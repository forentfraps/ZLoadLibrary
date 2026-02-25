const std = @import("std");
const winz = std.os.windows;
const clr = @import("clr.zig");
const sneaky_memory = @import("memory.zig");
const logger = @import("sys_logger");
const win = @import("zigwin32").everything;
const apiset = @import("apiset.zig");
const sigscan = @import("sigscan.zig");
const static_tls = @import("static_tls.zig");
const seh_fix = @import("seh_fix.zig");

pub const types = @import("win_types.zig");
pub const str = @import("u16str.zig");
pub const ldr = @import("ldr_utils.zig");

// Re-export commonly used items so callers can still do `dll.OwnedZ16` etc.
pub const OwnedZ16 = str.OwnedZ16;
pub const DllError = types.DllError;
pub const UNICODE_STRING = types.UNICODE_STRING;
pub const LDR_DATA_TABLE_ENTRY = types.LDR_DATA_TABLE_ENTRY;
pub const PEB = types.PEB;
pub const IMAGE_DELAYLOAD_DESCRIPTOR = types.IMAGE_DELAYLOAD_DESCRIPTOR;

const W = std.unicode.utf8ToUtf16LeStringLiteral;

const MEM_RESERVE = types.MEM_RESERVE;
const MEM_COMMIT = types.MEM_COMMIT;
const PAGE_EXECUTE_READWRITE = types.PAGE_EXECUTE_READWRITE;
const GENERIC_READ = types.GENERIC_READ;
const OPEN_EXISTING = types.OPEN_EXISTING;
const GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS = types.GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS;

const toUpperOwned = str.toUpperOwned;
const toUpperTemp = str.toUpperTemp;
const looksLikeForwarderString = str.looksLikeForwarderString;
const isOrdinalLookup64 = str.isOrdinalLookup64;
const ordinalOf64 = str.ordinalOf64;

const U16Set = std.HashMap([]const u16, void, str.U16KeyCtx, 80);
pub const u16HashMapType = std.HashMap([]u16, *Dll, str.MappingContext, 80);

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
pub fn init_logger_zload() void {
    log = logger.SysLogger.init(colour_list.len, pref_list, colour_list);
    log.enabled = true;
}

// ===== Dll record =====

pub const Dll = struct {
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
        var buf: [260]u8 = undefined;
        const up = toUpperTemp(&buf, name);
        const p = self.NameExports.get(up) orelse return DllError.FuncResolutionFailed;
        return @ptrCast(@alignCast(p));
    }
};

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
    pub fn shortKey(self: *const DllPath) []u16 {
        const raw = self.short.raw;
        return @constCast(raw[0..raw.len]);
    }
    pub fn normalize(self: *DllPath) void {
        self.short.toUpperAsciiInPlace();
    }
    pub fn deinit(self: *DllPath) void {
        var f = self.full;
        f.deinit();
        var s = self.short;
        s.deinit();
    }
};

// ===== Globals =====

pub var GLOBAL_DLL_LOADER: DllLoader = undefined;
pub var GLOBAL_DLL_INIT: bool = false;

// ===== Hook stubs =====

pub fn GetProcAddress(hModule: [*]u8, procname: [*:0]const u8) callconv(.winapi) ?*anyopaque {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();

    const self = &GLOBAL_DLL_LOADER;
    const name_slice = procname[0..std.mem.len(procname)];

    var it = self.LoadedDlls.keyIterator();
    while (it.next()) |key| {
        const d = self.LoadedDlls.get(key.*).?;
        if (d.BaseAddr == hModule) {
            var buf: [256]u8 = undefined;
            const up = toUpperTemp(&buf, name_slice);

            // Diagnostic: trace safe-loading function lookups
            if (std.mem.eql(u8, up, "SETDEFAULTDLLDIRECTORIES") or
                std.mem.eql(u8, up, "ADDDLLDIRECTORY"))
            {
                const result = d.NameExports.get(up);
                log.crit("SafeLoad GPA '{s}' in ", .{up});
                log.crit16("-> ", .{}, d.Path.short.z);
                log.crit("result: {?*}\n", .{result});
                // Also print what the raw value is — forwarder string or real ptr
                if (result) |r| {
                    const rb: [*]const u8 = @ptrCast(r);
                    if (str.looksLikeForwarderString(rb)) {
                        log.crit("  ^ IS STILL A FORWARDER STRING: {s}\n", .{rb[0..32]});
                    }
                } else {
                    log.crit("  ^ KEY NOT FOUND IN MAP\n", .{});
                    // Dump all keys containing "DEFAULT" for cross-check
                    var kit = d.NameExports.keyIterator();
                    while (kit.next()) |k| {
                        if (std.mem.indexOf(u8, k.*, "DEFAULT") != null)
                            log.crit("  map has: {s}\n", .{k.*});
                    }
                }
                return result;
            }

            return d.NameExports.get(up);
        }
    }

    log.crit("GPA: hModule {*} not found in LoadedDlls for '{s}'\n", .{ hModule, name_slice });
    return null;
}

pub fn GetModuleHandleA(moduleName_: ?[*:0]const u8) callconv(.winapi) ?[*]u8 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    const self = &GLOBAL_DLL_LOADER;
    if (moduleName_) |moduleName| {
        var owned = OwnedZ16.fromU8z(self.Allocator, moduleName) catch return null;
        log.info("GMHA {s}\n", .{moduleName});
        defer owned.deinit();
        return GetModuleHandleW(owned.view());
    } else {
        if (self.HostExeBase) |exe_base| return exe_base;
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
        const self = &GLOBAL_DLL_LOADER;
        var owned = OwnedZ16.fromU16(self.Allocator, moduleName16[0..len]) catch return null;
        owned.canonicalUpperDll() catch return null;
        log.info16("GMHW ", .{}, owned.raw);
        defer owned.deinit();
        var dllPath = (self.getDllPaths(owned.view()) catch return null) orelse return null;
        defer {
            dllPath.deinit();
            self.Allocator.destroy(dllPath);
        }
        log.info16("Resolved DLLpath ", .{}, dllPath.short.z);
        dllPath.normalize();
        if (self.LoadedDlls.contains(@constCast(dllPath.shortKey()))) {
            return self.LoadedDlls.get(@constCast(dllPath.shortKey())).?.BaseAddr;
        }
        return null;
    } else {
        const self = &GLOBAL_DLL_LOADER;
        if (self.HostExeBase) |exe_base| return exe_base;
        // Fallback to loader's own base
        const peb: usize = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> usize),
            :
            : .{ .memory = true });
        const addr: *[*]u8 = @ptrFromInt(peb + 0x10);
        return addr.*;
    }
}

pub fn LoadLibraryA_stub(libname: [*:0]const u8) callconv(.winapi) ?[*]u8 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    log.info("LLA {s}\n", .{libname});
    const self = &GLOBAL_DLL_LOADER;
    var name16 = OwnedZ16.fromU8z(self.Allocator, libname) catch return null;
    defer name16.deinit();
    return LoadLibraryW_stub(@ptrCast(name16.viewMut().ptr));
}

pub fn LoadLibraryW_stub(libname16: [*:0]u16) callconv(.winapi) ?[*]u8 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    log.info16("LLW\n", .{}, @ptrCast(libname16[0..std.mem.len(libname16)]));
    const d = (&GLOBAL_DLL_LOADER).ZLoadLibrary(@ptrCast(libname16[0..std.mem.len(libname16)])) catch return null;
    if (d) |dll| return dll.BaseAddr;
    return null;
}

pub fn LoadLibraryExA_stub(libname: [*:0]const u8, file: ?*anyopaque, flags: u32) callconv(.winapi) ?[*]u8 {
    _ = file;
    _ = flags;
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    log.info("LLEA {s}\n", .{libname});
    const self = &GLOBAL_DLL_LOADER;
    var name16 = OwnedZ16.fromU8z(self.Allocator, libname) catch return null;
    defer name16.deinit();
    return LoadLibraryExW_stub(@ptrCast(name16.viewMut().ptr), null, 0);
}

