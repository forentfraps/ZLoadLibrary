const std = @import("std");
const win = std.os.windows;
const clr = @import("clr.zig");
const sneaky_memory = @import("memory.zig");
const logger = @import("sys_logger"); // normalized
const winc = @import("Windows.h.zig");
const apiset = @import("apiset.zig");
const U16Set = std.HashMap([]const u16, void, U16KeyCtx, 80);

const GENERIC_WRITE: u32 = 0x40000000;
const GENERIC_READ: u32 = 0x80000000;
const FILE_SHARE_READ: u32 = 0x00000001;
const FILE_SHARE_WRITE: u32 = 0x00000002;
const OPEN_EXISTING: u32 = 3;
const FILE_ATTRIBUTE_NORMAL: u32 = 0x00000080;
const MEM_RESERVE: u32 = 0x00002000;
const MEM_COMMIT: u32 = 0x00001000;
const PAGE_NOACCESS: u32 = 0x01;
const PAGE_READONLY: u32 = 0x02;
const PAGE_READWRITE: u32 = 0x04;
const PAGE_WRITECOPY: u32 = 0x08;
const PAGE_EXECUTE: u32 = 0x10;
const PAGE_EXECUTE_READ: u32 = 0x20;
const PAGE_EXECUTE_READWRITE: u32 = 0x40;
const PAGE_EXECUTE_WRITECOPY: u32 = 0x80;

// Modifiers (OR with above)
const PAGE_GUARD: u32 = 0x100;
const PAGE_NOCACHE: u32 = 0x200;
const PAGE_WRITECOMBINE: u32 = 0x400;

const W = std.unicode.utf8ToUtf16LeStringLiteral;
pub fn stub() callconv(.winapi) void {
    std.debug.print("stub called\n", .{});
}

extern fn UniversalStub() void;

const U16KeyCtx = struct {
    const Self = @This();
    pub fn hash(_: Self, key: []const u16) u64 {
        // Hash the bytes of the UTF-16 slice
        var h = std.hash.Wyhash.init(0);
        h.update(std.mem.sliceAsBytes(key));
        return h.final();
    }
    pub fn eql(_: Self, a: []const u16, b: []const u16) bool {
        return std.mem.eql(u16, a, b);
    }
};
pub const OwnedZ16 = struct {
    alloc: std.mem.Allocator,
    raw: []u16, // exact allocation INCLUDING sentinel
    z: [:0]u16, // view with len excluding sentinel

    const Self = @This();

    pub fn deinit(self: *Self) void {
        if (self.raw.len != 0) self.alloc.free(self.raw);
        // self.* = .{ .alloc = self.alloc, .raw = &[_]u16{}, .z = @ptrCast(&[_:0]u16{}) };
    }
    fn up16(c: u16) u16 {
        return if (c >= 'a' and c <= 'z') c - 32 else c;
    }
    fn ensureNoDoulbeSentinel(self: *Self) void {
        // Invariant we want:
        //  - self.raw.len == payload + 1
        //  - self.raw[payload] == 0
        //  - self.z is a [:0] view over the payload (len == payload)
        if (self.raw.len == 0) return;

        // Make sure the last element is a sentinel (should already be true from allocSentinel).
        if (self.raw[self.raw.len - 1] != 0) {
            self.raw[self.raw.len - 1] = 0;
        }

        // Collapse any *run* of trailing 0s down to a single sentinel and
        // update the slice lengths accordingly.
        var payload: usize = self.raw.len - 1; // last valid content index + 1
        while (payload > 0 and self.raw[payload - 1] == 0) : (payload -= 1) {}

        // Write the single sentinel at the new end (harmless if already 0)
        self.raw[payload] = 0;

        // Shrink views to drop any extra 0s from the payload region
        self.raw = self.raw[0 .. payload + 1];
        self.z = @ptrCast(self.raw[0..payload]); // [:0]u16 where sentinel is at index payload
    }
    pub fn toUpperAsciiInPlace(self: *Self) void {
        var i: usize = 0;
        while (i < self.z.len) : (i += 1) {
            const c = self.z[i];
            if (c >= 'a' and c <= 'z') self.z[i] = c - 32;
        }
    }
    pub fn fromU8(alloc: std.mem.Allocator, s_in: []const u8) !Self {
        var n: usize = s_in.len;
        if (n > 0 and s_in[n - 1] == 0) n -= 1;
        var z = try alloc.allocSentinel(u16, n, 0);
        var i: usize = 0;
        while (i < n) : (i += 1) z[i] = @intCast(s_in[i]);
        return .{ .alloc = alloc, .raw = z[0 .. n + 1], .z = z };
    }
    pub fn fromU8z(alloc: std.mem.Allocator, zsrc: [*:0]const u8) !Self {
        const n = std.mem.len(zsrc);
        var z = try alloc.allocSentinel(u16, n, 0);
        var i: usize = 0;
        while (i < n) : (i += 1) z[i] = @intCast(zsrc[i]);
        return .{ .alloc = alloc, .raw = z[0 .. n + 1], .z = z };
    }
    pub fn fromU16(alloc: std.mem.Allocator, s: []const u16) !Self {
        var n = s.len;
        if (n > 0 and s[n - 1] == 0) n -= 1; // drop caller's NUL if present
        var z = try alloc.allocSentinel(u16, n, 0); // guarantees one trailing NUL
        @memcpy(z[0..n], s[0..n]); // copy payload only
        const out = Self{ .alloc = alloc, .raw = z[0 .. n + 1], .z = z };
        return out; // already normalized
    }
    pub fn replaceWithZ16(self: *Self, nz: [:0]const u16) !void {
        var z = try self.alloc.allocSentinel(u16, nz.len, 0);
        @memcpy(z[0..nz.len], nz);
        if (self.raw.len != 0) self.alloc.free(self.raw);
        self.raw = z[0 .. nz.len + 1];
        self.z = z;
        self.ensureNoDoulbeSentinel(); // normalize
    }
    pub fn view(self: *const Self) [:0]const u16 {
        return self.z;
    }
    pub fn viewMut(self: *Self) [:0]u16 {
        return self.z;
    }
    pub fn endsWithDll(self: *const Self) bool {
        const s = self.raw;
        if (s.len < 5) return false; // ".DLL" + 0
        return up16(s[s.len - 5]) == '.' and
            up16(s[s.len - 4]) == 'D' and
            up16(s[s.len - 3]) == 'L' and
            up16(s[s.len - 2]) == 'L';
    }
    // Canonicalize to UPPER + ".DLL" using a caller-provided temp buffer (no allocs)
    pub fn canonicalUpperDllUsing(self: *Self, buf: []u16) !void {
        // compute core len (exclude ".DLL" if present, exclude sentinel)
        const core_len: usize = if (self.endsWithDll()) self.raw.len - 5 else self.raw.len - 1;

        if (buf.len < core_len + 5) return error.BufferTooSmall;

        var i: usize = 0;
        while (i < core_len) : (i += 1) buf[i] = up16(self.raw[i]);

        // append ".DLL" + sentinel
        buf[i + 0] = '.';
        buf[i + 1] = 'D';
        buf[i + 2] = 'L';
        buf[i + 3] = 'L';
        buf[i + 4] = 0;

        // IMPORTANT: pass *payload* length to replaceWithZ16 (exclude the sentinel)
        const nz: [:0]u16 = @ptrCast(buf[0 .. core_len + 4]);
        try self.replaceWithZ16(nz);
    }
    // Convenience: canonicalize with an internal stack buffer (good for short names)
    pub fn canonicalUpperDll(self: *Self) !void {
        var tmp: [260]u16 = undefined;
        try self.canonicalUpperDllUsing(tmp[0..]);
    }

    // From ASCII bytes -> uppercase UTF-16 Z (single alloc)
    pub fn fromAsciiUpper(alloc: std.mem.Allocator, s: []const u8) !Self {
        // allocate s.len + sentinel
        var z = try alloc.allocSentinel(u16, s.len, 0);
        var i: usize = 0;
        while (i < s.len) : (i += 1) {
            z[i] = up16(s[i]);
        }
        return .{ .alloc = alloc, .raw = z[0 .. s.len + 1], .z = z };
    }
};

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
    InMemoryOrderLinks: win.LIST_ENTRY,
    Reserved2: [4]usize,
    DllBase: ?*anyopaque,
    EntryPoint: ?*anyopaque,
    Reserved3: usize,
    fullDllName: UNICODE_STRING,
    BaseDllName: UNICODE_STRING,
    Reserved5: usize,
    TimeDateStamp: u32,
};
// typedef struct _PEB_LDR_DATA
// {
//     ULONG Length;
//     BOOLEAN Initialized;
//     HANDLE SsHandle;
//     LIST_ENTRY InLoadOrderModuleList;
//     LIST_ENTRY InMemoryOrderModuleList;
//     LIST_ENTRY InInitializationOrderModuleList;
//     PVOID EntryInProgress;
//     BOOLEAN ShutdownInProgress;
//     HANDLE ShutdownThreadId;
// } PEB_LDR_DATA, *PPEB_LDR_DATA;
const PEB_LDR_DATA = extern struct {
    reserved: *anyopaque,

    InLoadOrderModuleList: win.LIST_ENTRY,
    InMemoryOrderModuleList: win.LIST_ENTRY,
    InInitializationOrderModuleList: win.LIST_ENTRY,
    EntryInProgress: *anyopaque,
    ShutdownInProgress: win.BOOLEAN,
    ShutdownThreadId: win.HANDLE,
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
const colour = logger.SysLoggerColour;
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

pub var log: logger.SysLogger = undefined;
var first_start: bool = true;

// ===== Public structs =====

pub const Dll = struct {
    // store upper-cased export names for case-insensitive lookups
    NameExports: std.StringHashMap(*anyopaque) = undefined,
    OrdinalExports: std.AutoHashMap(u16, *anyopaque) = undefined,
    BaseAddr: [*]u8 = undefined,
    Path: *DllPath = undefined,

    ExportBase: u32 = 0,
    NumberOfFunctions: u32 = 0,

    const Self = @This();
    pub fn ResolveByName(self: *Dll, up_name: []const u8) ?*anyopaque {
        return self.NameExports.get(up_name);
    }
    pub fn ResolveByOrdinal(self: *Dll, ord: u16) ?*anyopaque {
        return self.OrdinalExports.get(ord);
    }
    pub fn getProc(self: *Self, comptime T: type, name: []const u8) !*const T {
        const map: std.StringHashMap(*anyopaque) = self.NameExports;
        var buf: [128]u8 = undefined;
        const up = toUpperTemp(&buf, name);
        const p = map.get(up) orelse return DllError.FuncResolutionFailed;
        return @ptrCast(@alignCast(p));
    }
};

pub var GLOBAL_DLL_LOADER: *DllLoader = undefined;

// ===== GPA/GMH stubs (optional to keep) =====

pub fn GetProcAddress(hModule: [*]u8, procname: [*:0]const u8) callconv(.winapi) ?*anyopaque {
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

pub fn GetModuleHandleA(moduleName_: ?[*:0]const u8) callconv(.winapi) ?[*]u8 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    const self = GLOBAL_DLL_LOADER;

    if (moduleName_) |moduleName| {
        var owned = OwnedZ16.fromU8z(self.Allocator, moduleName) catch return null;
        defer owned.deinit();
        return GetModuleHandleW(owned.view());
    } else {
        const peb: usize = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> usize),
            :
            : .{ .memory = true });
        const addr: [*]u8 = @ptrFromInt(peb + 0x10);
        return addr;
    }
}

