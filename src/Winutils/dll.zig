const std = @import("std");
const win = std.os.windows;
const clr = @import("clr.zig");
const sneaky_memory = @import("memory.zig");
const logger = @import("../Logger/logger.zig"); // normalized
const winc = @import("Windows.h.zig");
const apiset = @import("apiset.zig");
const U16Set = std.HashMap([]const u16, void, U16KeyCtx, 80);

const W = std.unicode.utf8ToUtf16LeStringLiteral;
pub fn stub() callconv(.C) void {
    std.debug.print("stub called\n", .{});
}

extern fn UniversalStub() void;

// ===== Helpers (local, no OS hooking) =====
pub fn z16FromUtf8(alloc: std.mem.Allocator, s_in: []const u8) ![:0]u16 {
    var n: usize = s_in.len;
    if (n > 0 and s_in[n - 1] == 0) n -= 1; // ignore trailing NUL if caller provided one
    // alloc n payload + 1 sentinel, but the returned slice has len == n
    var z = try alloc.allocSentinel(u16, n, 0);
    var i: usize = 0;
    while (i < n) : (i += 1) z[i] = @intCast(s_in[i]);
    return z; // [:0]u16, len == n, z[n] == 0
}

fn z16FromU8z(alloc: std.mem.Allocator, zsrc: [*:0]const u8) ![:0]u16 {
    const n = std.mem.len(zsrc); // bytes before the 0
    var z = try alloc.allocSentinel(u16, n, 0);
    var i: usize = 0;
    while (i < n) : (i += 1) z[i] = @intCast(zsrc[i]);
    return z;
}

/// Duplicate an existing Z16 into owned memory (keeps sentinel)
fn dupZ16(alloc: std.mem.Allocator, s: [:0]const u16) ![:0]u16 {
    var z = try alloc.allocSentinel(u16, s.len, 0);
    @memcpy(z[0..s.len], s[0..s.len]);
    return z;
}
fn up16(c: u16) u16 {
    return if (c >= 'a' and c <= 'z') c - 32 else c;
}

// View without ".DLL" (still Z-terminated via sentinel slicing)
// If no ".DLL" suffix, returns original view.
fn stripExtDll16Z(s: [:0]const u16) [:0]const u16 {
    if (!endsWithDll16Z(s)) return s;
    // keep the sentinel by using the :0 slice form
    return s[0 .. s.len - 4 :0];
}

// Does a Z-terminated UTF-16 string end with ".DLL" (case-insensitive)?
fn endsWithDll16Z(s: [:0]const u16) bool {
    // [:0] slices include the sentinel in .len
    if (s.len < 5) return false; // ".DLL" + 0
    return s[s.len - 5] == '.' and up16(s[s.len - 4]) == 'D' and up16(s[s.len - 3]) == 'L' and up16(s[s.len - 2]) == 'L';
}

/// Uppercase + ensure ".DLL", Z in / Z out, NO allocation.
/// `buf` must be at least (core_len + 5) u16 long (".DLL" + 0).
fn canonicalUpperDllZ(src_z: [:0]const u16, buf: []u16) [:0]u16 {
    // compute core length (exclude ".DLL" if present, and exclude sentinel)
    const core_len: usize = if (endsWithDll16Z(src_z))
        src_z.len - 5 // strip ".DLL", keep no sentinel
    else
        src_z.len - 1; // drop existing sentinel only

    // copy & uppercase core
    var i: usize = 0;
    while (i < core_len) : (i += 1) {
        buf[i] = up16(src_z[i]);
    }

    // append ".DLL" + sentinel
    buf[i + 0] = '.';
    buf[i + 1] = 'D';
    buf[i + 2] = 'L';
    buf[i + 3] = 'L';
    buf[i + 4] = 0;

    // return as Z-slice
    return @ptrCast(buf[0 .. i + 5]);
}

// ASCII -> UTF-16 Z (no allocation, caller provides buffer)
fn asciiToUpperZ16Temp(src: []const u8, out: []u16) [:0]u16 {
    const n = @min(src.len, out.len - 1);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        out[i] = up16(src[i]);
    }
    out[n] = 0;
    return @ptrCast(out[0 .. n + 1]);
}
const U16KeyCtx = struct {
    pub fn hash(_: @This(), key: []const u16) u64 {
        // Hash the bytes of the UTF-16 slice
        var h = std.hash.Wyhash.init(0);
        h.update(std.mem.sliceAsBytes(key));
        return h.final();
    }
    pub fn eql(_: @This(), a: []const u16, b: []const u16) bool {
        return std.mem.eql(u16, a, b);
    }
};
const OwnedZ16 = struct {
    alloc: std.mem.Allocator,
    raw: []u16, // exact allocation INCLUDING sentinel
    z: [:0]u16, // view with len excluding sentinel

    pub fn deinit(self: *OwnedZ16) void {
        if (self.raw.len != 0) self.alloc.free(self.raw);
        // self.* = .{ .alloc = self.alloc, .raw = &[_]u16{}, .z = @ptrCast(&[_:0]u16{}) };
    }

    pub fn fromU8(alloc: std.mem.Allocator, s_in: []const u8) !OwnedZ16 {
        var n: usize = s_in.len;
        if (n > 0 and s_in[n - 1] == 0) n -= 1;
        var z = try alloc.allocSentinel(u16, n, 0);
        var i: usize = 0;
        while (i < n) : (i += 1) z[i] = @intCast(s_in[i]);
        return .{ .alloc = alloc, .raw = z[0 .. n + 1], .z = z };
    }
    pub fn fromU8z(alloc: std.mem.Allocator, zsrc: [*:0]const u8) !OwnedZ16 {
        const n = std.mem.len(zsrc);
        var z = try alloc.allocSentinel(u16, n, 0);
        var i: usize = 0;
        while (i < n) : (i += 1) z[i] = @intCast(zsrc[i]);
        return .{ .alloc = alloc, .raw = z[0 .. n + 1], .z = z };
    }
    pub fn fromU16(alloc: std.mem.Allocator, s: []const u16) !OwnedZ16 {
        var z = try alloc.allocSentinel(u16, s.len, 0);
        @memcpy(z[0..s.len], s);
        return .{ .alloc = alloc, .raw = z[0 .. s.len + 1], .z = z };
    }
    pub fn replaceWithZ16(self: *OwnedZ16, nz: [:0]const u16) !void {
        // allocate new + copy
        var z = try self.alloc.allocSentinel(u16, nz.len, 0);
        @memcpy(z[0..nz.len], nz);
        // free old using the exact recorded length
        if (self.raw.len != 0) self.alloc.free(self.raw);
        self.raw = z[0 .. nz.len + 1];
        self.z = z;
    }
};
fn zdup16(alloc: std.mem.Allocator, s: []const u16) ![:0]u16 {
    const buf = try alloc.alloc(u16, s.len + 1);
    @memcpy(buf[0..s.len], s);
    buf[s.len] = 0;
    return @ptrCast(buf);
}