pub fn LoadLibraryExW_stub(libname16: [*:0]u16, file: ?*anyopaque, flags: u32) callconv(.winapi) ?[*]u8 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    log.info16("LLEW ", .{}, @ptrCast(libname16[0..std.mem.len(libname16)]));
    if (file) |file_deref| log.info("File ptr: {*}\n", .{file_deref});
    log.info("Flags : {x}\n", .{flags});
    const self = &GLOBAL_DLL_LOADER;
    const key: []u16 = libname16[0..std.mem.len(libname16)];
    if (self.LoadedDlls.contains(key)) return self.LoadedDlls.get(key).?.BaseAddr;
    const result = self.ZLoadLibrary(@ptrCast(libname16[0..std.mem.len(libname16)])) catch return null;
    if (result) |d| return d.BaseAddr;
    return null;
}

pub fn ResolveDelayLoadedAPI_stub(
    parent_base: [*]u8,
    descriptor: *const IMAGE_DELAYLOAD_DESCRIPTOR,
    failure_dll_hook: ?*anyopaque,
    failure_hook: ?*anyopaque,
    thunk: *win.IMAGE_THUNK_DATA64,
    flags: u32,
) callconv(.winapi) ?*anyopaque {
    _ = failure_dll_hook;
    _ = failure_hook;
    _ = flags;
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    const self = &GLOBAL_DLL_LOADER;
    const lib_u8z: [*:0]const u8 = @ptrCast(parent_base[descriptor.DllNameRVA..]);
    var owned = OwnedZ16.fromU8z(self.Allocator, lib_u8z) catch return null;
    defer owned.deinit();
    if (apiset.ApiSetResolve(owned.view(), &.{})) |host_z| {
        const host_sz: [:0]u16 = @ptrCast(host_z);
        owned.replaceWithZ16(host_sz) catch return null;
    }
    owned.canonicalUpperDll() catch return null;
    const library = (self.ZLoadLibrary(owned.view()) catch return null) orelse return null;
    var addr: ?*anyopaque = null;
    const orig_thunk_va = descriptor.ImportNameTableRVA;
    if (orig_thunk_va != 0) {
        var int_ptr: *win.IMAGE_THUNK_DATA64 = @ptrCast(@alignCast(parent_base[orig_thunk_va..]));
        var iat_ptr: *win.IMAGE_THUNK_DATA64 = @ptrCast(@alignCast(parent_base[descriptor.ImportAddressTableRVA..]));
        var tmpname: [256]u8 = undefined;
        while (int_ptr.u1.AddressOfData != 0) : ({
            int_ptr = @ptrFromInt(@intFromPtr(int_ptr) + @sizeOf(win.IMAGE_THUNK_DATA64));
            iat_ptr = @ptrFromInt(@intFromPtr(iat_ptr) + @sizeOf(win.IMAGE_THUNK_DATA64));
        }) {
            if (@intFromPtr(iat_ptr) != @intFromPtr(thunk)) continue;
            if (isOrdinalLookup64(int_ptr.u1.AddressOfData)) {
                const ord = ordinalOf64(int_ptr.u1.AddressOfData);
                addr = library.ResolveByOrdinal(ord);
            } else {
                const ibn: *const win.IMAGE_IMPORT_BY_NAME =
                    @ptrCast(@alignCast(parent_base[int_ptr.u1.AddressOfData..]));
                const name_z: [*:0]const u8 = @ptrCast(&ibn.Name);
                const up = toUpperTemp(&tmpname, name_z[0..std.mem.len(name_z)]);
                addr = library.ResolveByName(up);
            }
            if (addr) |a| thunk.u1.Function = @intFromPtr(a);
            break;
        }
    }
    return addr;
}

pub fn GetModuleFileNameW_stub(
    hModule: ?[*]u8,
    lpFilename: [*]u16,
    nSize: u32,
) callconv(.winapi) u32 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    const self = &GLOBAL_DLL_LOADER;
    if (hModule) |base| {
        var it = self.LoadedDlls.valueIterator();
        while (it.next()) |dll_ptr| {
            const d = dll_ptr.*;
            if (d.BaseAddr == base) {
                const full = d.Path.full.z;
                const copy_len = @min(full.len, @as(usize, nSize) - 1);
                @memcpy(lpFilename[0..copy_len], full[0..copy_len]);
                lpFilename[copy_len] = 0;
                return @intCast(copy_len);
            }
        }
    } else {
        var it = self.LoadedDlls.valueIterator();
        while (it.next()) |dll_ptr| {
            const d = dll_ptr.*;
            const full = d.Path.full.z;
            if (full.len < 4) continue;
            const ext = full[full.len - 4 ..];
            if ((ext[0] == '.') and
                (ext[1] | 0x20) == 'e' and
                (ext[2] | 0x20) == 'x' and
                (ext[3] | 0x20) == 'e')
            {
                const copy_len = @min(full.len, @as(usize, nSize) - 1);
                @memcpy(lpFilename[0..copy_len], full[0..copy_len]);
                lpFilename[copy_len] = 0;
                return @intCast(copy_len);
            }
        }
    }
    return 0;
}

pub fn GetModuleHandleExW_stub(
    dwFlags: u32,
    lpModuleName: ?*anyopaque,
    phModule: *?[*]u8,
) callconv(.winapi) i32 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    const self = &GLOBAL_DLL_LOADER;
    if (dwFlags & GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS != 0) {
        const addr = @intFromPtr(lpModuleName);
        var it = self.LoadedDlls.valueIterator();
        while (it.next()) |dll_ptr| {
            const d = dll_ptr.*;
            const base = @intFromPtr(d.BaseAddr);
            const nt = DllLoader.ResolveNtHeaders(d.BaseAddr) catch continue;
            const size = nt.OptionalHeader.SizeOfImage;
            if (addr >= base and addr < base + size) {
                phModule.* = d.BaseAddr;
                return 1;
            }
        }
        phModule.* = null;
        return 0;
    }
    const name16: ?[*:0]u16 = @ptrCast(@alignCast(lpModuleName));
    phModule.* = GetModuleHandleW(name16);
    return if (phModule.* != null) 1 else 0;
}

pub fn GetModuleHandleExA_stub(
    dwFlags: u32,
    lpModuleName: ?*anyopaque,
    phModule: *?[*]u8,
) callconv(.winapi) i32 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    if (dwFlags & GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS != 0) {
        return GetModuleHandleExW_stub(dwFlags, lpModuleName, phModule);
    }
    const self = &GLOBAL_DLL_LOADER;
    const name_a: [*:0]const u8 = @ptrCast(lpModuleName orelse {
        phModule.* = GetModuleHandleA(null);
        return if (phModule.* != null) 1 else 0;
    });
    var name16 = OwnedZ16.fromU8z(self.Allocator, name_a) catch return 0;
    defer name16.deinit();
    phModule.* = GetModuleHandleW(@ptrCast(name16.viewMut().ptr));
    return if (phModule.* != null) 1 else 0;
}

// ===== DllLoader =====