pub fn GetModuleHandleW(moduleName16_: ?[*:0]const u16) callconv(.winapi) ?[*]u8 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();

    if (moduleName16_) |moduleName16| {
        const len = std.mem.len(moduleName16) + 1;
        const self = GLOBAL_DLL_LOADER;

        // own a Z16 copy for all downstream uses
        var owned = OwnedZ16.fromU16(self.Allocator, moduleName16[0..len]) catch return null;
        defer owned.deinit();

        var dllPath = (self.getDllPaths(owned.view()) catch {
            return null;
        }) orelse return null;

        dllPath.normalize();
        if (self.LoadedDlls.contains(@constCast(dllPath.shortKey()))) {
            return self.LoadedDlls.get(@constCast(dllPath.shortKey())).?.BaseAddr;
        }
        const resulting = self.ZLoadLibrary(owned.view()) catch return null;
        if (resulting) |d| return d.BaseAddr;
        return null;
    } else {
        const peb: usize = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> usize),
            :
            : .{ .memory = true });
        const addr: *[*]u8 = @ptrFromInt(peb + 0x10);
        return addr.*;
    }
}

pub fn LoadLibraryA_stub(libname: [*:0]const u8) callconv(.winapi) ?[*]u8 {
    const self = GLOBAL_DLL_LOADER;
    var name16 = OwnedZ16.fromU8z(self.Allocator, libname) catch return null;
    defer name16.deinit();
    return LoadLibraryW_stub(@ptrCast(name16.viewMut().ptr));
}

pub fn LoadLibraryW_stub(libname16: [*:0]u16) callconv(.winapi) ?[*]u8 {
    const key: []u16 = libname16[0..std.mem.len(libname16)];
    if (GLOBAL_DLL_LOADER.LoadedDlls.contains(key)) {
        return GLOBAL_DLL_LOADER.LoadedDlls.get(key).?.BaseAddr;
    }
    const dll = GLOBAL_DLL_LOADER.ZLoadLibrary(@ptrCast(libname16[0..std.mem.len(libname16)])) catch return null;
    if (dll) |d| return d.BaseAddr;
    return null;
}
// ===== Hash map context for u16 keys =====

const MappingContext = struct {
    const Self = @This();
    pub fn hash(_: Self, key: []u16) u64 {
        const len = key.len;
        const u8ptr: [*]const u8 = @ptrCast(key.ptr);
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(u8ptr[0 .. len * 2]);
        return hasher.final();
    }
    pub fn eql(_: Self, a: []u16, b: []u16) bool {
        return std.mem.eql(u16, a, b);
    }
};

pub const u16HashMapType = std.HashMap([]u16, *Dll, MappingContext, 80);

// ===== DllPath =====

pub const DllPath = struct {
    full: OwnedZ16,
    short: OwnedZ16,

    pub fn shortView(self: *const DllPath) [:0]const u16 {
        return self.short.view();
    }
    pub fn fullView(self: *const DllPath) [:0]const u16 {
        return self.full.view();
    }

    // NEW: for u16HashMapType (K = []u16)
    pub fn shortKey(self: *const DllPath) []u16 {
        const raw = self.short.raw; // [:0]const u16
        return @constCast(raw[0..raw.len]); // []u16 (no sentinel)
    }

    pub fn normalize(self: *DllPath) void {
        // uppercase only the short/basename (your old behavior)
        self.short.toUpperAsciiInPlace();
    }

    pub fn deinit(self: *DllPath) void {
        var f = self.full;
        f.deinit();
        var s = self.short;
        s.deinit();
    }
};
// ===== Loader =====