fn asciiUpper(b: u8) u8 {
    return if (b >= 'a' and b <= 'z') b - 32 else b;
}
fn asciiUpper16(w: u16) u16 {
    return if (w >= 'a' and w <= 'z') w - 32 else w;
}
fn toUpperOwned(alloc: std.mem.Allocator, s: []const u8) ![]u8 {
    var out = try alloc.alloc(u8, s.len);
    for (s, 0..) |b, i| out[i] = asciiUpper(b);
    return out;
}
fn toUpperTemp(buf: []u8, s: []const u8) []u8 {
    const n = @min(buf.len, s.len);
    var i: usize = 0;
    while (i < n) : (i += 1) buf[i] = asciiUpper(s[i]);
    return buf[0..n];
}

fn looksLikeForwarderString(p: [*]const u8) bool {
    // Cheap heuristic: ASCII, contains '.', and no crazy bytes early
    var i: usize = 0;
    var has_dot = false;
    while (i < 64) : (i += 1) {
        const c = p[i];
        if (c == 0) break;
        if (c == '.') has_dot = true;
        if (c < 0x20 or c > 0x7E) return false;
    }
    return has_dot;
}

fn isOrdinalLookup64(imp: u64) bool {
    // IMAGE_SNAP_BY_ORDINAL for PE32+ uses the high bit
    return (imp & (1 << 63)) != 0;
}
fn ordinalOf64(imp: u64) u16 {
    return @intCast(imp & 0xFFFF);
}

fn getProc(comptime T: type, map: std.StringHashMap(*anyopaque), name: []const u8) !*const T {
    var buf: [128]u8 = undefined;
    const up = toUpperTemp(&buf, name);
    const p = map.get(up) orelse return DllError.FuncResolutionFailed;
    return @ptrCast(@alignCast(p));
}

// ===== Structures =====

const BASE_RELOCATION_BLOCK = struct {
    PageAddress: u32,
    BlockSize: u32,
};

const BASE_RELOCATION_ENTRY = packed struct {
    Offset: u12,
    Type: u4,
};

const DLLEntry = fn (dll: win.HINSTANCE, reason: u32, reserved: ?*std.os.windows.LPVOID) bool;

pub const DllError = error{
    Size,
    VirtualAllocNull,
    HashmapSucks,
    FuncResolutionFailed,
    ForwarderParse,
    LoadFailed,
};

const UNICODE_STRING = extern struct {
    Length: u16,
    MaximumLength: u16,
    alignment: u32,
    Buffer: ?[*:0]u16,
};

const LDR_DATA_TABLE_ENTRY = extern struct {
    Reserved1: [2]usize,
    InMemoryOrderLinks: winc.LIST_ENTRY,
    Reserved2: [4]usize,
    DllBase: ?*anyopaque,
    EntryPoint: ?*anyopaque,
    Reserved3: usize,
    fullDllName: UNICODE_STRING,
    BaseDllName: UNICODE_STRING,
    Reserved5: usize,
    TimeDateStamp: u32,
};

const PEB_LDR_DATA = extern struct {
    Reserved1: [3]usize,
    InMemoryOrderModuleList: [2]usize,
};

pub const IMAGE_DELAYLOAD_DESCRIPTOR = extern struct {
    Attributes: u32,
    DllNameRVA: u32,
    ModuleHandleRVA: u32,
    ImportAddressTableRVA: u32,
    ImportNameTableRVA: u32,
    BoundImportAddressTableRVA: u32,
    UnloadInformationTableRVA: u32,
    TimeDateStamp: u32,
};

const PEB = extern struct {
    Reserved1: [2]u8,
    BeingDebugged: u8,
    Reserved2: [1]u8,
    Reserved3: [2]*anyopaque,
    Ldr: *PEB_LDR_DATA,
    Reserved4: [3]*anyopaque,
    Reserved5: [2]usize,
    Reserved6: *anyopaque,
    Reserved7: usize,
    Reserved8: [4]usize,
    Reserved9: [4]usize,
    Reserved10: [1]usize,
    PostProcessInitRoutine: *const usize,
    Reserved11: [1]usize,
    Reserved12: [1]usize,
    SessionId: u32,
};

// ===== Logging =====

const pref_list = [_][]const u8{ "RefLoad", "ExpTable", "ImpFix", "ImpRes", "RVAres", "HookF", "PathRes" };
const colour = logger.LoggerColour;
const colour_list = [_]colour{ colour.green, colour.blue, colour.cyan, colour.yellow, colour.pink, colour.red, colour.cyan };

const logtags = enum {
    RefLoad,
    ExpTable,
    ImpFix,
    ImpRes,
    RVAres,
    HookF,
    PathRes,
};

var log = logger.Logger.init(colour_list.len, pref_list, colour_list);

// ===== Public structs =====

pub const Dll = struct {
    // store upper-cased export names for case-insensitive lookups
    NameExports: std.StringHashMap(*anyopaque) = undefined,
    OrdinalExports: std.AutoHashMap(u16, *anyopaque) = undefined,
    BaseAddr: [*]u8 = undefined,
    Path: *DllPath = undefined,

    ExportBase: u32 = 0,
    NumberOfFunctions: u32 = 0,
    pub fn ResolveByName(self: *Dll, up_name: []const u8) ?*anyopaque {
        return self.NameExports.get(up_name);
    }
    pub fn ResolveByOrdinal(self: *Dll, ord: u16) ?*anyopaque {
        return self.OrdinalExports.get(ord);
    }
};