pub const DllLoader = struct {
    LoadedDlls: u16HashMapType = undefined,
    Allocator: std.mem.Allocator,
    HeapAllocator: sneaky_memory.HeapAllocator = undefined,
    InFlight: U16Set = undefined,
    WinVer: sigscan.WinVer = undefined,
    HostExeBase: ?[*]u8 = null,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !void {
        if (GLOBAL_DLL_INIT == false) {
            GLOBAL_DLL_LOADER = Self{
                .LoadedDlls = undefined,
                .Allocator = allocator,
                .InFlight = U16Set.init(allocator),
            };
            init_logger_zload();
            const loader = &GLOBAL_DLL_LOADER;
            try loader.getLoadedDlls();
            const kb = try loader.getDllByName("kernelbase.dll");
            try loader.ResolveImportInconsistencies(kb);
            const k32 = try loader.getDllByName("kernel32.dll");
            try loader.ResolveImportInconsistencies(k32);
            try loader.resolveKnownForwarders();
            GLOBAL_DLL_LOADER.WinVer = try sigscan.getWinVer(loader);
            GLOBAL_DLL_INIT = true;
        }
    }
    pub fn deinit() void {
        const self = &GLOBAL_DLL_LOADER;
        const ntdll = self.getDllByName("ntdll.dll") catch null;
        const NtFreeVirtualMemory: ?*const fn (i64, *?[*]u8, *usize, u32) callconv(.winapi) c_int = blk: {
            if (ntdll) |n| {
                break :blk n.getProc(
                    fn (i64, *?[*]u8, *usize, u32) callconv(.winapi) c_int,
                    "NtFreeVirtualMemory",
                ) catch null;
            }
            break :blk null;
        };

        const MEM_RELEASE: u32 = 0x8000;

        // Collect which bases came from the PEB so we don't free them
        var peb_bases = std.AutoHashMap(usize, void).init(self.Allocator);
        defer peb_bases.deinit();
        {
            const peb: *types.PEB = asm volatile ("mov %gs:0x60, %rax"
                : [peb] "={rax}" (-> *types.PEB),
                :
                : .{ .memory = true });
            const head: *win.LIST_ENTRY = &peb.Ldr.InMemoryOrderModuleList;
            var curr: *win.LIST_ENTRY = head.Flink.?;
            while (curr != head) : (curr = curr.Flink.?) {
                const entry: *LDR_DATA_TABLE_ENTRY = @fieldParentPtr("InMemoryOrderLinks", curr);
                if (entry.DllBase) |b| {
                    peb_bases.put(@intFromPtr(b), {}) catch {};
                }
            }
        }

        var it = self.LoadedDlls.valueIterator();
        while (it.next()) |dll_ptr| {
            const d = dll_ptr.*;

            // Free NameExports — keys were heap-allocated by toUpperOwned
            // log.info16("Freeing dll: ", .{}, d.Path.short.z);
            var key_it = d.NameExports.keyIterator();
            while (key_it.next()) |k| self.Allocator.free(k.*);
            d.NameExports.deinit();

            // OrdinalExports — no owned keys
            d.OrdinalExports.deinit();

            // Path
            d.Path.deinit();
            self.Allocator.destroy(d.Path);

            // Mapped memory — only free if we reflectively loaded it
            const base_addr = @intFromPtr(d.BaseAddr);
            if (!peb_bases.contains(base_addr)) {
                if (NtFreeVirtualMemory) |free_fn| {
                    var base: ?[*]u8 = d.BaseAddr;
                    var region_size: usize = 0;
                    _ = free_fn(-1, &base, &region_size, MEM_RELEASE);
                }
            }
            self.Allocator.destroy(d);
        }

        self.LoadedDlls.deinit();
        self.InFlight.deinit();

        GLOBAL_DLL_INIT = false;
    }

    pub fn getDllByName(self: *DllLoader, name: []const u8) !*Dll {
        var up = try OwnedZ16.fromAsciiUpper(self.Allocator, name);
        defer up.deinit();
        try up.canonicalUpperDll();
        if (self.LoadedDlls.get(up.raw)) |dll| return dll;
        return DllError.LoadFailed;
    }

    pub fn getLoadedDlls(self: *Self) !void {
        const peb: *types.PEB = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> *types.PEB),
            :
            : .{ .memory = true });
        const ldr_data: *types.PEB_LDR_DATA = peb.Ldr;
        const head: *win.LIST_ENTRY = ldr_data.InLoadOrderModuleList.Flink.?;
        var curr: *win.LIST_ENTRY = head.Flink.?;

        self.LoadedDlls = u16HashMapType.init(self.Allocator);

        while (true) : (curr = curr.Flink.?) {
            const entry: *LDR_DATA_TABLE_ENTRY = @fieldParentPtr("InLoadOrderLinks", curr);
            const base_name: UNICODE_STRING = entry.BaseDllName;

            if (base_name.Buffer != null and (base_name.Length / 2) <= 260) {
                var dll_rec: *Dll = try self.Allocator.create(Dll);
                dll_rec.BaseAddr = @ptrCast(entry.DllBase);

                const full_len: usize = entry.fullDllName.Length / 2 + 1;
                const base_len: usize = entry.BaseDllName.Length / 2 + 1;
                const full_src: []const u16 = entry.fullDllName.Buffer.?[0..full_len];
                const base_src: []const u16 = entry.BaseDllName.Buffer.?[0..base_len];

                var full_owned = try OwnedZ16.fromU16(self.Allocator, full_src);
                errdefer full_owned.deinit();
                var short_owned = try OwnedZ16.fromU16(self.Allocator, base_src);
                errdefer short_owned.deinit();
                if (!short_owned.endsWithDll()) {
                    full_owned.deinit();
                    short_owned.deinit();
                    self.Allocator.destroy(dll_rec);

                    if (curr == head) break;
                    continue;
                }

                dll_rec.Path = try self.Allocator.create(DllPath);
                dll_rec.Path.* = .{ .full = full_owned, .short = short_owned };
                dll_rec.Path.normalize();
                log.info16("GetLoadedDlls ", .{}, dll_rec.Path.short.z);

                try self.ResolveExports(dll_rec);
                try self.LoadedDlls.put(dll_rec.Path.shortKey(), dll_rec);
            }
            if (curr == head) break;
        }
    }

    pub fn ResolveExports(self: *Self, dll_rec: *Dll) !void {
        // All allocations here are permanent
        log.setContext(logtags.ExpTable);
        defer log.rollbackContext();

        const bytes = dll_rec.BaseAddr;
        const dos: *win.IMAGE_DOS_HEADER = @ptrCast(@alignCast(bytes));
        const nt: *const win.IMAGE_NT_HEADERS64 = @ptrCast(@alignCast(bytes[@intCast(dos.e_lfanew)..]));
        const dir: win.IMAGE_DATA_DIRECTORY = nt.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_EXPORT)];
        dll_rec.NameExports = std.StringHashMap(*anyopaque).init(self.Allocator);
        dll_rec.OrdinalExports = std.AutoHashMap(u16, *anyopaque).init(self.Allocator);
        if (dir.Size == 0) return;

        const exp: *const win.IMAGE_EXPORT_DIRECTORY = @ptrCast(@alignCast(bytes[dir.VirtualAddress..]));
        dll_rec.ExportBase = exp.Base;
        dll_rec.NumberOfFunctions = exp.NumberOfFunctions;

        const eat: [*]align(4) u32 = @ptrCast(@alignCast(bytes[exp.AddressOfFunctions..]));
        const enpt: [*]align(4) u32 = @ptrCast(@alignCast(bytes[exp.AddressOfNames..]));
        const enot: [*]align(4) u16 = @ptrCast(@alignCast(bytes[exp.AddressOfNameOrdinals..]));

        var i: u32 = 0;
        while (i < exp.NumberOfFunctions) : (i += 1) {
            const rva = eat[i];
            if (rva == 0) continue;
            const fptr: *anyopaque = @ptrCast(bytes[@as(usize, @intCast(rva))..]);
            const real_ordinal: u16 = @intCast(exp.Base + i);
            try dll_rec.OrdinalExports.put(real_ordinal, fptr);
        }

        var j: u32 = 0;
        while (j < exp.NumberOfNames) : (j += 1) {
            const name_rva = enpt[j];
            const idx = enot[j];
            const fptr: *anyopaque = @ptrCast(bytes[@as(usize, @intCast(eat[idx]))..]);
            const fname_z: [*:0]u8 = @ptrCast(bytes[@as(usize, @intCast(name_rva))..]);
            const fname = fname_z[0..std.mem.len(fname_z)];
            const up = try toUpperOwned(self.Allocator, fname);
            errdefer self.Allocator.free(up);
            const g = try dll_rec.NameExports.getOrPut(up);
            if (g.found_existing) self.Allocator.free(up);
            g.value_ptr.* = fptr;
        }
    }

    fn resolveForwarder(self: *DllLoader, fwd: []const u8, targetPath: *const DllPath) !*anyopaque {
        const dot = std.mem.indexOfScalar(u8, fwd, '.') orelse return DllError.ForwarderParse;
        const mod = fwd[0..dot];
        const sym = fwd[dot + 1 ..];

        var modbuf: [128]u8 = undefined;
        const upmod = toUpperTemp(&modbuf, mod);
        const needs_ext = !(upmod.len >= 4 and std.mem.eql(u8, upmod[upmod.len - 4 ..], ".DLL"));
        const final_mod: []const u8 = if (needs_ext)
            try std.fmt.allocPrint(self.Allocator, "{s}.dll", .{mod})
        else
            try self.Allocator.dupe(u8, mod);
        defer self.Allocator.free(final_mod);

        var mod16 = try OwnedZ16.fromU8(self.Allocator, final_mod);
        defer mod16.deinit();
        try mod16.canonicalUpperDll();
        const bl = [_][]const u16{targetPath.short.z};
        if (apiset.ApiSetResolve(mod16.view(), &bl)) |host_z| {
            const host_sz: [:0]u16 = @ptrCast(host_z);
            try mod16.replaceWithZ16(host_sz);
            try mod16.canonicalUpperDll();
        } else {
            try mod16.canonicalUpperDll();
        }

        const dep: *Dll = (try self.ZLoadLibrary(mod16.view())) orelse return DllError.LoadFailed;

        if (sym.len > 0 and sym[0] == '#') {
            const ord = try std.fmt.parseInt(u16, sym[1..], 10);
            return dep.ResolveByOrdinal(ord) orelse error.FuncResolutionByOrdinalFailed;
        } else {
            var buf: [256]u8 = undefined;
            const up = toUpperTemp(&buf, sym);
            return dep.ResolveByName(up) orelse {
                log.crit("FUNCTION THAT FAILED TO RESOLVE: {s} FWD -> {s}\n", .{ up, fwd });
                log.crit16("Master dll: ", .{}, targetPath.short.z);
                return error.FuncResolutionByNameFailed;
            };
        }
    }

    pub fn resolveExportForwarders(self: *Self, dll_rec: *Dll) !void {
        log.setContext(logtags.ExpTable);
        defer log.rollbackContext();

        var name_it = dll_rec.NameExports.iterator();
        while (name_it.next()) |entry| {
            const ptr: [*]const u8 = @ptrCast(entry.value_ptr.*);
            if (!looksLikeForwarderString(ptr)) continue;
            const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(ptr)), 0);
            const resolved = self.resolveForwarder(fwd_slice, dll_rec.Path) catch |err| {
                log.crit("  failed: {}\n", .{err});
                continue;
            };
            entry.value_ptr.* = resolved;
        }

        var ord_it = dll_rec.OrdinalExports.iterator();
        while (ord_it.next()) |entry| {
            const ptr: [*]const u8 = @ptrCast(entry.value_ptr.*);
            if (!looksLikeForwarderString(ptr)) continue;
            const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(ptr)), 0);
            const resolved = self.resolveForwarder(fwd_slice, dll_rec.Path) catch |err| {
                log.crit("  failed: {}\n", .{err});
                continue;
            };
            entry.value_ptr.* = resolved;
        }
    }

    pub fn resolveKnownForwarders(self: *Self) !void {
        const targets = [_][]const u8{ "KERNEL32.DLL", "KERNELBASE.DLL" };
        for (targets) |name| {
            const dll_rec = self.getDllByName(name) catch {
                asm volatile ("int3");
                continue;
            };
            try self.resolveExportForwarders(dll_rec);
        }
    }

    pub fn getDllPaths(self: *Self, libname16_: [:0]const u16) !?*DllPath {
        log.setContext(logtags.PathRes);
        defer log.rollbackContext();

        const kernel32 = (try self.getDllByName("kernel32.dll"));
        const GetFileAttributesW = try kernel32.getProc(fn ([*:0]u16) callconv(.winapi) c_int, "GetFileAttributesW");
        const GetEnvironmentVariableW = try kernel32.getProc(fn ([*]const u16, [*:0]u16, c_uint) callconv(.winapi) c_uint, "GetEnvironmentVariableW");
        const GetSystemDirectoryW = try kernel32.getProc(fn ([*]u16, usize) callconv(.winapi) c_int, "GetSystemDirectoryW");
        const GetLastError = try kernel32.getProc(fn () callconv(.winapi) c_int, "GetLastError");
        const SetLastError = try kernel32.getProc(fn (c_int) callconv(.winapi) void, "SetLastError");

        const lastSlash = struct {
            fn find(z: [:0]const u16) ?usize {
                var i: isize = @intCast(z.len);
                i = i - 2;
                while (i >= 0) : (i -= 1) {
                    const c = z[@intCast(i)];
                    if (c == '\\' or c == '/') return @intCast(i);
                }
                return null;
            }
        }.find;

        const makePath = struct {
            fn build(alloc: std.mem.Allocator, full_z: [:0]const u16) !*DllPath {
                var full_owned = try OwnedZ16.fromU16(alloc, full_z[0..full_z.len]);
                errdefer full_owned.deinit();
                const cut = lastSlash(full_z);
                const base_z: [:0]const u16 = if (cut) |p|
                    @ptrCast(full_z[p + 1 .. full_z.len :0])
                else
                    full_z;
                var short_owned = try OwnedZ16.fromU16(alloc, base_z[0..base_z.len]);
                errdefer short_owned.deinit();
                var dp = try alloc.create(DllPath);
                dp.* = .{ .full = full_owned, .short = short_owned };
                dp.normalize();
                return dp;
            }
        }.build;

        const is_path = blk: {
            var has_slash = false;
            var i: usize = 0;
            while (i + 1 < libname16_.len) : (i += 1) {
                const c = libname16_[i];
                if (c == '\\' or c == '/') {
                    has_slash = true;
                    break;
                }
            }
            const drive_path =
                libname16_.len >= 3 and
                ((libname16_[0] >= 'A' and libname16_[0] <= 'Z') or
                    (libname16_[0] >= 'a' and libname16_[0] <= 'z')) and
                libname16_[1] == ':' and
                (libname16_[2] == '\\' or libname16_[2] == '/');
            const unc_path =
                libname16_.len >= 3 and
                libname16_[0] == '\\' and libname16_[1] == '\\';
            break :blk (has_slash or drive_path or unc_path);
        };

        if (is_path) return try makePath(self.Allocator, libname16_);

        // Build search path: %PATH% + ".\" + system32 + EXE directory
        var PATH: [33000:0]u16 = undefined;
        const PATH_s = W("PATH");
        var len: usize = GetEnvironmentVariableW(PATH_s.ptr, &PATH, 32767);

        // ".\"
        PATH[len] = @intCast('.');
        PATH[len + 1] = @intCast('\\');
        PATH[len + 2] = @intCast(';');
        len += 3;

        // System directory — fix 1: proper buffer size, fix 2: terminate with ';'
        const syslen: usize = @intCast(GetSystemDirectoryW(PATH[len..].ptr, @intCast(33000 - len - 4)));
        PATH[len + syslen] = @intCast(';');
        PATH[len + syslen + 1] = 0;
        len += syslen + 1;

        // EXE directory — so DLLs sitting next to the loaded EXE are found
        if (self.HostExeBase != null) {
            var it = self.LoadedDlls.valueIterator();
            while (it.next()) |dll_ptr| {
                const d = dll_ptr.*;
                const full = d.Path.full.z;
                if (full.len < 4) continue;
                const ext = full[full.len - 4 ..];
                const is_exe =
                    (ext[0] == '.') and
                    (ext[1] | 0x20) == 'e' and
                    (ext[2] | 0x20) == 'x' and
                    (ext[3] | 0x20) == 'e';
                if (!is_exe) continue;

                // Strip filename to get directory
                var sep: usize = 0;
                var si: usize = 0;
                while (si < full.len) : (si += 1) {
                    if (full[si] == '\\' or full[si] == '/') sep = si;
                }
                if (sep == 0) continue;
                const dir = full[0..sep]; // excludes trailing slash

                if (len + dir.len + 2 < 33000) {
                    std.mem.copyForwards(u16, PATH[len..][0..dir.len], dir);
                    PATH[len + dir.len] = @intCast(';');
                    PATH[len + dir.len + 1] = 0;
                    len += dir.len + 1;
                }
                break;
            }
        }

        // Walk the search path
        var i: usize = 0;
        var start_pointer: usize = 0;
        while (PATH[i] != 0) : (i += 1) {
            if ((PATH[i] & 0xff00 == 0) and @as(u8, @intCast(PATH[i])) == ';') {
                const end_pointer = i;
                if (end_pointer == start_pointer) {
                    // empty segment (double semicolon), skip
                    start_pointer = end_pointer + 1;
                    continue;
                }

                // Compose "<dir>\<libname>\0"
                const dir_len = end_pointer - start_pointer;
                const tmp_len = dir_len + 1 + libname16_.len; // dir + '\' + name+sentinel
                const tmp_alloc = try self.Allocator.alloc(u16, tmp_len);
                defer self.Allocator.free(tmp_alloc);
                var tmp_z: [:0]u16 = @ptrCast(tmp_alloc);

                std.mem.copyForwards(u16, tmp_z[0..dir_len], PATH[start_pointer..end_pointer]);
                tmp_z[dir_len] = @intCast('\\');
                std.mem.copyForwards(u16, tmp_z[dir_len + 1 .. tmp_len], libname16_);

                SetLastError(0);
                _ = GetFileAttributesW(tmp_z.ptr);
                const err: c_int = GetLastError();
                if (err == 0) {
                    // log.info16("Found ", .{}, tmp_z);
                    return try makePath(self.Allocator, tmp_z);
                }

                start_pointer = end_pointer + 1;
            }
        }

        log.crit16(" Did not find an entry  -> ", .{}, libname16_);
        return null;
    }

    pub fn LoadDllInMemory(self: *Self, dllPath: *DllPath, dllSize: *usize) !?[*]u8 {
        const kernel32 = (try self.getDllByName("kernel32.dll"));
        const CreateFileW = try kernel32.getProc(fn ([*:0]const u16, u32, u32, ?*win.SECURITY_ATTRIBUTES, u32, u32, ?*anyopaque) callconv(.winapi) *anyopaque, "CreateFileW");
        const CloseHandle = try kernel32.getProc(fn (*anyopaque) callconv(.winapi) c_int, "CloseHandle");
        const GetFileSizeEx = try kernel32.getProc(fn (*anyopaque, *i64) callconv(.winapi) c_int, "GetFileSizeEx");
        const ReadFile = try kernel32.getProc(fn (*anyopaque, [*]u8, u32, ?*u32, ?*win.OVERLAPPED) callconv(.winapi) c_int, "ReadFile");

        const dll_handle = CreateFileW(dllPath.fullView(), GENERIC_READ, 0, null, OPEN_EXISTING, 0, null);
        defer _ = CloseHandle(dll_handle);

        var dll_size_i: i64 = 0;
        if ((GetFileSizeEx(dll_handle, &dll_size_i) <= 0)) return DllError.Size;
        dllSize.* = @intCast(dll_size_i);

        const dll_bytes: [*]u8 = (try self.Allocator.alloc(u8, dllSize.*)).ptr;
        var bytes_read: u32 = 0;
        _ = ReadFile(dll_handle, dll_bytes, @as(u32, @intCast(dllSize.*)), &bytes_read, null);
        return dll_bytes;
    }

    pub fn ResolveNtHeaders(dll_bytes: [*]u8) !*const win.IMAGE_NT_HEADERS64 {
        const dos_headers: *win.IMAGE_DOS_HEADER = @ptrCast(@alignCast(dll_bytes));
        const nt_headers: *const win.IMAGE_NT_HEADERS64 =
            @ptrCast(@alignCast(dll_bytes[@intCast(dos_headers.e_lfanew)..]));
        if (nt_headers.Signature != 0x4550) return error.InvalidPESignature;
        return nt_headers;
    }

    pub fn MapSections(self: *Self, nt_headers: *const win.IMAGE_NT_HEADERS64, dll_bytes: [*]u8, delta_image_base: *usize) ![*]u8 {
        const ntdll_dll = (try self.getDllByName("ntdll.dll"));
        const ZwAllocateVirtualMemory = try ntdll_dll.getProc(fn (i64, *?[*]u8, usize, *usize, u32, u32) callconv(.winapi) c_int, "ZwAllocateVirtualMemory");

        var dll_base_dirty: ?[*]u8 = null;
        var virtAllocSize: usize = nt_headers.OptionalHeader.SizeOfImage;

        var status: c_int = ZwAllocateVirtualMemory(-1, &dll_base_dirty, 0, &virtAllocSize, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE);
        if (status < 0) {
            dll_base_dirty = null;
            status = ZwAllocateVirtualMemory(-1, &dll_base_dirty, 0, &virtAllocSize, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE);
            if (status < 0 or dll_base_dirty == null) return DllError.VirtualAllocNull;
        }
        const dll_base = dll_base_dirty.?;
        delta_image_base.* = @intFromPtr(dll_base) - nt_headers.OptionalHeader.ImageBase;

        std.mem.copyForwards(u8, dll_base[0..nt_headers.OptionalHeader.SizeOfHeaders], dll_bytes[0..nt_headers.OptionalHeader.SizeOfHeaders]);

        const section: [*]const win.IMAGE_SECTION_HEADER =
            @ptrFromInt(@intFromPtr(nt_headers) + @sizeOf(win.IMAGE_NT_HEADERS64));
        var i: usize = 0;
        while (i < nt_headers.FileHeader.NumberOfSections) : (i += 1) {
            const dst: [*]u8 = @ptrCast(dll_base[section[i].VirtualAddress..]);
            const src: [*]u8 = @ptrCast(dll_bytes[section[i].PointerToRawData..]);
            std.mem.copyForwards(u8, dst[0..section[i].SizeOfRawData], src[0..section[i].SizeOfRawData]);
        }

        var new_nt = @constCast(try ResolveNtHeaders(dll_base));
        new_nt.OptionalHeader.ImageBase = @intFromPtr(dll_base);
        return dll_base;
    }

    pub fn ResolveRVA(dll_base: [*]u8, nt_headers: *const win.IMAGE_NT_HEADERS64, delta_image_base: usize) !void {
        log.setContext(logtags.RVAres);
        const relocations = nt_headers.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_BASERELOC)];
        const relocation_table: [*]u8 = @ptrCast(@alignCast(dll_base[relocations.VirtualAddress..]));
        var relocations_processed: u32 = 0;

        while (relocations_processed < relocations.Size) {
            const relocation_block: *types.BASE_RELOCATION_BLOCK = @ptrCast(@alignCast(relocation_table[relocations_processed..]));
            relocations_processed += @sizeOf(types.BASE_RELOCATION_BLOCK);
            const relocations_count = (relocation_block.BlockSize - @sizeOf(types.BASE_RELOCATION_BLOCK)) / @sizeOf(types.BASE_RELOCATION_ENTRY);
            const relocation_entries: [*]align(1) types.BASE_RELOCATION_ENTRY = @ptrCast(@alignCast(relocation_table[relocations_processed..]));
            for (0..relocations_count) |entry_index| {
                if (relocation_entries[entry_index].Type != 0) {
                    const relocation_rva: usize = relocation_block.PageAddress + relocation_entries[entry_index].Offset;
                    const ptr: *align(1) usize = @ptrCast(@alignCast(dll_base[relocation_rva..]));
                    ptr.* = ptr.* + delta_image_base;
                }
                relocations_processed += @sizeOf(types.BASE_RELOCATION_ENTRY);
            }
        }
        log.rollbackContext();
    }

    pub fn ResolveImportTable(self: *Self, dll_base: [*]u8, nt_headers: *const win.IMAGE_NT_HEADERS64, dllPath: *DllPath, dll_struct: *Dll) !void {
        log.setContext(logtags.ImpRes);
        defer log.rollbackContext();

        const impdir = nt_headers.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_IMPORT)];
        if (impdir.Size == 0) return;

        var import_descriptor: *const win.IMAGE_IMPORT_DESCRIPTOR =
            @ptrCast(@alignCast(dll_base[impdir.VirtualAddress..]));

        while (import_descriptor.Name != 0) : (import_descriptor =
            @ptrFromInt(@intFromPtr(import_descriptor) + @sizeOf(win.IMAGE_IMPORT_DESCRIPTOR)))
        {
            const lib_u8z: [*:0]const u8 = @ptrCast(dll_base[import_descriptor.Name..]);
            if (std.mem.len(lib_u8z) == 0) break;

            var owned = try OwnedZ16.fromU8z(self.Allocator, lib_u8z);
            defer owned.deinit();

            const bl = [_][]const u16{dllPath.short.z};
            if (apiset.ApiSetResolve(owned.view(), &bl)) |host_z| {
                const host_sz: [:0]u16 = @ptrCast(host_z);
                try owned.replaceWithZ16(host_sz);
                try owned.canonicalUpperDll();
            } else {
                try owned.canonicalUpperDll();
            }
            const libraryNameToLoad16 = owned;

            var library: ?*Dll = undefined;
            if (std.mem.eql(u16, dllPath.shortKey(), libraryNameToLoad16.raw)) {
                library = dll_struct;
            } else {
                // log.info16("Trying to load ", .{}, libraryNameToLoad16.z);
                library = try self.ZLoadLibrary(libraryNameToLoad16.z);
                if (library == null) return error.ImportDllIsNull;

                var orig_thunk_rva: u32 = import_descriptor.Anonymous.OriginalFirstThunk;
                const thunk_rva: u32 = import_descriptor.FirstThunk;
                if (orig_thunk_rva == 0) orig_thunk_rva = import_descriptor.FirstThunk;

                var orig: *win.IMAGE_THUNK_DATA64 = @ptrCast(@alignCast(dll_base[orig_thunk_rva..]));
                var thunk: *win.IMAGE_THUNK_DATA64 = @ptrCast(@alignCast(dll_base[thunk_rva..]));
                var tmpname: [256]u8 = undefined;

                while (orig.u1.AddressOfData != 0) : ({
                    thunk = @ptrFromInt(@intFromPtr(thunk) + @sizeOf(win.IMAGE_THUNK_DATA64));
                    orig = @ptrFromInt(@intFromPtr(orig) + @sizeOf(win.IMAGE_THUNK_DATA64));
                }) {
                    if (isOrdinalLookup64(orig.u1.AddressOfData)) {
                        const ord = ordinalOf64(orig.u1.AddressOfData);
                        var addr = library.?.ResolveByOrdinal(ord) orelse {
                            log.info16("Failed ordinal {x} lookup for library -> ", .{ord}, libraryNameToLoad16.raw);
                            return DllError.FuncResolutionFailed;
                        };
                        const addr_bytes: [*]const u8 = @ptrCast(addr);
                        if (looksLikeForwarderString(addr_bytes)) {
                            const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(addr)), 0);
                            addr = try self.resolveForwarder(fwd_slice, dllPath);
                            log.crit("FWD to resolve {s}\n", .{fwd_slice});
                            log.crit16("FROM MODULE ", .{}, libraryNameToLoad16.raw);
                        }
                        thunk.u1.Function = @intFromPtr(addr);
                    } else {
                        const ibn: *const win.IMAGE_IMPORT_BY_NAME = @ptrCast(@alignCast(dll_base[orig.u1.AddressOfData..]));
                        const name_z: [*:0]const u8 = @ptrCast(&ibn.Name);
                        const up = toUpperTemp(&tmpname, name_z[0..std.mem.len(name_z)]);
                        var addr = library.?.ResolveByName(up) orelse return DllError.FuncResolutionFailed;
                        const addr_bytes: [*]const u8 = @ptrCast(addr);
                        if (looksLikeForwarderString(addr_bytes)) {
                            const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(addr)), 0);
                            log.crit("FWD to resolve {s}\n", .{fwd_slice});
                            log.crit16("FROM MODULE ", .{}, libraryNameToLoad16.raw);
                            addr = try self.resolveForwarder(fwd_slice, dllPath);
                        }
                        thunk.u1.Function = @intFromPtr(addr);
                    }
                }
            }
        }
    }

    pub fn fixDelayImports(self: *@This(), dll_base: [*]u8, nt_headers: *const win.IMAGE_NT_HEADERS64, dllPath: *DllPath, dll_struct: *Dll) !void {
        log.setContext(logtags.ImpRes);
        defer log.rollbackContext();

        const delaydir = nt_headers.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT)];
        if (delaydir.Size == 0) return;

        const ptrFromAttr = struct {
            fn ptrFromAttr(comptime T: type, base: [*]u8, attrs: u32, rva_or_va: u32) *T {
                const addr: usize = if ((attrs & 0x1) != 0)
                    @intFromPtr(base) + rva_or_va
                else
                    @intCast(rva_or_va);
                return @ptrFromInt(addr);
            }
        }.ptrFromAttr;

        var desc: *const IMAGE_DELAYLOAD_DESCRIPTOR = @ptrCast(@alignCast(dll_base[delaydir.VirtualAddress..]));
        while (desc.DllNameRVA != 0) : (desc = @ptrFromInt(@intFromPtr(desc) + @sizeOf(IMAGE_DELAYLOAD_DESCRIPTOR))) {
            const lib_u8z: ?[*:0]const u8 = @ptrCast(dll_base[desc.DllNameRVA..]);
            if (lib_u8z == null) break;

            var owned = try OwnedZ16.fromU8z(self.Allocator, lib_u8z.?);
            defer owned.deinit();
            const bl = [_][]const u16{dllPath.short.z};
            if (apiset.ApiSetResolve(owned.view(), &bl)) |host_z| {
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

            const library: ?*Dll = if (std.mem.eql(u16, dllPath.shortKey(), owned.raw))
                dll_struct
            else
                try self.ZLoadLibrary(owned.view());
            if (library == null) return;

            if (desc.ModuleHandleRVA != 0) {
                const pHMODULE = ptrFromAttr(?[*]u8, dll_base, desc.Attributes, desc.ModuleHandleRVA);
                pHMODULE.* = library.?.BaseAddr;
            }
            if (desc.ImportNameTableRVA == 0 or desc.ImportAddressTableRVA == 0) continue;

            var orig: *win.IMAGE_THUNK_DATA64 = ptrFromAttr(win.IMAGE_THUNK_DATA64, dll_base, desc.Attributes, desc.ImportNameTableRVA);
            var thunk: *win.IMAGE_THUNK_DATA64 = ptrFromAttr(win.IMAGE_THUNK_DATA64, dll_base, desc.Attributes, desc.ImportAddressTableRVA);
            var tmpname: [256]u8 = undefined;

            while (orig.u1.AddressOfData != 0) : ({
                thunk = @ptrFromInt(@intFromPtr(thunk) + @sizeOf(win.IMAGE_THUNK_DATA64));
                orig = @ptrFromInt(@intFromPtr(orig) + @sizeOf(win.IMAGE_THUNK_DATA64));
            }) {
                if (isOrdinalLookup64(orig.u1.AddressOfData)) {
                    const ord = ordinalOf64(orig.u1.AddressOfData);
                    var addr = library.?.ResolveByOrdinal(ord) orelse return DllError.FuncResolutionFailed;
                    const addr_bytes: [*]const u8 = @ptrCast(addr);
                    if (looksLikeForwarderString(addr_bytes)) {
                        const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(addr)), 0);
                        addr = try self.resolveForwarder(fwd_slice, dllPath);
                    }
                    thunk.u1.Function = @intFromPtr(addr);
                } else {
                    const ibn: *const win.IMAGE_IMPORT_BY_NAME = @ptrCast(@alignCast(dll_base[orig.u1.AddressOfData..]));
                    const name_z: [*:0]const u8 = @ptrCast(&ibn.Name);
                    const up = toUpperTemp(&tmpname, name_z[0..std.mem.len(name_z)]);
                    var addr = library.?.ResolveByName(up) orelse return DllError.FuncResolutionFailed;
                    const addr_bytes: [*]const u8 = @ptrCast(addr);
                    if (looksLikeForwarderString(addr_bytes)) {
                        const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(addr)), 0);
                        addr = try self.resolveForwarder(fwd_slice, dllPath);
                    }
                    thunk.u1.Function = @intFromPtr(addr);
                }
            }
        }
    }

    pub fn ResolveImportInconsistencies(self: *Self, dll_rec: *Dll) !void {
        _ = self;
        log.setContext(logtags.ImpFix);
        defer log.rollbackContext();
        var tmp: [32]u8 = undefined;

        const k1 = toUpperTemp(&tmp, "GetProcAddress");
        if (dll_rec.NameExports.getPtr(k1)) |vp| vp.* = @ptrCast(@constCast(&GetProcAddress));
        const k2 = toUpperTemp(&tmp, "GetModuleHandleA");
        if (dll_rec.NameExports.getPtr(k2)) |vp| vp.* = @ptrCast(@constCast(&GetModuleHandleA));
        const k3 = toUpperTemp(&tmp, "GetModuleHandleW");
        if (dll_rec.NameExports.getPtr(k3)) |vp| vp.* = @ptrCast(@constCast(&GetModuleHandleW));
        const k4 = toUpperTemp(&tmp, "LoadLibraryA");
        if (dll_rec.NameExports.getPtr(k4)) |vp| vp.* = @ptrCast(@constCast(&LoadLibraryA_stub));
        const k5 = toUpperTemp(&tmp, "LoadLibraryW");
        if (dll_rec.NameExports.getPtr(k5)) |vp| vp.* = @ptrCast(@constCast(&LoadLibraryW_stub));
        const k6 = toUpperTemp(&tmp, "LoadLibraryExA");
        if (dll_rec.NameExports.getPtr(k6)) |vp| vp.* = @ptrCast(@constCast(&LoadLibraryExA_stub));
        const k7 = toUpperTemp(&tmp, "LoadLibraryExW");
        if (dll_rec.NameExports.getPtr(k7)) |vp| vp.* = @ptrCast(@constCast(&LoadLibraryExW_stub));
        const k9 = toUpperTemp(&tmp, "ResolveDelayLoadedAPI");
        if (dll_rec.NameExports.getPtr(k9)) |vp| vp.* = @ptrCast(@constCast(&ResolveDelayLoadedAPI_stub));
        const k10 = toUpperTemp(&tmp, "LdrResolveDelayLoadedAPI");
        if (dll_rec.NameExports.getPtr(k10)) |vp| vp.* = @ptrCast(@constCast(&ResolveDelayLoadedAPI_stub));
        const k11 = toUpperTemp(&tmp, "GetModuleFileNameW");
        if (dll_rec.NameExports.getPtr(k11)) |vp| vp.* = @ptrCast(@constCast(&GetModuleFileNameW_stub));
        const k12 = toUpperTemp(&tmp, "GetModuleHandleExW");
        if (dll_rec.NameExports.getPtr(k12)) |vp| vp.* = @ptrCast(@constCast(&GetModuleHandleExW_stub));
        const k13 = toUpperTemp(&tmp, "GetModuleHandleExA");
        if (dll_rec.NameExports.getPtr(k13)) |vp| vp.* = @ptrCast(@constCast(&GetModuleHandleExA_stub));
    }

    pub fn IMAGE_FIRST_SECTION(nt_headers: *const win.IMAGE_NT_HEADERS64) [*]const win.IMAGE_SECTION_HEADER {
        const OptionalHeader: [*]const u8 = @ptrCast(&nt_headers.OptionalHeader);
        const SizeOfOptionalHeader: usize = nt_headers.FileHeader.SizeOfOptionalHeader;
        return @ptrCast(@alignCast(OptionalHeader[SizeOfOptionalHeader..]));
    }

    pub fn ExecuteDll(self: *Self, dll_rec: *Dll) !void {
        const ntdll_dll = (try self.getDllByName("ntdll.dll"));
        const NtProtectVirtualMemory = try ntdll_dll.getProc(fn (i64, *const [*]u8, *const usize, c_int, *c_int) callconv(.winapi) c_int, "NtProtectVirtualMemory");
        const NtFlushInstructionCache = try ntdll_dll.getProc(fn (i32, ?[*]u8, usize) callconv(.winapi) c_int, "NtFlushInstructionCache");

        const nt_headers = try ResolveNtHeaders(dll_rec.BaseAddr);
        const sectionHeader: [*]const win.IMAGE_SECTION_HEADER = IMAGE_FIRST_SECTION(nt_headers);

        var dwProtect: c_int = undefined;
        var i: usize = 0;
        while (i < nt_headers.FileHeader.NumberOfSections) : (i += 1) {
            if (sectionHeader[i].SizeOfRawData == 0) continue;
            const protection = clr.sectionCharacteristicsToPageProtection(sectionHeader[i].Characteristics);
            dwProtect = @bitCast(protection);
            const BaseAddress = dll_rec.BaseAddr[sectionHeader[i].VirtualAddress..];
            const RegionSize: usize = sectionHeader[i].SizeOfRawData;
            var oldProt: c_int = 0;
            _ = NtProtectVirtualMemory(-1, &BaseAddress, &RegionSize, dwProtect, &oldProt);
        }

        _ = NtFlushInstructionCache(-1, null, 0);
        try static_tls.ldrpHandleTlsData(self, dll_rec);
        try seh_fix.rtlInsertInvertedFunctionTable(self, dll_rec);

        if (nt_headers.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_TLS)].Size != 0) {
            const tls_dir: *const win.IMAGE_TLS_DIRECTORY64 = @ptrCast(@alignCast(
                dll_rec.BaseAddr[nt_headers.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_TLS)].VirtualAddress..],
            ));
            if (tls_dir.AddressOfCallBacks != 0) {
                var p: [*]?*const types.DLLEntry = @ptrFromInt(tls_dir.AddressOfCallBacks);
                const hinst: win.HINSTANCE = @ptrCast(dll_rec.BaseAddr);
                while (p[0]) |cb| : (p = p[1..]) _ = cb(hinst, win.DLL_PROCESS_ATTACH, null);
            }
        }

        if (nt_headers.OptionalHeader.AddressOfEntryPoint != 0) {
            const dll_entry: ?*const types.DLLEntry = @ptrCast(dll_rec.BaseAddr[nt_headers.OptionalHeader.AddressOfEntryPoint..]);
            if (dll_entry) |run| {
                const hinst: win.HINSTANCE = @ptrCast(dll_rec.BaseAddr);
                log.info("Starting DLLMain\n", .{});
                const dllmain_result = run(hinst, 1, null);
                log.info("Out of dllmain -> {}\n", .{dllmain_result});
            }
        }
    }

    pub fn ZLoadExe(self: *Self, libname16_: [:0]const u16) anyerror!?*Dll {
        log.setContext(logtags.RefLoad);
        defer log.rollbackContext();

        var resolved = try OwnedZ16.fromU16(self.Allocator, libname16_);
        defer resolved.deinit();
        // Don't call canonicalUpperDll — EXEs don't need .DLL appended
        resolved.toUpperAsciiInPlace();

        var dllPath = (try self.getDllPaths(resolved.view())) orelse return null;
        dllPath.normalize();

        var dll_struct: *Dll = try self.Allocator.create(Dll);
        dll_struct.Path = dllPath;

        var dll_size: usize = 0;
        const dll_bytes = try self.LoadDllInMemory(dllPath, &dll_size) orelse return null;
        defer self.Allocator.free(dll_bytes[0..dll_size]);

        var nt = try ResolveNtHeaders(dll_bytes);

        if (nt.FileHeader.Characteristics.DLL != 0) {
            log.crit("ZLoadExe: target is a DLL not an EXE\n", .{});
            return DllError.LoadFailed;
        }

        var delta: usize = 0;
        const base = try self.MapSections(nt, dll_bytes, &delta);
        dll_struct.BaseAddr = base;
        nt = try ResolveNtHeaders(base);

        try ResolveRVA(base, nt, delta);
        try self.ResolveExports(dll_struct);

        try self.LoadedDlls.put(dllPath.shortKey(), dll_struct);

        try self.ResolveImportInconsistencies(dll_struct);
        try self.ResolveImportTable(base, nt, dllPath, dll_struct);
        try self.resolveExportForwarders(dll_struct);
        self.HostExeBase = base;

        log.info16("EXE mapped, running imports done -> ", .{}, dll_struct.Path.shortView());

        const ntdll_dll = try self.getDllByName("ntdll.dll");
        const NtProtectVirtualMemory = try ntdll_dll.getProc(
            fn (i64, *const [*]u8, *const usize, c_int, *c_int) callconv(.winapi) c_int,
            "NtProtectVirtualMemory",
        );
        const NtFlushInstructionCache = try ntdll_dll.getProc(
            fn (i32, ?[*]u8, usize) callconv(.winapi) c_int,
            "NtFlushInstructionCache",
        );

        const sectionHeader = IMAGE_FIRST_SECTION(nt);
        var i: usize = 0;
        while (i < nt.FileHeader.NumberOfSections) : (i += 1) {
            if (sectionHeader[i].SizeOfRawData == 0) continue;
            const protection = clr.sectionCharacteristicsToPageProtection(sectionHeader[i].Characteristics);
            const dwProtect: c_int = @bitCast(protection);
            const BaseAddress = dll_struct.BaseAddr[sectionHeader[i].VirtualAddress..];
            const RegionSize: usize = sectionHeader[i].SizeOfRawData;
            var oldProt: c_int = 0;
            _ = NtProtectVirtualMemory(-1, &BaseAddress, &RegionSize, dwProtect, &oldProt);
        }
        _ = NtFlushInstructionCache(-1, null, 0);

        try static_tls.ldrpHandleTlsData(self, dll_struct);
        try seh_fix.rtlInsertInvertedFunctionTable(self, dll_struct);

        if (nt.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_TLS)].Size != 0) {
            const tls_dir: *const win.IMAGE_TLS_DIRECTORY64 = @ptrCast(@alignCast(
                base[nt.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_TLS)].VirtualAddress..],
            ));
            if (tls_dir.AddressOfCallBacks != 0) {
                var p: [*]?*const types.DLLEntry = @ptrFromInt(tls_dir.AddressOfCallBacks);
                const hinst: win.HINSTANCE = @ptrCast(base);
                while (p[0]) |cb| : (p = p[1..]) _ = cb(hinst, win.DLL_PROCESS_ATTACH, null);
            }
        }

        return dll_struct;
    }

    pub fn RunExe(self: *Self, exe: *Dll) !void {
        _ = self;
        const nt = try ResolveNtHeaders(exe.BaseAddr);
        if (nt.OptionalHeader.AddressOfEntryPoint == 0) return DllError.LoadFailed;

        const EntryPoint = fn () callconv(.winapi) void;
        const ep: *const EntryPoint = @ptrCast(exe.BaseAddr[nt.OptionalHeader.AddressOfEntryPoint..]);

        log.info16("Jumping to EXE entrypoint ->", .{}, exe.Path.shortView());
        ep();
    }

    pub fn ZLoadLibrary(self: *Self, libname16_: [:0]const u16) anyerror!?*Dll {
        log.setContext(logtags.RefLoad);
        defer log.rollbackContext();

        var resolved = try OwnedZ16.fromU16(self.Allocator, libname16_);
        defer resolved.deinit();
        try resolved.canonicalUpperDll();

        if (apiset.ApiSetResolve(resolved.view(), &.{})) |host_z| {
            const host_sz: [:0]u16 = @ptrCast(host_z);
            try resolved.replaceWithZ16(host_sz);
            try resolved.canonicalUpperDll();
        }

        var dllPath = (try self.getDllPaths(resolved.view())) orelse return null;
        errdefer dllPath.deinit();
        errdefer self.Allocator.destroy(dllPath);
        dllPath.normalize();
        const key = dllPath.shortKey();
        if (self.LoadedDlls.get(key)) |d| {
            dllPath.deinit();
            self.Allocator.destroy(dllPath);
            return d;
        }

        if (self.InFlight.contains(key)) {}
        try self.InFlight.put(key, {});
        defer _ = self.InFlight.remove(key);

        var dll_struct: *Dll = try self.Allocator.create(Dll);
        dll_struct.Path = dllPath;

        log.info16("starting to load {d}", .{dllPath.full.raw.len}, dllPath.full.raw);

        var dll_size: usize = 0;
        const dll_bytes = try self.LoadDllInMemory(dllPath, &dll_size) orelse return null;
        defer self.Allocator.free(dll_bytes[0..dll_size]);

        var nt = try ResolveNtHeaders(dll_bytes);
        var delta: usize = 0;
        const base = try self.MapSections(nt, dll_bytes, &delta);
        dll_struct.BaseAddr = base;
        nt = try ResolveNtHeaders(base);

        try ResolveRVA(base, nt, delta);
        try self.ResolveExports(dll_struct);
        try self.LoadedDlls.put(dllPath.shortKey(), dll_struct);
        try self.ResolveImportInconsistencies(dll_struct);
        self.ResolveImportTable(base, nt, dllPath, dll_struct) catch |e| {
            log.crit(
                "Failed to resolve imports {}\n",
                .{e},
            );
            return e;
        };

        try self.resolveExportForwarders(dll_struct);

        log.info16("executing ", .{}, dll_struct.Path.shortView());
        try self.ExecuteDll(dll_struct);

        return dll_struct;
    }

    pub fn CreateLdrDataTableEntryFromImageBase(self: *Self, dll_rec: *Dll) !*LDR_DATA_TABLE_ENTRY {
        const alloc = self.Allocator;
        const image_base = dll_rec.BaseAddr;
        const dllPath = dll_rec.Path;

        const initSelf = struct {
            fn initSelf(le: *win.LIST_ENTRY) void {
                le.Flink = le;
                le.Blink = le;
            }
        }.initSelf;
        const usFromZ = struct {
            fn usFromZ(z: [:0]const u16) UNICODE_STRING {
                return .{
                    .Length = @intCast(z.len * 2),
                    .MaximumLength = @intCast((z.len + 1) * 2),
                    .alignment = 0,
                    .Buffer = @ptrCast(@constCast(z.ptr)),
                };
            }
        }.usFromZ;

        const nt = try ResolveNtHeaders(image_base);
        const ep_rva = nt.OptionalHeader.AddressOfEntryPoint;
        const ep_ptr: ?*anyopaque = if (ep_rva != 0) @ptrCast(@alignCast(image_base[ep_rva..])) else null;

        var e = try alloc.create(LDR_DATA_TABLE_ENTRY);
        @memset(@as([*]u8, @ptrCast(e))[0..@sizeOf(LDR_DATA_TABLE_ENTRY)], 0);
        initSelf(&e.InLoadOrderLinks);
        initSelf(&e.InMemoryOrderLinks);
        initSelf(&e.InInitializationOrderLinks);
        initSelf(&e.HashLinks);
        e.DllBase = image_base;
        e.EntryPoint = ep_ptr;
        e.SizeOfImage = nt.OptionalHeader.SizeOfImage;
        e.fullDllName = usFromZ(dllPath.fullView());
        e.BaseDllName = usFromZ(dllPath.shortView());
        e.Flags = 0;
        e.LoadCount = 1;
        e.TlsIndex = 0;
        e.TimeDateStamp = nt.FileHeader.TimeDateStamp;
        return e;
    }
};

// ===== Re-exported from ldr_utils for callers that used to access via dll.zig =====

pub const LdrpHashUnicodeString = ldr.LdrpHashUnicodeString;
pub const getNtdllBase = ldr.getNtdllBase;