pub const DllLoader = struct {
    LoadedDlls: u16HashMapType = undefined,
    Allocator: std.mem.Allocator,
    HeapAllocator: sneaky_memory.HeapAllocator = undefined,
    InFlight: U16Set = undefined,

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .LoadedDlls = undefined,
            .Allocator = allocator,
            .InFlight = U16Set.init(allocator),
        };
    }
    pub fn getDllByName(self: *DllLoader, name: []const u8) !*Dll {
        // ASCII -> UPPER Z16 via OwnedZ16
        // log.info("getDllByName: Name u8 {s}\n", .{name});
        var up = try OwnedZ16.fromAsciiUpper(self.Allocator, name);
        // log.info16("raw", .{}, up.raw);
        // log.info16("z", .{}, up.z);
        defer up.deinit();

        // Ensure ".DLL" (UPPER too)
        try up.canonicalUpperDll();
        // log.info16("raw {d}", .{up.raw.len}, up.raw);
        // log.info16("z", .{}, up.z);

        if (self.LoadedDlls.get(up.raw)) |dll| return dll;
        return DllError.LoadFailed;
    }

    pub fn getLoadedDlls(self: *Self) !void {
        // Enumerate existing loader list into our map (read-only snapshot)
        const peb: *PEB = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> *PEB),
            :
            : .{ .memory = true });
        const ldr = peb.Ldr;
        const head: *win.LIST_ENTRY = ldr.InMemoryOrderModuleList.Flink;
        var curr: *win.LIST_ENTRY = head.Flink;

        self.LoadedDlls = u16HashMapType.init(self.Allocator);

        while (true) : ({
            curr = curr.Flink;
        }) {
            const entry: *LDR_DATA_TABLE_ENTRY =
                @fieldParentPtr("InMemoryOrderLinks", curr);
            const base_name: UNICODE_STRING = entry.BaseDllName;

            if (base_name.Buffer != null and (base_name.Length / 2) <= 260) {
                // allocate dll record
                var dll: *Dll = try self.Allocator.create(Dll);
                dll.BaseAddr = @ptrCast(entry.DllBase);

                // lengths include room we add for sentinel when copying (+1)
                const full_len: usize = entry.fullDllName.Length / 2 + 1;
                const base_len: usize = entry.BaseDllName.Length / 2 + 1;

                // own the two paths via OwnedZ16
                const full_src: []const u16 = entry.fullDllName.Buffer.?[0..full_len];
                const base_src: []const u16 = entry.BaseDllName.Buffer.?[0..base_len];

                var full_owned = try OwnedZ16.fromU16(self.Allocator, full_src);
                errdefer full_owned.deinit();

                var short_owned = try OwnedZ16.fromU16(self.Allocator, base_src);
                errdefer short_owned.deinit();

                // create and fill DllPath
                dll.Path = try self.Allocator.create(DllPath);
                dll.Path.* = .{
                    .full = full_owned,
                    .short = short_owned,
                };
                dll.Path.normalize(); // uppercase short name, used as the key

                // build exports before inserting
                try self.ResolveExports(dll);

                // use the short (uppercased) name as the map key
                try self.LoadedDlls.put(dll.Path.shortKey(), dll);
            }
            if (curr == head) break;
        }
    }
    // ===== Export table (case-insensitive names, ordinals, forwarders later) =====
    pub fn ResolveExports(self: *Self, dll: *Dll) !void {
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
        try mod16.canonicalUpperDll();
        // log.info16("Forwarder found: ", .{}, mod16.raw);
        if (apiset.ApiSetResolve(mod16.view())) |host_z| {
            const host_sz: [:0]u16 = @ptrCast(host_z);
            try mod16.replaceWithZ16(host_sz);
            try mod16.canonicalUpperDll(); // ensure UPPER + .DLL
            // log.info("Apihost\n", .{});
        } else {
            // log.info("native host\n", .{});
            try mod16.canonicalUpperDll();
        }
        // log.info16("post api deduction ", .{}, mod16.raw);
        const dep: *Dll = (try self.ZLoadLibrary(mod16.view())) orelse {
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
    pub fn getDllPaths(self: *Self, libname16_: [:0]const u16) !?*DllPath {
        log.setContext(logtags.PathRes);
        defer log.rollbackContext();

        const kernel32 = (try self.getDllByName("kernel32.dll"));

        const GetFileAttributesW =
            try kernel32.getProc(fn ([*:0]u16) callconv(.winapi) c_int, "GetFileAttributesW");

        const GetEnvironmentVariableW =
            try kernel32.getProc(fn ([*]const u16, [*:0]u16, c_uint) callconv(.winapi) c_uint, "GetEnvironmentVariableW");

        const GetSystemDirectoryW =
            try kernel32.getProc(fn ([*]u16, usize) callconv(.winapi) c_int, "GetSystemDirectoryW");

        const GetLastError =
            try kernel32.getProc(fn () callconv(.winapi) c_int, "GetLastError");

        const SetLastError =
            try kernel32.getProc(fn (c_int) callconv(.winapi) void, "SetLastError");

        // helper: last index of '\' or '/' in a [:0] string (returns usize or ~usize if none)
        const lastSlash = struct {
            fn find(z: [:0]const u16) ?usize {
                var i: isize = @intCast(z.len);
                i = i - 2; // skip sentinel
                while (i >= 0) : (i -= 1) {
                    const c = z[@intCast(i)];
                    if (c == '\\' or c == '/') return @intCast(i);
                }
                return null;
            }
        }.find;

        // helper: build DllPath (OwnedZ16-backed) from a full path [:0] slice
        const makePath = struct {
            fn build(alloc: std.mem.Allocator, full_z: [:0]const u16) !*DllPath {
                // Own full path
                var full_owned = try OwnedZ16.fromU16(alloc, full_z[0..full_z.len]);
                errdefer full_owned.deinit();

                // Basename slice of full_z (still [:0])
                const cut = lastSlash(full_z);
                const base_z: [:0]const u16 = if (cut) |p|
                    @ptrCast(full_z[p + 1 .. full_z.len :0])
                else
                    full_z;

                // Own short/basename
                var short_owned = try OwnedZ16.fromU16(alloc, base_z[0..base_z.len]);
                errdefer short_owned.deinit();

                // Assemble DllPath
                var dp = try alloc.create(DllPath);
                dp.* = .{ .full = full_owned, .short = short_owned };
                dp.normalize(); // uppercase short name (your map key behavior)
                return dp;
            }
        }.build;

        // decide: is libname16_ already a path? (drive, UNC, or any slash)
        const is_path = blk: {
            var has_slash = false;
            var i: usize = 0;
            while (i + 1 < libname16_.len) : (i += 1) { // exclude sentinel
                const c = libname16_[i];
                if (c == '\\' or c == '/') {
                    has_slash = true;
                    break;
                }
            }
            // drive "X:\"
            const drive_path =
                libname16_.len >= 3 and
                ((libname16_[0] >= 'A' and libname16_[0] <= 'Z') or (libname16_[0] >= 'a' and libname16_[0] <= 'z')) and
                libname16_[1] == ':' and
                (libname16_[2] == '\\' or libname16_[2] == '/');

            // UNC "\\"
            const unc_path =
                libname16_.len >= 3 and
                libname16_[0] == '\\' and libname16_[1] == '\\';

            break :blk (has_slash or drive_path or unc_path);
        };

        if (is_path) {
            // treat as full path directly
            return try makePath(self.Allocator, libname16_);
        }

        // --- Search PATH + ".\" + SystemDirectory ---

        var PATH: [33000:0]u16 = undefined;
        const PATH_s = W("PATH");

        var len: usize = GetEnvironmentVariableW(PATH_s.ptr, &PATH, 32767);
        // append ".\" and a trailing ';'
        PATH[len] = @intCast('.');
        PATH[len + 1] = @intCast('\\');
        PATH[len + 2] = @intCast(';');
        len += 3;

        // append SystemDirectory
        const syslen: usize = @intCast(GetSystemDirectoryW(PATH[len..].ptr, 30));
        PATH[len + syslen] = 0;

        var i: usize = 0;
        var start_pointer: usize = 0;

        while (PATH[i] != 0) : (i += 1) {
            // split by ';' (ASCII)
            if ((PATH[i] & 0xff00 == 0) and @as(u8, @intCast(PATH[i])) == ';') {
                const end_pointer = i;

                // Compose "<dir>\<libname>"
                const tmp_len = (end_pointer - start_pointer) + 1 + libname16_.len; // + '\' + lib + sentinel
                const tmp_alloc = try self.Allocator.alloc(u16, tmp_len);
                defer self.Allocator.free(tmp_alloc); // freed unless we succeed
                var tmp_z: [:0]u16 = @ptrCast(tmp_alloc);

                // dir
                std.mem.copyForwards(u16, tmp_z[0 .. end_pointer - start_pointer], PATH[start_pointer..end_pointer]);
                // '\'
                tmp_z[end_pointer - start_pointer] = @intCast('\\');
                // libname (includes its sentinel)
                std.mem.copyForwards(
                    u16,
                    tmp_z[end_pointer - start_pointer + 1 .. tmp_len],
                    libname16_,
                );

                // log.info16("u16 search string ", .{}, tmp_z);
                SetLastError(0);
                _ = GetFileAttributesW(tmp_z.ptr);
                const err: c_int = GetLastError();
                if (err == 0) {
                    // found! Build and return OwnedZ16-backed DllPath
                    return try makePath(self.Allocator, tmp_z);
                }

                start_pointer = end_pointer + 1;
            }
        }

        // not found
        return null;
    }

    // ===== File mapping =====
    pub fn LoadDllInMemory(self: *Self, dllPath: *DllPath, dllSize: *usize) !?[*]u8 {
        const kernel32 = (try self.getDllByName("kernel32.dll"));

        const CreateFileW =
            try kernel32.getProc(
                fn ([*:0]const u16, u32, u32, ?*win.SECURITY_ATTRIBUTES, u32, u32, ?*anyopaque) callconv(.winapi) *anyopaque,
                "CreateFileW",
            );

        const CloseHandle =
            try kernel32.getProc(fn (*anyopaque) callconv(.winapi) c_int, "CloseHandle");

        const GetFileSizeEx =
            try kernel32.getProc(fn (*anyopaque, *i64) callconv(.winapi) c_int, "GetFileSizeEx");

        const ReadFile =
            try kernel32.getProc(fn (*anyopaque, [*]u8, u32, ?*u32, ?*win.OVERLAPPED) callconv(.winapi) c_int, "ReadFile");
        // log.info16("LoadDllInMemory dllPath.path16 ", .{}, dllPath.fullView());
        const dll_handle = CreateFileW(dllPath.fullView(), GENERIC_READ, 0, null, OPEN_EXISTING, 0, null);
        defer _ = CloseHandle(dll_handle);

        var dll_size_i: i64 = 0;
        if ((GetFileSizeEx(dll_handle, &dll_size_i) <= 0)) return DllError.Size;
        dllSize.* = @intCast(dll_size_i);

        const dll_bytes: [*]u8 = (try self.Allocator.alloc(u8, dllSize.*)).ptr;
        var bytes_read: winc.DWORD = 0;
        _ = ReadFile(dll_handle, dll_bytes, @as(u32, @intCast(dllSize.*)), &bytes_read, null);
        return dll_bytes;
    }

    pub fn ResolveNtHeaders(dll_bytes: [*]u8) !*const winc.IMAGE_NT_HEADERS {
        const dos_headers: *winc.IMAGE_DOS_HEADER = @ptrCast(@alignCast(dll_bytes));
        const nt_headers: *const winc.IMAGE_NT_HEADERS =
            @ptrCast(@alignCast(dll_bytes[@intCast(dos_headers.e_lfanew)..]));
        const pesig = 0x4550;
        if (nt_headers.Signature != pesig) {
            return error.InvalidPESignature;
        }
        return nt_headers;
    }

    pub fn MapSections(
        self: *Self,
        nt_headers: *const winc.IMAGE_NT_HEADERS,
        dll_bytes: [*]u8,
        delta_image_base: *usize,
    ) ![*]u8 {
        const ntdll = (try self.getDllByName("ntdll.dll"));

        const ZwAllocateVirtualMemory = try ntdll.getProc(fn (
            i64,
            *?[*]u8,
            usize,
            *usize,
            u32,
            u32,
        ) callconv(.winapi) c_int, "ZwAllocateVirtualMemory");

        var dll_base_dirty: ?[*]u8 = null;
        var virtAllocSize: usize = nt_headers.OptionalHeader.SizeOfImage;

        var status: c_int = ZwAllocateVirtualMemory(
            -1,
            &dll_base_dirty,
            0,
            &virtAllocSize,
            MEM_RESERVE | MEM_COMMIT,

            PAGE_EXECUTE_READWRITE,
        );
        if (status < 0) {
            // try again once
            dll_base_dirty = null;
            status = ZwAllocateVirtualMemory(
                -1,
                &dll_base_dirty,
                0,
                &virtAllocSize,
                MEM_RESERVE | MEM_COMMIT,
                PAGE_EXECUTE_READWRITE,
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
        var new_nt = @constCast(try ResolveNtHeaders(dll_base));
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
        const relocations = nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_BASERELOC];
        const relocation_table: [*]u8 = @ptrCast(@alignCast(dll_base[relocations.VirtualAddress..]));
        var relocations_processed: u32 = 0;

        while (relocations_processed < relocations.Size) {
            const relocation_block: *BASE_RELOCATION_BLOCK = @ptrCast(@alignCast(relocation_table[relocations_processed..]));
            relocations_processed += @sizeOf(BASE_RELOCATION_BLOCK);
            const relocations_count = (relocation_block.BlockSize - @sizeOf(BASE_RELOCATION_BLOCK)) / @sizeOf(BASE_RELOCATION_ENTRY);
            const relocation_entries: [*]align(1) BASE_RELOCATION_ENTRY = @ptrCast(@alignCast(relocation_table[relocations_processed..]));

            // log.info("New relocation_block\n", .{});
            for (0..relocations_count) |entry_index| {
                if (relocation_entries[entry_index].Type != 0) {
                    const relocation_rva: usize = relocation_block.PageAddress + relocation_entries[entry_index].Offset;
                    // log.info("Reloction entry index: {d} relocation rva {x} \n", .{
                    //     entry_index,
                    //     relocation_rva,
                    // });
                    const ptr: *align(1) usize = @ptrCast(@alignCast(dll_base[relocation_rva..]));
                    //log.info("Value before rva is {x} changing to {*}\n", .{ ptr.*, ptr });
                    ptr.* = ptr.* + delta_image_base;

                    //address_to_patch += delta_image_base;

                } else {
                    // log.crit("Type ABSOLUT offset: {d}\n", .{relocation_entries[entry_index].Offset});
                    // we ignore it
                }
                relocations_processed += @sizeOf(BASE_RELOCATION_ENTRY);
            }
            //log.info("block proc\n", .{});
        }

        log.rollbackContext();
    }

    // ===== Import resolution (API set, ordinals, forwarders) =====
    pub fn ResolveImportTable(
        self: *Self,
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

            // log.info("Resolve Import Table import name: {s}\n", .{lib_u8z});
            // 1) Own a UTF-16Z copy of the import name
            var owned = try OwnedZ16.fromU8z(self.Allocator, lib_u8z);
            // log.info16("owned Z  {d}", .{owned.z.len}, owned.z);
            // log.info16("owned raw {d}", .{owned.z.len}, owned.raw);
            defer owned.deinit(); // exactly once at the end of this descriptor

            // 2) If it’s an ApiSet, resolve to host (non-Z slice from the ApiSet map)
            if (apiset.ApiSetResolve(owned.view())) |host_z| {
                const host_sz: [:0]u16 = @ptrCast(host_z);
                try owned.replaceWithZ16(host_sz);
                try owned.canonicalUpperDll(); // ensure UPPER + .DLL
                // log.info("Apihost\n", .{});
            } else {
                // log.info("native host\n", .{});
                try owned.canonicalUpperDll();
            }
            const libraryNameToLoad16 = owned;
            // log.info16("librarynametoload16 {d}", .{libraryNameToLoad16.raw.len}, libraryNameToLoad16.raw);

            // Now you have a guaranteed, owned, zero-terminated, canonical UPPERCASE short name

            // 3) Load (or reuse) the library
            var library: ?*Dll = undefined;
            if (std.mem.eql(u16, dllPath.shortKey(), libraryNameToLoad16.raw)) {
                library = dll_struct;
            } else {
                // log.info16("Trying to load  -> ", .{}, libraryNameToLoad16.raw);
                library = try self.ZLoadLibrary(libraryNameToLoad16.z);
                // }
                if (library == null) return DllError.LoadFailed; // (or `continue;` if you prefer soft-fail)

                // 4) Walk thunks and resolve
                var orig_thunk_rva: u32 = import_descriptor.unnamed_0.OriginalFirstThunk;
                const thunk_rva: u32 = import_descriptor.FirstThunk;
                if (orig_thunk_rva == 0) {
                    orig_thunk_rva = import_descriptor.FirstThunk;
                }
                var orig: *winc.IMAGE_THUNK_DATA =
                    @ptrCast(@alignCast(dll_base[orig_thunk_rva..]));
                var thunk: *winc.IMAGE_THUNK_DATA =
                    @ptrCast(@alignCast(dll_base[thunk_rva..]));

                var tmpname: [256]u8 = undefined;

                while (orig.u1.AddressOfData != 0) : ({
                    thunk = @ptrFromInt(@intFromPtr(thunk) + @sizeOf(winc.IMAGE_THUNK_DATA));
                    orig = @ptrFromInt(@intFromPtr(orig) + @sizeOf(winc.IMAGE_THUNK_DATA));
                }) {
                    if (isOrdinalLookup64(orig.u1.AddressOfData)) {
                        // Ordinal path (REAL ordinal)
                        const ord = ordinalOf64(orig.u1.AddressOfData);
                        var addr = library.?.ResolveByOrdinal(ord) orelse {
                            log.info16("Failed ordinal {x} lookup for library -> ", .{ord}, libraryNameToLoad16.raw);
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
                            log.info16("Current lib to load is ", .{}, dllPath.shortKey());
                            log.info16("Loading from ", .{}, library.?.Path.full.raw);
                            log.info16("Failed name {s} in -> ", .{up}, libraryNameToLoad16.raw);
                            return DllError.FuncResolutionFailed;
                        };

                        // Forwarder?
                        const addr_bytes: [*]const u8 = @ptrCast(addr);
                        if (looksLikeForwarderString(addr_bytes)) {
                            // log.crit("LooksLikeForwarederString: {s}\n", .{addr_bytes[0..10]});
                            const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(addr)), 0);
                            // log.crit("FWD to resolve {s}\n", .{fwd_slice});
                            addr = try self.resolveForwarder(fwd_slice);
                        }

                        thunk.u1.Function = @intFromPtr(addr);
                    }
                }
            }
        }
    }
    // Optional delay-load resolver (off by default)
    pub fn fixDelayImports(
        self: *@This(),
        dll_base: [*]u8,
        nt_headers: *const winc.IMAGE_NT_HEADERS,
        dllPath: *DllPath,
        dll_struct: *Dll,
    ) !void {
        log.setContext(logtags.ImpRes);
        defer log.rollbackContext();

        const delaydir = nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT];
        if (delaydir.Size == 0) return;

        // Helper: convert RVA/VA fields from delay descriptor into pointers
        const ptrFromAttr = struct {
            fn ptrFromAttr(comptime T: type, base: [*]u8, attrs: u32, rva_or_va: u32) *T {
                const addr: usize = if ((attrs & 0x1) != 0) // dlattrRva
                    @intFromPtr(base) + rva_or_va
                else
                    @intCast(rva_or_va);
                return @ptrFromInt(addr);
            }
        }.ptrFromAttr;

        // Walk IMAGE_DELAYLOAD_DESCRIPTOR array until DllNameRVA == 0
        var desc: *const IMAGE_DELAYLOAD_DESCRIPTOR =
            @ptrCast(@alignCast(dll_base[delaydir.VirtualAddress..]));

        while (desc.DllNameRVA != 0) : (desc = @ptrFromInt(@intFromPtr(desc) + @sizeOf(IMAGE_DELAYLOAD_DESCRIPTOR))) {
            // DLL name (ASCII z)
            const lib_u8z: ?[*:0]const u8 = @ptrCast(dll_base[desc.DllNameRVA..]);
            if (lib_u8z == null) break;
            log.info("u8 lib delay: '{s}'\n", .{lib_u8z.?});

            // Own & canonicalize -> UPPER + .DLL (and resolve apisets)
            var owned = try OwnedZ16.fromU8z(self.Allocator, lib_u8z.?);
            defer owned.deinit();

            if (apiset.ApiSetResolve(owned.view())) |host_z| {
                log.info16("Apihost delay resolved: ", .{}, host_z);
                if (host_z.len != 0) {
                    const host_sz: [:0]u16 = @ptrCast(host_z);
                    try owned.replaceWithZ16(host_sz);
                } else {
                    log.crit16("FAILED TO RESOLVE API HOST ", .{}, owned.view());
                    continue;
                }
                try owned.canonicalUpperDll();
            } else {
                try owned.canonicalUpperDll();
            }

            // Load (or reuse)
            log.info16("trying to delay load", .{}, owned.raw);
            const library: ?*Dll = if (std.mem.eql(u16, dllPath.shortKey(), owned.raw))
                dll_struct
            else
                try self.ZLoadLibrary(owned.view());
            // if (library == null) return DllError.LoadFailed;
            if (library == null) return;

            // Cache HMODULE location if present
            if (desc.ModuleHandleRVA != 0) {
                const pHMODULE = ptrFromAttr(?[*]u8, dll_base, desc.Attributes, desc.ModuleHandleRVA);
                pHMODULE.* = library.?.BaseAddr;
            }

            // Name table (INT) and IAT thunks
            if (desc.ImportNameTableRVA == 0 or desc.ImportAddressTableRVA == 0) {
                // nothing to fix for this descriptor
                continue;
            }

            var orig: *winc.IMAGE_THUNK_DATA =
                ptrFromAttr(winc.IMAGE_THUNK_DATA, dll_base, desc.Attributes, desc.ImportNameTableRVA);
            var thunk: *winc.IMAGE_THUNK_DATA =
                ptrFromAttr(winc.IMAGE_THUNK_DATA, dll_base, desc.Attributes, desc.ImportAddressTableRVA);

            var tmpname: [256]u8 = undefined;

            // Resolve each delayed thunk
            while (orig.u1.AddressOfData != 0) : ({
                thunk = @ptrFromInt(@intFromPtr(thunk) + @sizeOf(winc.IMAGE_THUNK_DATA));
                orig = @ptrFromInt(@intFromPtr(orig) + @sizeOf(winc.IMAGE_THUNK_DATA));
            }) {
                if (isOrdinalLookup64(orig.u1.AddressOfData)) {
                    // Ordinal
                    const ord = ordinalOf64(orig.u1.AddressOfData);
                    var addr = library.?.ResolveByOrdinal(ord) orelse {
                        log.info16("DelayImport: ordinal {x} not found in -> ", .{ord}, owned.raw);
                        return DllError.FuncResolutionFailed;
                    };

                    // Forwarder?
                    const addr_bytes: [*]const u8 = @ptrCast(addr);
                    if (looksLikeForwarderString(addr_bytes)) {
                        const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(addr)), 0);
                        addr = try self.resolveForwarder(fwd_slice);
                    }

                    thunk.u1.Function = @intFromPtr(addr);
                } else {
                    // By name
                    const ibn: *const winc.IMAGE_IMPORT_BY_NAME =
                        @ptrCast(@alignCast(dll_base[orig.u1.AddressOfData..]));
                    const name_z: [*:0]const u8 = @ptrCast(&ibn.Name);
                    const up = toUpperTemp(&tmpname, name_z[0..std.mem.len(name_z)]);

                    var addr = library.?.ResolveByName(up) orelse {
                        log.info16("DelayImport: name {s} not found in -> ", .{up}, owned.raw);
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

    // Patching exported stubs (case-insensitive now)
    pub fn ResolveImportInconsistencies(self: *Self, dll: *Dll) !void {
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
            @ptrCast(@alignCast(OptionalHeader[SizeOfOptionalHeader..]));
        return sectionHeader;
    }

    pub fn ExecuteDll(self: *Self, dll: *Dll) !void {
        const ntdll = (try self.getDllByName("ntdll.dll"));

        const NtProtectVirtualMemory = try ntdll.getProc(
            fn (i64, *const [*]u8, *const usize, c_int, *c_int) callconv(.winapi) c_int,
            "NtProtectVirtualMemory",
        );
        const NtFlushInstructionCache = try ntdll.getProc(
            fn (i32, ?[*]u8, usize) callconv(.winapi) c_int,
            "NtFlushInstructionCache",
        );

        const nt_headers = try ResolveNtHeaders(dll.BaseAddr);
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

        log.info("Starting tls\n", .{});
        // TLS
        if (nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_TLS].Size != 0) {
            const tls_dir: *const winc.IMAGE_TLS_DIRECTORY =
                @ptrCast(@alignCast(
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

        log.info("Starting DLLMain\n", .{});

        // DllMain
        if (nt_headers.OptionalHeader.AddressOfEntryPoint != 0) {
            const dll_entry: ?*const DLLEntry = @ptrCast(dll.BaseAddr[nt_headers.OptionalHeader.AddressOfEntryPoint..]);
            if (dll_entry) |run| {
                const hinst: win.HINSTANCE = @ptrCast(dll.BaseAddr);
                _ = run(hinst, winc.DLL_PROCESS_ATTACH, null);
            }
        }
        log.info("Out of dllmain\n", .{});
    }

    // ===== Optional: NO PEB FORGERY =====
    pub fn addDllToPEBList(self: *Self, dll: *Dll) !void {
        _ = self;
        _ = dll;
        // Intentionally not implemented. We do NOT forge or insert into PEB loader lists.
        // If you need discoverability, expose your own registry of loaded modules (self.LoadedDlls), which we already maintain.
        return;
    }

    // ===== The main loader =====
    pub fn ZLoadLibrary(self: *Self, libname16_: [:0]const u16) anyerror!?*Dll {
        if (first_start) {
            first_start = false;
            log = logger.SysLogger.init(colour_list.len, pref_list, colour_list);
            log.enabled = true;
        }
        log.setContext(logtags.RefLoad);
        defer log.rollbackContext();

        // Resolve full path + short name
        var dllPath = (try self.getDllPaths(libname16_)) orelse return null;
        dllPath.normalize();
        const key = dllPath.shortKey(); // already UPPERCASE & Z
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

        log.info16("starting to load {d}", .{dllPath.full.raw.len}, dllPath.full.raw);

        // Read file
        var dll_size: usize = 0;
        const dll_bytes = try self.LoadDllInMemory(dllPath, &dll_size) orelse return null;

        // Headers + map
        var nt = try ResolveNtHeaders(dll_bytes);
        var delta: usize = 0;
        const base = try self.MapSections(nt, dll_bytes, &delta);
        dll_struct.BaseAddr = base;
        nt = try ResolveNtHeaders(base);

        // Relocations
        try ResolveRVA(base, nt, delta);

        // Build exports (case-insensitive)
        try self.ResolveExports(dll_struct);

        // Put early to break import cycles
        try self.LoadedDlls.put(dllPath.shortKey(), dll_struct);

        // Imports
        try self.ResolveImportTable(base, nt, dllPath, dll_struct);

        // Optional delay-loads (currently disabled)
        try self.fixDelayImports(base, nt, dllPath, dll_struct);

        // Patch exported stubs (GPA/GMH/LL) if present
        try self.ResolveImportInconsistencies(dll_struct);

        // const entry = try self.CreateLdrDataTableEntryFromImageBase(dll_struct);
        // LdrpInsertHashTableEntry(entry);

        registerImageUnwindInfo(dll_struct);
        log.info16("executing ", .{}, dll_struct.Path.shortView());
        // Execute TLS + DllMain
        try self.ExecuteDll(dll_struct);

        return dll_struct;
    }
    pub fn CreateLdrDataTableEntryFromImageBase(
        self: *Self,
        dll: *Dll,
        // image_base: [*]u8,
        // dllPath: *DllPath,
    ) !*LDR_DATA_TABLE_ENTRY_FULL {
        const alloc = self.Allocator;
        const image_base = dll.BaseAddr;
        const dllPath = dll.Path;

        // ---- helpers ---------------------------------------------------------
        const initSelf = struct {
            fn initSelf(le: *win.LIST_ENTRY) void {
                le.Flink = le;
                le.Blink = le;
            }
        }.initSelf;
        const usFromZ = struct {
            fn usFromZ(z: [:0]const u16) UNICODE_STRING {
                // Length/MaximumLength are in *bytes*, Buffer is zero-terminated.
                return .{
                    .Length = @intCast(z.len * 2),
                    .MaximumLength = @intCast((z.len + 1) * 2),
                    .alignment = 0,
                    .Buffer = @ptrCast(@constCast(z.ptr)),
                };
            }
        }.usFromZ;

        // ---- PE headers ------------------------------------------------------
        const nt = try DllLoader.ResolveNtHeaders(image_base);
        const ep_rva = nt.OptionalHeader.AddressOfEntryPoint;
        const ep_ptr: ?*anyopaque = if (ep_rva != 0)
            @ptrCast(@alignCast(image_base[ep_rva..]))
        else
            null;

        // ---- allocate and fill ----------------------------------------------
        var e = try alloc.create(LDR_DATA_TABLE_ENTRY_FULL);
        // Zero anything we don't explicitly set
        @memset(@as([*]u8, @ptrCast(e))[0..@sizeOf(LDR_DATA_TABLE_ENTRY_FULL)], 0);

        initSelf(&e.InLoadOrderLinks);
        initSelf(&e.InMemoryOrderLinks);
        initSelf(&e.InInitializationOrderLinks);
        initSelf(&e.HashLinks);

        e.DllBase = image_base;
        e.EntryPoint = ep_ptr;
        e.SizeOfImage = nt.OptionalHeader.SizeOfImage;

        // The UNICODE_STRINGs reference the existing OwnedZ16 buffers in dllPath.
        e.FullDllName = usFromZ(dllPath.fullView());
        e.BaseDllName = usFromZ(dllPath.shortView());

        // Reasonable defaults; adjust if you maintain your own flags/load counts.
        e.Flags = 0;
        e.LoadCount = 1;
        e.TlsIndex = 0;
        e.TimeDateStamp = nt.FileHeader.TimeDateStamp;

        return e;
    }
};
// ===== Loader-compatible hashing (x65599), bucket index (32 buckets) =====

extern "ntdll" fn RtlUpcaseUnicodeChar(c: u16) callconv(.winapi) u16;

pub fn LdrpHashUnicodeString(us_opt: ?*const UNICODE_STRING) u64 {
    var h: u32 = 0;

    if (us_opt == null) return 0x8000_0000;

    const us = us_opt.?;
    const len_chars: usize = us.Length >> 1;

    // The original code reads the buffer pointer from the UNICODE_STRING.
    // Buffer might be declared as [*:0]u16; we don't need the sentinel here.
    const p0: [*]const u16 = @ptrCast(us.Buffer orelse return 0x8000_0000);

    var i: usize = 0;
    var p = p0;
    while (i < len_chars) : (i += 1) {
        var ch: u16 = p[0];
        p += 1;

        if (ch >= 'a') {
            if (ch <= 'z') {
                ch -= 32;
            } else if (ch >= 0xC0) {
                ch = asciiUpper16(ch);
            }
        }
        if (ch >= 0x0061) {
            if (ch <= 0x007A) {
                ch -%= 32;
            } else if (ch >= 0x00C0) {
                ch = RtlUpcaseUnicodeChar(ch);
            }
        }

        // h = (h * 65599 + ch) mod 2^32
        const t: u64 = @as(u64, h) * 65599 + @as(u64, ch);
        h = @truncate(t);
    }

    return if (h != 0) @as(u64, h) else 0x8000_0000;
}

inline fn ldrBucketIndex(hash: u64) usize {
    // 32 buckets => mask lower 5 bits
    return @intCast(hash & 0x1F);
}

// ===== Small helpers =====

inline fn isAsciiDotDLL(z: [:0]const u8) bool {
    return z.len >= 4 and std.mem.eql(u8, z[z.len - 4 ..], ".dll");
}

fn findSection(
    base: [*]u8,
    nt: *const winc.IMAGE_NT_HEADERS,
    name_z: []const u8,
) ?struct { p: [*]u8, size: usize } {
    var sec: [*]const winc.IMAGE_SECTION_HEADER = @ptrFromInt(
        @intFromPtr(nt) + @sizeOf(winc.IMAGE_NT_HEADERS),
    );
    var i: usize = 0;
    while (i < nt.FileHeader.NumberOfSections) : (i += 1) {
        const nm = sec[i].Name[0..8];
        var j: usize = 0;
        while (j < 8 and nm[j] != 0) : (j += 1) {}
        const s = nm[0..j];
        if (std.mem.eql(u8, s, name_z)) {
            return .{
                .p = @ptrCast(base[sec[i].VirtualAddress..]),
                .size = sec[i].Misc.VirtualSize,
            };
        }
    }
    return null;
}

// ===== Inverted Function Table (compatible layout) =====
// (Fields match what ntdll uses on x64: ImageBase/ImageSize + Exception dir + size.)

const RTL_INVERTED_FUNCTION_TABLE_ENTRY = extern struct {
    ImageBase: ?*anyopaque,
    ImageSize: u32,
    ExceptionDirectory: ?*anyopaque,
    ExceptionDirectorySize: u32,
};

const RTL_INVERTED_FUNCTION_TABLE = extern struct {
    Count: u32,
    MaxCount: u32,
    Epoch: u32, // padding/epoch; exact name varies by build
    Overflow: u32, // padding/flags; keep to match size/alignment
    Entries: ?[*]RTL_INVERTED_FUNCTION_TABLE_ENTRY,
};

// system VirtualProtect
extern "kernel32" fn VirtualProtect(
    lpAddress: ?*anyopaque,
    dwSize: usize,
    flNewProtect: u32,
    lpflOldProtect: *u32,
) callconv(.winapi) i32;

// public unwind registration (fallback if we can't patch MRDATA)
extern "kernel32" fn RtlAddFunctionTable(
    table: [*]winc.IMAGE_RUNTIME_FUNCTION_ENTRY,
    entry_count: u32,
    base_address: usize,
) callconv(.winapi) i32;

// Locate ntdll base using the real OS loader list (same as your getLoadedDlls).
fn getNtdllBase() ?[*]u8 {
    const peb: *PEB = asm volatile ("mov %gs:0x60, %rax"
        : [peb] "={rax}" (-> *PEB),
        :
        : .{ .memory = true });
    const head: *win.LIST_ENTRY = &peb.Ldr.InMemoryOrderModuleList;
    var curr: *win.LIST_ENTRY = head.Flink;
    var safety: usize = 0;
    while (safety < 2048) : (safety += 1) {
        const e: *LDR_DATA_TABLE_ENTRY =
            @fieldParentPtr("InMemoryOrderLinks", curr);
        if (e.BaseDllName.Buffer) |b| {
            const len = e.BaseDllName.Length / 2;
            const z = b[0..len];
            var is_ntdll = false;
            if (len >= 8) {
                var tmp: [16]u16 = undefined;
                var i: usize = 0;
                while (i < len and i < tmp.len - 1) : (i += 1) tmp[i] = if (z[i] >= 'a' and z[i] <= 'z') z[i] - 32 else z[i];
                tmp[i] = 0;
                const up: [:0]u16 = @ptrCast(tmp[0..i]);
                is_ntdll = std.mem.eql(u16, up, @as([:0]const u16, std.unicode.utf8ToUtf16LeStringLiteral("NTDLL.DLL")));
            }
            if (is_ntdll) return @ptrCast(e.DllBase);
        }
        curr = curr.Flink;
        if (curr == head) break;
    }
    return null;
}

// Try to find ntdll!LdrpInvertedFunctionTable by scanning .mrdata for a plausible header.
fn searchForLdrpInvertedFunctionTable(
    mrdata_out: *?*anyopaque,
    mrdata_size_out: *u32,
) ?*RTL_INVERTED_FUNCTION_TABLE {
    const ntdll = getNtdllBase() orelse return null;
    const nt = DllLoader.ResolveNtHeaders(ntdll) catch return null;

    const mr = findSection(ntdll, nt, ".mrdata") orelse
        (findSection(ntdll, nt, ".data") orelse return null);

    mrdata_out.* = mr.p;
    mrdata_size_out.* = @intCast(mr.size);

    // Scan by pointer-size granularity and validate candidates.
    const start: [*]u8 = mr.p;
    const end: [*]u8 = @ptrFromInt(@intFromPtr(start) + mr.size);
    var p: [*]u8 = start;

    while (@intFromPtr(p) + @sizeOf(RTL_INVERTED_FUNCTION_TABLE) < @intFromPtr(end)) : (p = @ptrFromInt(@intFromPtr(p) + @sizeOf(usize))) {
        const t: *RTL_INVERTED_FUNCTION_TABLE = @ptrCast(@alignCast(p));
        if (t.MaxCount == 0 or t.MaxCount > 512 or t.Count == 0 or t.Count > t.MaxCount) continue;
        if (t.Entries == null) continue;

        // Entries pointer should live inside MRDATA, and entry[0] should be NTDLL.
        const entries_ptr = @intFromPtr(t.Entries);
        if (!(entries_ptr >= @intFromPtr(start) and entries_ptr < @intFromPtr(end))) continue;

        const e0: *RTL_INVERTED_FUNCTION_TABLE_ENTRY = &t.Entries.?[0];
        if (@intFromPtr(e0.ImageBase.?) != @intFromPtr(ntdll)) continue;

        // Looks good enough.
        return t;
    }
    return null;
}

// Public helper: register unwind info either by patching MRDATA (preferred) or via RtlAddFunctionTable.
fn registerImageUnwindInfo(dll: *Dll) void {
    // image_base: [*]u8, nt: *const winc.IMAGE_NT_HEADERS
    const image_base = dll.BaseAddr;
    const nt = DllLoader.ResolveNtHeaders(image_base) catch unreachable;
    const dir = nt.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_EXCEPTION];
    if (dir.Size == 0) return;

    // Preferred path: patch LdrpInvertedFunctionTable (so lookups act like loader-mapped images)
    var mr: ?*anyopaque = null;
    var mr_size: u32 = 0;
    if (searchForLdrpInvertedFunctionTable(&mr, &mr_size)) |ift| {
        // Make MRDATA writable while we touch it
        var oldProt: u32 = 0;
        if (VirtualProtect(mr, mr_size, winc.PAGE_READWRITE, &oldProt) != 0) {
            // Insert sorted by ImageBase like the real routine does
            // var idx: u32 = 0;
            if (ift.Count == ift.MaxCount) {
                // Table full; fall through to RtlAddFunctionTable
            } else {
                // Find insertion point to keep array ordered by ImageBase
                const n = ift.Count;
                var insert_at: u32 = 1;
                while (insert_at < n) : (insert_at += 1) {
                    if (@intFromPtr(image_base) < @intFromPtr(ift.Entries.?[insert_at].ImageBase)) break;
                }
                if (insert_at != n) {
                    const move_len: usize = @intCast(n - insert_at);
                    const dst = ift.Entries.?[(insert_at + 1) .. (insert_at + 1) + move_len];
                    const src = ift.Entries.?[insert_at .. insert_at + move_len];
                    std.mem.copyBackwards(RTL_INVERTED_FUNCTION_TABLE_ENTRY, dst, src);
                }

                const ex_ptr: ?*anyopaque = @ptrCast(image_base + dir.VirtualAddress);
                ift.Entries.?[insert_at].ImageBase = image_base;
                ift.Entries.?[insert_at].ImageSize = nt.OptionalHeader.SizeOfImage;
                ift.Entries.?[insert_at].ExceptionDirectory = ex_ptr;
                ift.Entries.?[insert_at].ExceptionDirectorySize = dir.Size;
                ift.Count += 1;
            }

            var dontcare: u32 = 0;
            _ = VirtualProtect(mr, mr_size, oldProt, &dontcare);
            return;
        }
        // If we cannot make MRDATA writable, fall back below.
    }

    // Fallback: public dynamic function table registration
    const tbl: [*]winc.IMAGE_RUNTIME_FUNCTION_ENTRY =
        @ptrCast(@alignCast(image_base[dir.VirtualAddress..]));
    const cnt: u32 = @intCast(dir.Size / @sizeOf(winc.IMAGE_RUNTIME_FUNCTION_ENTRY));
    _ = RtlAddFunctionTable(tbl, cnt, @intFromPtr(image_base));
}

// ===== LdrpHashTable insertion =====
//
// A fuller LDR entry layout that includes HashLinks; compatible with Win7+ x64.
// Only the fields we read/write are defined here.
const LDR_DATA_TABLE_ENTRY_FULL = extern struct {
    InLoadOrderLinks: win.LIST_ENTRY,
    InMemoryOrderLinks: win.LIST_ENTRY,
    InInitializationOrderLinks: win.LIST_ENTRY,
    DllBase: ?*anyopaque,
    EntryPoint: ?*anyopaque,
    SizeOfImage: u32,
    FullDllName: UNICODE_STRING,
    BaseDllName: UNICODE_STRING,
    Flags: u32,
    LoadCount: u16,
    TlsIndex: u16,
    HashLinks: win.LIST_ENTRY,
    TimeDateStamp: u32,
    // (rest omitted)
};

// Classic InsertTailList
inline fn insertTailList(head: *win.LIST_ENTRY, node: *win.LIST_ENTRY) void {
    const blink = head.Blink;
    node.Flink = head;
    node.Blink = blink;
    blink.Flink = node;
    head.Blink = node;
}

// Find the base of ntdll!LdrpHashTable (array[32] of LIST_ENTRY) using the trick from MDSec:
//   table0 = HashLinks.Flink - (hash & 0x1F) * sizeof(LIST_ENTRY)
fn findLdrpHashTableBase() ?[*]win.LIST_ENTRY {
    const peb: *PEB = asm volatile ("mov %gs:0x60, %rax"
        : [peb] "={rax}" (-> *PEB),
        :
        : .{ .memory = true });
    const head: *win.LIST_ENTRY = &peb.Ldr.InInitializationOrderModuleList;
    var cur: *win.LIST_ENTRY = head.Flink;
    var cap: usize = 0;

    while (cap < 2048) : (cap += 1) {
        const e: *LDR_DATA_TABLE_ENTRY_FULL =
            @fieldParentPtr("InInitializationOrderLinks", cur);
        cur = cur.Flink;

        if (e.HashLinks.Flink == &e.HashLinks) continue; // empty bucket link
        // Compute hash of this entry's BaseDllName
        // const h = ldrHashUnicodeStringX65599CaseI(e.BaseDllName);
        const h = LdrpHashUnicodeString(&e.BaseDllName);
        const idx = ldrBucketIndex(h);
        const list_after_head = e.HashLinks.Flink;
        const table0: [*]win.LIST_ENTRY = @ptrFromInt(
            @intFromPtr(list_after_head) - idx * @sizeOf(win.LIST_ENTRY),
        );
        return table0;
    }
    return null;
}

// Public: insert a module’s HashLinks into ntdll!LdrpHashTable.
// IMPORTANT: This expects `entry` to be a *real* LDR_DATA_TABLE_ENTRY in memory
// (if you don’t forge PEB lists, don’t call this).
pub fn LdrpInsertHashTableEntry(entry: *LDR_DATA_TABLE_ENTRY_FULL) void {
    log.info("Inside LdrInsertHashtableEntry\n", .{});
    const table0 = findLdrpHashTableBase() orelse return;

    log.info("1\n", .{});
    // Compute target bucket
    // const h = ldrHashUnicodeStringX65599CaseI(entry.BaseDllName);
    const h = LdrpHashUnicodeString(&entry.BaseDllName);

    log.info("2\n", .{});
    const idx = ldrBucketIndex(h);

    log.info("3\n", .{});
    const head: *win.LIST_ENTRY = &table0[idx];

    // HashLinks must at least be self-initialised before linking.
    if (@as(?*win.LIST_ENTRY, @ptrCast(entry.HashLinks.Flink)) == null or
        @as(?*win.LIST_ENTRY, @ptrCast(entry.HashLinks.Blink)) == null or
        entry.HashLinks.Flink == &entry.HashLinks and entry.HashLinks.Blink == &entry.HashLinks)
    {
        entry.HashLinks.Flink = &entry.HashLinks;
        entry.HashLinks.Blink = &entry.HashLinks;
    }

    log.info("4\n", .{});
    // The hash table array lives in ntdll's .data; make it writable if needed.
    var oldProt: u32 = 0;
    const ok = VirtualProtect(@ptrCast(table0), 32 * @sizeOf(win.LIST_ENTRY), winc.PAGE_READWRITE, &oldProt);

    log.info("4.5\n", .{});
    if (ok != 0) {
        insertTailList(head, &entry.HashLinks);

        log.info("4.7\n", .{});
        var tmp: u32 = 0;
        _ = VirtualProtect(@ptrCast(table0), 32 * @sizeOf(win.LIST_ENTRY), oldProt, &tmp);
    } else {
        log.info("4.8\n", .{});
        // best-effort: try without changing protection
        insertTailList(head, &entry.HashLinks);
    }

    log.info("5\n", .{});
}