pub var GLOBAL_DLL_LOADER: *DllLoader = undefined;

// ===== GPA/GMH stubs (optional to keep) =====

pub fn GetProcAddress(hModule: [*]u8, procname: [*:0]const u8) callconv(.C) ?*anyopaque {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    const self = GLOBAL_DLL_LOADER;

    var it = self.LoadedDlls.keyIterator();
    while (it.next()) |key| {
        const dll = self.LoadedDlls.get(key.*).?;
        if (dll.BaseAddr == hModule) {
            var buf: [256]u8 = undefined;
            const up = toUpperTemp(&buf, procname[0..std.mem.len(procname)]);
            return dll.NameExports.get(up);
        }
    }
    return null;
}

pub fn GetModuleHandleA(moduleName_: ?[*:0]const u8) callconv(.C) ?[*]u8 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    const self = GLOBAL_DLL_LOADER;

    if (moduleName_) |moduleName| {
        var owned = OwnedZ16.fromU8z(self.Allocator, moduleName) catch return null;
        defer owned.deinit();
        return GetModuleHandleW(owned.z);
    } else {
        const peb: usize = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> usize),
            :
            : "memory"
        );
        const addr: [*]u8 = @ptrFromInt(peb + 0x10);
        return addr;
    }
}

pub fn GetModuleHandleW(moduleName16_: ?[*:0]const u16) callconv(.C) ?[*]u8 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();

    if (moduleName16_) |moduleName16| {
        const len = std.mem.len(moduleName16) + 1;
        const self = GLOBAL_DLL_LOADER;
        var dllPath = (self.getDllPaths(@ptrCast(moduleName16[0..len])) catch {
            return null;
        }) orelse return null;

        dllPath.normalize();
        if (self.LoadedDlls.contains(@constCast(dllPath.shortPath16))) {
            return self.LoadedDlls.get(@constCast(dllPath.shortPath16)).?.BaseAddr;
        }
        const resulting = self.ZLoadLibrary(@as([:0]u16, @constCast(@ptrCast(moduleName16[0..len])))) catch return null;
        if (resulting) |d| return d.BaseAddr;
        return null;
    } else {
        const peb: usize = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> usize),
            :
            : "memory"
        );
        const addr: *[*]u8 = @ptrFromInt(peb + 0x10);
        return addr.*;
    }
}

pub fn LoadLibraryW_stub(libname16: [*:0]u16) callconv(.C) ?[*]u8 {
    if (GLOBAL_DLL_LOADER.LoadedDlls.contains(libname16[0..std.mem.len(libname16)])) {
        return GLOBAL_DLL_LOADER.LoadedDlls.get(libname16[0..std.mem.len(libname16)]).?.BaseAddr;
    }
    const dll = GLOBAL_DLL_LOADER.ZLoadLibrary(@ptrCast(libname16[0..std.mem.len(libname16)])) catch return null;
    if (dll) |d| return d.BaseAddr;
    return null;
}

pub fn LoadLibraryA_stub(libname: [*:0]u8) callconv(.C) ?[*]u8 {
    const self = GLOBAL_DLL_LOADER;
    const libname16 = z16FromUtf8(self.Allocator, libname[0 .. std.mem.len(libname) + 1]) catch return null;
    defer self.Allocator.free(libname16);
    return LoadLibraryW_stub(@ptrCast(libname16.ptr));
}

// ===== Hash map context for u16 keys =====

const MappingContext = struct {
    pub fn hash(_: @This(), key: []u16) u64 {
        const len = key.len;
        const u8ptr: [*]const u8 = @ptrCast(key.ptr);
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(u8ptr[0 .. len * 2]);
        return hasher.final();
    }
    pub fn eql(_: @This(), a: []u16, b: []u16) bool {
        return std.mem.eql(u16, a, b);
    }
};

pub const u16HashMapType = std.HashMap([]u16, *Dll, MappingContext, 80);

// ===== DllPath =====

pub const DllPath = struct {
    path16: [:0]u16,
    shortPath16: [:0]u16,
    allocated_buf: ?[]u16 = null,

    const Self = @This();

    pub fn normalize(self: *Self) void {
        var i: usize = 0;
        while (self.shortPath16[i] != 0) : (i += 1) {
            const ch = self.shortPath16[i];
            if (ch >= 'a' and ch <= 'z') self.shortPath16[i] = ch - 32;
        }
    }

    pub fn free(self: *Self, allocator: std.mem.Allocator) void {
        if (self.allocated_buf) |mem| allocator.free(mem);
    }
};

// ===== Loader =====

pub const DllLoader = struct {
    LoadedDlls: u16HashMapType = undefined,
    Allocator: std.mem.Allocator,
    HeapAllocator: sneaky_memory.HeapAllocator = undefined,
    InFlight: U16Set = undefined,

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .LoadedDlls = undefined,
            .Allocator = allocator,
            .InFlight = U16Set.init(allocator),
        };
    }
    pub fn getDllByName(self: *DllLoader, name: []const u8) !*Dll {
        // ASCII -> Z16 (upper)
        // log.info("name u8 {d} -> {s}\n", .{ name.len, name });
        var tmp16: [260]u16 = undefined;
        const name_z16 = asciiToUpperZ16Temp(name, &tmp16);

        // log.info16("name_z {d}", .{name_z16.len}, name_z16);
        // Canonicalize to UPPER + ".DLL"
        var canon_buf: [260]u16 = undefined;
        const canon_z = canonicalUpperDllZ(name_z16, &canon_buf);

        // HashMap key type is []u16; a [:0]u16 slices to that directly
        // log.info16("canon_z {d}", .{canon_z.len}, canon_z);
        if (self.LoadedDlls.get(canon_z)) |dll| return dll;
        return DllError.LoadFailed;
    }

    pub fn getLoadedDlls(self: *@This()) !void {
        // Enumerate existing loader list into our map (read-only snapshot)
        const peb: *PEB = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> *PEB),
            :
            : "memory"
        );
        const ldr = peb.Ldr;
        const head: *winc.LIST_ENTRY = @ptrFromInt(ldr.InMemoryOrderModuleList[0]);
        var curr: *winc.LIST_ENTRY = head.Flink;
        var count: usize = 0;
        var skipcount: i32 = 2;

        self.LoadedDlls = u16HashMapType.init(self.Allocator);

        while (count < 1000) : ({
            curr = curr.Flink;
            count += 1;
        }) {
            const entry: *LDR_DATA_TABLE_ENTRY = @ptrFromInt(@intFromPtr(curr) - 16);
            const BaseDllName: UNICODE_STRING = entry.BaseDllName;

            if (BaseDllName.Buffer != null and (BaseDllName.Length / 2) <= 260 and skipcount <= 0) {
                var dll: *Dll = try self.Allocator.create(Dll);
                dll.BaseAddr = @ptrCast(entry.DllBase);

                const fullLen = entry.fullDllName.Length / 2 + 1;
                const baseLen = entry.BaseDllName.Length / 2 + 1;

                const dllName: [*:0]u16 = @ptrCast((try self.Allocator.alloc(u16, fullLen)).ptr);
                const shortdllName: [*:0]u16 = @ptrCast((try self.Allocator.alloc(u16, baseLen)).ptr);

                std.mem.copyForwards(u16, dllName[0..fullLen], entry.fullDllName.Buffer.?[0..fullLen]);
                std.mem.copyForwards(u16, shortdllName[0..baseLen], entry.BaseDllName.Buffer.?[0..baseLen]);

                dll.Path = try self.Allocator.create(DllPath);
                dll.Path.shortPath16 = @ptrCast(shortdllName[0..baseLen]);
                dll.Path.path16 = @ptrCast(dllName[0..fullLen]);
                dll.Path.normalize();
                try self.ResolveExports(dll);
                try self.LoadedDlls.put(dll.Path.shortPath16, dll);

                if (curr == head) break;
            } else {
                skipcount -= 1;
            }
        }
    }

    // ===== Export table (case-insensitive names, ordinals, forwarders later) =====
    pub fn ResolveExports(self: *@This(), dll: *Dll) !void {
        log.setContext(logtags.ExpTable);
        defer log.rollbackContext();

        const bytes = dll.BaseAddr;
        const dos: *winc.IMAGE_DOS_HEADER = @ptrCast(@alignCast(bytes));
        const nt: *const winc.IMAGE_NT_HEADERS = @ptrCast(@alignCast(bytes[@intCast(dos.e_lfanew)..]));
        const dir = nt.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_EXPORT];
        if (dir.Size == 0) return;

        const exp: *const winc.IMAGE_EXPORT_DIRECTORY =
            @ptrCast(@alignCast(bytes[dir.VirtualAddress..]));

        dll.ExportBase = exp.Base;
        dll.NumberOfFunctions = exp.NumberOfFunctions;

        const eat: [*]u32 = @ptrCast(@alignCast(bytes[exp.AddressOfFunctions..]));
        const enpt: [*]u32 = @ptrCast(@alignCast(bytes[exp.AddressOfNames..]));
        const enot: [*]u16 = @ptrCast(@alignCast(bytes[exp.AddressOfNameOrdinals..]));

        dll.NameExports = std.StringHashMap(*anyopaque).init(self.Allocator);
        dll.OrdinalExports = std.AutoHashMap(u16, *anyopaque).init(self.Allocator);

        // 1) Fill ordinals for ALL functions by index -> real ordinal
        var i: u32 = 0;
        while (i < exp.NumberOfFunctions) : (i += 1) {
            const rva = eat[i];
            if (rva == 0) continue; // unused slot
            const fptr: *anyopaque = @ptrCast(bytes[@as(usize, @intCast(rva))..]);
            const real_ordinal: u16 = @intCast(exp.Base + i);
            // overwrite ok if duplicates/forwarders later adjust
            try dll.OrdinalExports.put(real_ordinal, fptr);
        }

        // 2) Fill names (UPPERCASE keys), using index -> RVA
        var j: u32 = 0;
        while (j < exp.NumberOfNames) : (j += 1) {
            const name_rva = enpt[j];
            const idx = enot[j]; // index into EAT
            const fptr: *anyopaque = @ptrCast(bytes[@as(usize, @intCast(eat[idx]))..]);

            // uppercase-own the key before insert (your earlier fix)
            const fname_z: [*:0]u8 = @ptrCast(bytes[@as(usize, @intCast(name_rva))..]);
            const fname = fname_z[0..std.mem.len(fname_z)];
            const up = try toUpperOwned(self.Allocator, fname);
            errdefer self.Allocator.free(up);

            const g = try dll.NameExports.getOrPut(up);
            if (g.found_existing) self.Allocator.free(up);
            g.value_ptr.* = fptr;
        }
    }
    // ===== Forwarder resolver =====
    fn resolveForwarder(self: *DllLoader, fwd: []const u8) !*anyopaque {
        // "DLL.Func" or "DLL.#123"
        const dot = std.mem.indexOfScalar(u8, fwd, '.') orelse return DllError.ForwarderParse;
        const mod = fwd[0..dot];
        const sym = fwd[dot + 1 ..];

        // Ensure ".dll"
        var modbuf: [128]u8 = undefined;
        var upmod = toUpperTemp(&modbuf, mod);
        const needs_ext = !(upmod.len >= 4 and std.mem.eql(u8, upmod[upmod.len - 4 ..], ".DLL"));
        var final_mod: []const u8 = undefined;
        if (needs_ext) {
            final_mod = try std.fmt.allocPrint(self.Allocator, "{s}.dll", .{mod});
        } else {
            final_mod = try self.Allocator.dupe(u8, mod);
        }
        defer self.Allocator.free(final_mod);

        // Load dependency (respect apisets)
        var mod16 = try OwnedZ16.fromU8(self.Allocator, final_mod);
        defer mod16.deinit();
        const dep: *Dll = (try self.ZLoadLibrary(mod16.z)) orelse {
            return DllError.LoadFailed;
        };

        if (sym.len > 0 and sym[0] == '#') {
            const ord = try std.fmt.parseInt(u16, sym[1..], 10);
            return dep.ResolveByOrdinal(ord) orelse DllError.FuncResolutionFailed;
        } else {
            // case-insensitive
            var buf: [256]u8 = undefined;
            const up = toUpperTemp(&buf, sym);
            return dep.ResolveByName(up) orelse DllError.FuncResolutionFailed;
        }
    }

    // Resolve by name/ordinal from already built maps

    // ===== Path resolution (unchanged except small cleanups) =====
    pub fn getDllPaths(self: *@This(), libname16_: [:0]const u16) !?*DllPath {
        log.setContext(logtags.PathRes);
        defer log.rollbackContext();

        // var it = self.LoadedDlls.iterator();
        // while (it.next()) |key| {
        //     log.info16("lib", .{}, key.key_ptr.*);
        // }
        const kernel32 = (try self.getDllByName("kernel32.dll")).NameExports;

        const GetFileAttributesW =
            try getProc(fn ([*:0]u16) callconv(.C) c_int, kernel32, "GetFileAttributesW");

        const GetEnvironmentVariableW =
            try getProc(fn ([*]const u16, [*:0]u16, c_uint) callconv(.C) c_uint, kernel32, "GetEnvironmentVariableW");

        const GetSystemDirectoryW =
            try getProc(fn ([*]u16, usize) callconv(.C) c_int, kernel32, "GetSystemDirectoryW");

        const GetLastError =
            try getProc(fn () callconv(.C) c_int, kernel32, "GetLastError");

        const SetLastError =
            try getProc(fn (c_int) callconv(.C) void, kernel32, "SetLastError");
        const dllPath: *DllPath = try self.Allocator.create(DllPath);

        if (clr.isFullPath(libname16_)) |symbol| {
            const copy_fullname16 = try self.Allocator.alloc(u16, libname16_.len);
            @memcpy(copy_fullname16, libname16_);
            dllPath.path16 = @ptrCast(copy_fullname16);
            var start_index: usize = 0;
            for (dllPath.path16, 0..) |item, index| {
                if (item == symbol) start_index = index + 1;
            }
            dllPath.shortPath16 = dllPath.path16[start_index..];
            dllPath.allocated_buf = copy_fullname16;
        } else {
            dllPath.path16 = @ptrCast(try self.Allocator.alloc(u16, 260));
            var PATH: [33000:0]u16 = undefined;
            const PATH_s = W("PATH");

            var len: usize = GetEnvironmentVariableW(PATH_s.ptr, &PATH, 32767);
            PATH[len] = @intCast('.');
            PATH[len + 1] = @intCast('\\');
            PATH[len + 2] = @intCast(';');
            len += 3;
            const syslen: usize = @intCast(GetSystemDirectoryW(PATH[len..].ptr, 30));
            PATH[len + syslen] = 0;

            var i: usize = 0;
            var start_pointer: usize = 0;
            var found: bool = false;

            while (PATH[i] != 0) : (i += 1) {
                if ((PATH[i] & 0xff00 == 0) and @as(u8, @intCast(PATH[i])) == ';') {
                    const end_pointer = i;

                    const tmp_str_len = (end_pointer - start_pointer) + 1 + libname16_.len + 1;
                    const u16searchString_alloc = try self.Allocator.alloc(u16, tmp_str_len);
                    var u16searchString: [:0]u16 = @ptrCast(u16searchString_alloc);

                    std.mem.copyForwards(u16, u16searchString[0 .. end_pointer - start_pointer], PATH[start_pointer..end_pointer]);
                    u16searchString[end_pointer - start_pointer] = @intCast('\\');
                    std.mem.copyForwards(u16, u16searchString[end_pointer - start_pointer + 1 .. tmp_str_len], libname16_);

                    _ = GetFileAttributesW(u16searchString.ptr);
                    const err: c_int = GetLastError();
                    if (err != 0) {
                        SetLastError(0);
                        start_pointer = end_pointer + 1;
                        self.Allocator.free(u16searchString_alloc);
                        continue;
                    }

                    found = true;
                    const copy_fullname16 = try self.Allocator.alloc(u16, tmp_str_len - 2);
                    @memcpy(copy_fullname16, u16searchString[0 .. tmp_str_len - 2]);
                    const copy_shortname16 = clr.getShortName(@ptrCast(copy_fullname16));

                    self.Allocator.free(u16searchString_alloc);
                    dllPath.path16 = @ptrCast(copy_fullname16);
                    dllPath.shortPath16 = @ptrCast(copy_shortname16);
                    dllPath.allocated_buf = copy_fullname16;
                    break;
                }
            }

            if (!found) return null;
        }

        return dllPath;
    }

    // ===== File mapping =====
    pub fn LoadDllInMemory(self: *@This(), dllPath: *DllPath, dllSize: *usize) !?[*]u8 {
        const kernel32 = (try self.getDllByName("kernel32.dll")).NameExports;

        const CreateFileW =
            try getProc(fn ([*:0]const u16, u32, u32, ?*win.SECURITY_ATTRIBUTES, u32, u32, ?*anyopaque) callconv(.C) *anyopaque, kernel32, "CreateFileW");

        const CloseHandle =
            try getProc(fn (*anyopaque) callconv(.C) c_int, kernel32, "CloseHandle");

        const GetFileSizeEx =
            try getProc(fn (*anyopaque, *i64) callconv(.C) c_int, kernel32, "GetFileSizeEx");

        const ReadFile =
            try getProc(fn (*anyopaque, [*]u8, u32, ?*u32, ?*win.OVERLAPPED) callconv(.C) c_int, kernel32, "ReadFile");
        const dll_handle = CreateFileW(dllPath.path16, win.GENERIC_READ, 0, null, win.OPEN_EXISTING, 0, null);
        defer _ = CloseHandle(dll_handle);

        var dll_size_i: i64 = 0;
        if ((GetFileSizeEx(dll_handle, &dll_size_i) <= 0)) return DllError.Size;
        dllSize.* = @intCast(dll_size_i);

        const dll_bytes: [*]u8 = (try self.Allocator.alloc(u8, dllSize.*)).ptr;
        var bytes_read: winc.DWORD = 0;
        _ = ReadFile(dll_handle, dll_bytes, @as(u32, @intCast(dllSize.*)), &bytes_read, null);
        return dll_bytes;
    }

    pub fn ResolveNtHeaders(dll_bytes: [*]u8) *const winc.IMAGE_NT_HEADERS {
        const dos_headers: *winc.IMAGE_DOS_HEADER = @ptrCast(@alignCast(dll_bytes));
        const nt_headers: *const winc.IMAGE_NT_HEADERS =
            @ptrCast(@alignCast(dll_bytes[@intCast(dos_headers.e_lfanew)..]));
        return nt_headers;
    }

    pub fn MapSections(
        self: *@This(),
        nt_headers: *const winc.IMAGE_NT_HEADERS,
        dll_bytes: [*]u8,
        delta_image_base: *usize,
    ) ![*]u8 {
        const ntdll = (try self.getDllByName("ntdll.dll")).NameExports;

        const ZwAllocateVirtualMemory = try getProc(fn (
            i64,
            *?[*]u8,
            usize,
            *usize,
            u32,
            u32,
        ) callconv(.C) c_int, ntdll, "ZwAllocateVirtualMemory");

        var dll_base_dirty: ?[*]u8 = null;
        var virtAllocSize: usize = nt_headers.OptionalHeader.SizeOfImage;

        var status: c_int = ZwAllocateVirtualMemory(
            -1,
            &dll_base_dirty,
            0,
            &virtAllocSize,
            win.MEM_RESERVE | win.MEM_COMMIT,
            win.PAGE_READWRITE,
        );
        if (status < 0) {
            // try again once
            dll_base_dirty = null;
            status = ZwAllocateVirtualMemory(
                -1,
                &dll_base_dirty,
                0,
                &virtAllocSize,
                win.MEM_RESERVE | win.MEM_COMMIT,
                win.PAGE_READWRITE,
            );
            if (status < 0 or dll_base_dirty == null) return DllError.VirtualAllocNull;
        }
        const dll_base = dll_base_dirty.?;

        // delta
        delta_image_base.* = @intFromPtr(dll_base) - nt_headers.OptionalHeader.ImageBase;

        // headers
        std.mem.copyForwards(
            u8,
            dll_base[0..nt_headers.OptionalHeader.SizeOfHeaders],
            dll_bytes[0..nt_headers.OptionalHeader.SizeOfHeaders],
        );

        // sections
        const section: [*]const winc.IMAGE_SECTION_HEADER =
            @ptrFromInt(@intFromPtr(nt_headers) + @sizeOf(winc.IMAGE_NT_HEADERS));
        var i: usize = 0;
        while (i < nt_headers.FileHeader.NumberOfSections) : (i += 1) {
            const dst: [*]u8 = @ptrCast(dll_base[section[i].VirtualAddress..]);
            const src: [*]u8 = @ptrCast(dll_bytes[section[i].PointerToRawData..]);
            std.mem.copyForwards(u8, dst[0..section[i].SizeOfRawData], src[0..section[i].SizeOfRawData]);
        }

        // update ImageBase
        var new_nt = @constCast(ResolveNtHeaders(dll_base));
        new_nt.OptionalHeader.ImageBase = @intFromPtr(dll_base);
        return dll_base;
    }

    // ===== Relocations (DIR64 only, safe) =====
    pub fn ResolveRVA(
        dll_base: [*]u8,
        nt_headers: *const winc.IMAGE_NT_HEADERS,
        delta_image_base: usize,
    ) !void {
        log.setContext(logtags.RVAres);
        defer log.rollbackContext();

        const dir = nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_BASERELOC];
        if (dir.Size == 0) return;

        var processed: usize = 0;
        while (processed < dir.Size) {
            const block: *BASE_RELOCATION_BLOCK = @ptrCast(@alignCast(dll_base[dir.VirtualAddress + processed ..]));
            if (block.BlockSize < @sizeOf(BASE_RELOCATION_BLOCK)) break;
            processed += @sizeOf(BASE_RELOCATION_BLOCK);

            const count = (block.BlockSize - @sizeOf(BASE_RELOCATION_BLOCK)) / @sizeOf(BASE_RELOCATION_ENTRY);
            const entries: [*]align(1) BASE_RELOCATION_ENTRY = @ptrCast(@alignCast(dll_base[dir.VirtualAddress + processed ..]));

            var i: usize = 0;
            while (i < count) : (i += 1) {
                const e = entries[i];
                if (e.Type == 10) { // IMAGE_REL_BASED_DIR64
                    const rva: usize = block.PageAddress + e.Offset;
                    const ptr: *usize = @ptrCast(@alignCast(dll_base[rva..]));
                    ptr.* = ptr.* + delta_image_base;
                }
                // ABSOLUTE and others ignored
                processed += @sizeOf(BASE_RELOCATION_ENTRY);
            }
        }
    }

    // ===== Import resolution (API set, ordinals, forwarders) =====
    pub fn ResolveImportTable(
        self: *@This(),
        dll_base: [*]u8,
        nt_headers: *const winc.IMAGE_NT_HEADERS,
        dllPath: *DllPath,
        dll_struct: *Dll,
    ) !void {
        log.setContext(logtags.ImpRes);
        defer log.rollbackContext();

        const impdir = nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_IMPORT];
        if (impdir.Size == 0) return;

        var import_descriptor: *const winc.IMAGE_IMPORT_DESCRIPTOR =
            @ptrCast(@alignCast(dll_base[impdir.VirtualAddress..]));

        // ---------------------------------------------------------------

        while (import_descriptor.Name != 0) : (import_descriptor =
            @ptrFromInt(@intFromPtr(import_descriptor) + @sizeOf(winc.IMAGE_IMPORT_DESCRIPTOR)))
        {
            const lib_u8z: [*:0]const u8 = @ptrCast(dll_base[import_descriptor.Name..]);
            if (std.mem.len(lib_u8z) == 0) break;

            // 1) Own a UTF-16Z copy of the import name
            var owned = try OwnedZ16.fromU8z(self.Allocator, lib_u8z);
            defer owned.deinit(); // exactly once at the end of this descriptor

            // 2) If it’s an ApiSet, resolve to host (non-Z slice from the ApiSet map)
            if (apiset.ApiSetResolve(owned.z)) |host_noz| {
                if (host_noz.len == 0) {
                    log.info16("Api host empty for ", .{}, owned.raw);
                    @panic("HAndle me");
                    // continue;
                }
                var canon_buf: [260]u16 = undefined;
                var tmp: [260]u16 = undefined;
                const host_tmp_z = blk: {
                    @memcpy(tmp[0..host_noz.len], host_noz);
                    tmp[host_noz.len] = 0;
                    break :blk @as([:0]u16, @ptrCast(tmp[0 .. host_noz.len + 1]));
                };
                const canon_z = canonicalUpperDllZ(host_tmp_z, &canon_buf);
                try owned.replaceWithZ16(canon_z);
                log.info16("Api host  -> ", .{}, owned.z);
            } else {
                var canon_buf2: [260]u16 = undefined;
                const canon2_z = canonicalUpperDllZ(owned.z, &canon_buf2);
                try owned.replaceWithZ16(canon2_z);
            }

            // Now you have a guaranteed, owned, zero-terminated, canonical UPPERCASE short name
            const libraryNameToLoad16: [:0]u16 = owned.z;

            // 3) Load (or reuse) the library
            var library: ?*Dll = undefined;
            if (std.mem.eql(u16, dllPath.shortPath16, libraryNameToLoad16)) {
                library = dll_struct;
            } else {
                log.info16("Trying to load  -> ", .{}, libraryNameToLoad16);
                library = try self.ZLoadLibrary(libraryNameToLoad16);
            }
            if (library == null) return DllError.LoadFailed; // (or `continue;` if you prefer soft-fail)

            // 4) Walk thunks and resolve
            var orig_thunk_rva: u32 = import_descriptor.FirstThunk;
            if (orig_thunk_rva == 0) {
                orig_thunk_rva = import_descriptor.FirstThunk;
            }
            var orig: *winc.IMAGE_THUNK_DATA =
                @ptrCast(@alignCast(dll_base[orig_thunk_rva..]));
            var thunk = orig;

            var tmpname: [256]u8 = undefined;

            while (orig.u1.AddressOfData != 0) : ({
                thunk = @ptrFromInt(@intFromPtr(thunk) + @sizeOf(winc.IMAGE_THUNK_DATA));
                orig = @ptrFromInt(@intFromPtr(orig) + @sizeOf(winc.IMAGE_THUNK_DATA));
            }) {
                if (isOrdinalLookup64(orig.u1.AddressOfData)) {
                    // Ordinal path (REAL ordinal)
                    const ord = ordinalOf64(orig.u1.AddressOfData);
                    var addr = library.?.ResolveByOrdinal(ord) orelse {
                        log.info16("Failed ordinal {x} lookup for library -> ", .{ord}, libraryNameToLoad16);
                        return DllError.FuncResolutionFailed;
                    };
                    // forwarder check for ordinals too
                    const addr_bytes: [*]const u8 = @ptrCast(addr);
                    if (looksLikeForwarderString(addr_bytes)) {
                        const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(addr)), 0);
                        addr = try self.resolveForwarder(fwd_slice);
                    }
                    thunk.u1.Function = @intFromPtr(addr);
                } else {
                    // Name path
                    const ibn: *const winc.IMAGE_IMPORT_BY_NAME = @ptrCast(@alignCast(dll_base[orig.u1.AddressOfData..]));
                    const name_z: [*:0]const u8 = @ptrCast(&ibn.Name);
                    const up = toUpperTemp(&tmpname, name_z[0..std.mem.len(name_z)]);

                    var addr = library.?.ResolveByName(up) orelse {
                        log.info16("Failed name {s} in -> ", .{up}, libraryNameToLoad16);
                        return DllError.FuncResolutionFailed;
                    };

                    // Forwarder?
                    const addr_bytes: [*]const u8 = @ptrCast(addr);
                    if (looksLikeForwarderString(addr_bytes)) {
                        const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(addr)), 0);
                        addr = try self.resolveForwarder(fwd_slice);
                    }

                    thunk.u1.Function = @intFromPtr(addr);
                }
            }
        }
    }
    // Optional delay-load resolver (off by default)
    fn fixDelayImports(self: *DllLoader, dll: *Dll) !void {
        _ = self;
        _ = dll;
        // Wire similarly to ResolveImportTable if you enable delay import directory.
    }

    // Patching exported stubs (case-insensitive now)
    pub fn ResolveImportInconsistencies(self: *@This(), dll: *Dll) !void {
        _ = self;
        log.setContext(logtags.ImpFix);
        defer log.rollbackContext();

        var tmp: [32]u8 = undefined;

        const k1 = toUpperTemp(&tmp, "GetProcAddress");
        if (dll.NameExports.getPtr(k1)) |vp| vp.* = @ptrCast(@constCast(&GetProcAddress));

        const k2 = toUpperTemp(&tmp, "GetModuleHandleA");
        if (dll.NameExports.getPtr(k2)) |vp| vp.* = @ptrCast(@constCast(&GetModuleHandleA));

        const k3 = toUpperTemp(&tmp, "GetModuleHandleW");
        if (dll.NameExports.getPtr(k3)) |vp| vp.* = @ptrCast(@constCast(&GetModuleHandleW));

        const k4 = toUpperTemp(&tmp, "LoadLibraryA");
        if (dll.NameExports.getPtr(k4)) |vp| vp.* = @ptrCast(@constCast(&LoadLibraryA_stub));

        const k5 = toUpperTemp(&tmp, "LoadLibraryW");
        if (dll.NameExports.getPtr(k5)) |vp| vp.* = @ptrCast(@constCast(&LoadLibraryW_stub));
    }
    // ===== Memory protections + TLS + DllMain =====
    pub fn IMAGE_FIRST_SECTION(nt_headers: *const winc.IMAGE_NT_HEADERS) [*]const winc.IMAGE_SECTION_HEADER {
        const OptionalHeader: [*]const u8 = @ptrCast(&nt_headers.OptionalHeader);
        const SizeOfOptionalHeader: usize = nt_headers.FileHeader.SizeOfOptionalHeader;
        const sectionHeader: [*]const winc.IMAGE_SECTION_HEADER =
            @alignCast(@ptrCast(OptionalHeader[SizeOfOptionalHeader..]));
        return sectionHeader;
    }

    pub fn ExecuteDll(self: *@This(), dll: *Dll) !void {
        const ntdll = (try self.getDllByName("ntdll.dll")).NameExports;

        const NtProtectVirtualMemory = try getProc(
            fn (i64, *const [*]u8, *const usize, c_int, *c_int) callconv(.C) c_int,
            ntdll,
            "NtProtectVirtualMemory",
        );
        const NtFlushInstructionCache = try getProc(
            fn (i32, ?[*]u8, usize) callconv(.C) c_int,
            ntdll,
            "NtFlushInstructionCache",
        );

        const nt_headers = ResolveNtHeaders(dll.BaseAddr);
        const sectionHeader: [*]const winc.IMAGE_SECTION_HEADER = IMAGE_FIRST_SECTION(nt_headers);

        var dwProtect: c_int = undefined;
        var i: usize = 0;
        while (i < nt_headers.FileHeader.NumberOfSections) : (i += 1) {
            if (sectionHeader[i].SizeOfRawData == 0) continue;

            const exec = (sectionHeader[i].Characteristics & winc.IMAGE_SCN_MEM_EXECUTE) != 0;
            const read = (sectionHeader[i].Characteristics & winc.IMAGE_SCN_MEM_READ) != 0;
            const write = (sectionHeader[i].Characteristics & winc.IMAGE_SCN_MEM_WRITE) != 0;

            if (!exec and !read and !write) dwProtect = winc.PAGE_NOACCESS else if (!exec and !read and write) dwProtect =
                winc.PAGE_WRITECOPY else if (!exec and read and !write) dwProtect = winc.PAGE_READONLY else if (!exec and read and write) dwProtect = winc.PAGE_READWRITE else if (exec and !read and !write) dwProtect = winc.PAGE_EXECUTE else if (exec and !read and write) dwProtect = winc.PAGE_EXECUTE_WRITECOPY else if (exec and read and !write) dwProtect = winc.PAGE_EXECUTE_READ else dwProtect = winc.PAGE_EXECUTE_READWRITE;

            if (sectionHeader[i].Characteristics & winc.IMAGE_SCN_MEM_NOT_CACHED != 0)
                dwProtect |= winc.PAGE_NOCACHE;

            const BaseAddress = dll.BaseAddr[sectionHeader[i].VirtualAddress..];
            const RegionSize: usize = sectionHeader[i].SizeOfRawData;
            var oldProt: c_int = 0;
            _ = NtProtectVirtualMemory(-1, &BaseAddress, &RegionSize, dwProtect, &oldProt);
        }

        _ = NtFlushInstructionCache(-1, null, 0);

        // log.info("Starting tls\n", .{});
        // TLS
        if (nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_TLS].Size != 0) {
            const tls_dir: *const winc.IMAGE_TLS_DIRECTORY =
                @alignCast(@ptrCast(
                    dll.BaseAddr[nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_TLS].VirtualAddress..],
                ));
            if (tls_dir.AddressOfCallBacks != 0) {
                var p: [*]?*const DLLEntry = @ptrFromInt(tls_dir.AddressOfCallBacks);
                const hinst: win.HINSTANCE = @ptrCast(dll.BaseAddr);
                while (p[0]) |cb| : (p = p[1..]) {
                    _ = cb(hinst, winc.DLL_PROCESS_ATTACH, null);
                }
            }
        }

        // log.info("Starting DLLMain\n", .{});

        // DllMain
        if (nt_headers.OptionalHeader.AddressOfEntryPoint != 0) {
            const dll_entry: ?*const DLLEntry = @ptrCast(dll.BaseAddr[nt_headers.OptionalHeader.AddressOfEntryPoint..]);
            if (dll_entry) |run| {
                const hinst: win.HINSTANCE = @ptrCast(dll.BaseAddr);
                _ = run(hinst, winc.DLL_PROCESS_ATTACH, null);
            }
        }
    }

    // ===== Optional: NO PEB FORGERY =====
    pub fn addDllToPEBList(self: *@This(), dll: *Dll) !void {
        _ = self;
        _ = dll;
        // Intentionally not implemented. We do NOT forge or insert into PEB loader lists.
        // If you need discoverability, expose your own registry of loaded modules (self.LoadedDlls), which we already maintain.
        return;
    }

    // ===== The main loader =====
    pub fn ZLoadLibrary(self: *@This(), libname16_: [:0]const u16) anyerror!?*Dll {
        log.setContext(logtags.RefLoad);
        defer log.rollbackContext();

        // Resolve full path + short name
        log.info16("starting to load", .{}, libname16_);
        var dllPath = (try self.getDllPaths(libname16_)) orelse return null;
        dllPath.normalize();
        const key = dllPath.shortPath16; // already UPPERCASE & Z
        if (self.LoadedDlls.get(key)) |d| return d;

        // prevent re-entry
        if (self.InFlight.contains(key)) {
            // already being loaded; just return what’s there once it lands
            // since this is single-threaded, best is to return null -> caller will retry later
            // but easier: temporarily insert a stub and return it.
            // We'll do the stub approach:
        }
        // mark in-flight
        try self.InFlight.put(key, {});
        defer _ = self.InFlight.remove(key);

        var dll_struct: *Dll = try self.Allocator.create(Dll);
        dll_struct.Path = dllPath;

        // Read file
        var dll_size: usize = 0;
        const dll_bytes = try self.LoadDllInMemory(dllPath, &dll_size) orelse return null;

        // Headers + map
        var nt = ResolveNtHeaders(dll_bytes);
        var delta: usize = 0;
        const base = try self.MapSections(nt, dll_bytes, &delta);
        dll_struct.BaseAddr = base;
        nt = ResolveNtHeaders(base);

        // Relocations
        try ResolveRVA(base, nt, delta);

        // Build exports (case-insensitive)
        try self.ResolveExports(dll_struct);

        // Put early to break import cycles
        try self.LoadedDlls.put(dllPath.shortPath16, dll_struct);

        // Imports
        try self.ResolveImportTable(base, nt, dllPath, dll_struct);

        // Optional delay-loads (currently disabled)
        // try self.fixDelayImports(dll_struct);

        // Patch exported stubs (GPA/GMH/LL) if present
        try self.ResolveImportInconsistencies(dll_struct);

        log.info16("executing ", .{}, dll_struct.Path.shortPath16);
        // Execute TLS + DllMain
        try self.ExecuteDll(dll_struct);

        return dll_struct;
    }
};
