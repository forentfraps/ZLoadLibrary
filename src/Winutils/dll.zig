const std = @import("std");
const winz = std.os.windows;
const builtin = @import("builtin");
const clr = @import("clr.zig");
const sneaky_memory = @import("memory.zig");
const logger = @import("sys_logger");
const win = @import("zigwin32").everything;
const apiset = @import("apiset.zig");
const sigscan = @import("sigscan.zig");
const static_tls = @import("static_tls.zig");
const seh_fix = @import("seh_fix.zig");
const actctx = @import("actctx.zig");

pub const ACTCTXW = actctx.ACTCTXW;
pub const types = @import("win_types.zig");
pub const str = @import("u16str.zig");
pub const ldr = @import("ldr_utils.zig");

pub const OwnedZ16 = str.OwnedZ16;
pub const DllError = types.DllError;
pub const UNICODE_STRING = types.UNICODE_STRING;
pub const LDR_DATA_TABLE_ENTRY = types.LDR_DATA_TABLE_ENTRY;
pub const PEB = types.PEB;
pub const IMAGE_DELAYLOAD_DESCRIPTOR = types.IMAGE_DELAYLOAD_DESCRIPTOR;

const W = std.unicode.utf8ToUtf16LeStringLiteral;

const MEM_RESERVE = types.MEM_RESERVE;
const PAGE_READWRITE = types.PAGE_READWRITE;
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

const logtags = enum {
    RefLoad,
    ExpTable,
    ImpFix,
    ImpRes,
    RVAres,
    HookF,
    PathRes,
};

const Log = logger.SysLogger(.{
    .debug_only = true,
    .backend = .nt_write_file,
    .max_context_depth = 1280,
});

pub var log: Log = undefined;

pub fn init_logger_zload() void {
    log = Log.init();
}

pub const Dll = struct {
    NameExports: std.StringHashMap(*anyopaque) = undefined,
    OrdinalExports: std.AutoHashMap(u16, *anyopaque) = undefined,
    BaseAddr: [*]u8 = undefined,
    Path: *DllPath = undefined,
    ExportBase: u32 = 0,
    NumberOfFunctions: u32 = 0,
    Initialized: bool = false,

    MuiBase: ?[*]u8 = null,
    MuiSize: usize = 0,
    MunBase: ?[*]u8 = null,
    MunSize: usize = 0,

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

pub var GLOBAL_DLL_LOADER: DllLoader = undefined;
pub var GLOBAL_DLL_INIT: bool = false;

fn eqlIgnoreCaseW(a: []const u16, b: []const u16) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        const ca: u16 = if (a[i] >= 'a' and a[i] <= 'z') a[i] - 32 else a[i];
        const cb: u16 = if (b[i] >= 'a' and b[i] <= 'z') b[i] - 32 else b[i];
        if (ca != cb) return false;
    }
    return true;
}

fn eqlIgnoreCaseAscii(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        const ca: u8 = if (a[i] >= 'a' and a[i] <= 'z') a[i] - 32 else a[i];
        const cb: u8 = if (b[i] >= 'a' and b[i] <= 'z') b[i] - 32 else b[i];
        if (ca != cb) return false;
    }
    return true;
}

pub fn GetProcAddress(hModule: [*]u8, procname: [*:0]const u8) callconv(.winapi) ?*anyopaque {
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

    const self = &GLOBAL_DLL_LOADER;

    const name_int: usize = @intFromPtr(procname);
    const is_ordinal = name_int < 0x10000;

    if (is_ordinal) {
        const ord: u16 = @intCast(name_int & 0xFFFF);
        var it_o = self.LoadedDlls.keyIterator();
        while (it_o.next()) |key| {
            const d = self.LoadedDlls.get(key.*).?;
            if (d.BaseAddr == hModule) return d.OrdinalExports.get(ord);
        }
        log.crit("GPA: hModule {*} not found in LoadedDlls for ordinal #{d}", .{ hModule, ord });
        return null;
    }

    const name_slice = procname[0..std.mem.len(procname)];

    var it = self.LoadedDlls.keyIterator();
    while (it.next()) |key| {
        const d = self.LoadedDlls.get(key.*).?;
        if (d.BaseAddr == hModule) {
            var buf: [256]u8 = undefined;
            const up = toUpperTemp(&buf, name_slice);

            return d.NameExports.get(up);
        }
    }

    log.crit("GPA: hModule {*} not found in LoadedDlls for '{s}'", .{ hModule, name_slice });
    return null;
}

pub fn GetModuleHandleA(moduleName_: ?[*:0]const u8) callconv(.winapi) ?[*]u8 {
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

    const self = &GLOBAL_DLL_LOADER;
    if (moduleName_) |moduleName| {
        var owned = OwnedZ16.fromU8z(self.Allocator, moduleName) catch return null;
        log.info("GMHA {s}", .{moduleName});
        defer owned.deinit();
        return GetModuleHandleW(owned.view());
    } else {
        if (self.HostExeBase) |exe_base| return exe_base;
        const peb: usize = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> usize),
            :
            : .{ .memory = true });
        const addr: *[*]u8 = @ptrFromInt(peb + 0x10);
        return addr.*;
    }
}

pub fn GetModuleHandleW(moduleName16_: ?[*:0]const u16) callconv(.winapi) ?[*]u8 {
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

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
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

    log.info("LLA {s}", .{libname});
    const self = &GLOBAL_DLL_LOADER;
    var name16 = OwnedZ16.fromU8z(self.Allocator, libname) catch return null;
    defer name16.deinit();
    return LoadLibraryW_stub(@ptrCast(name16.viewMut().ptr));
}

pub fn LoadLibraryW_stub(libname16: [*:0]u16) callconv(.winapi) ?[*]u8 {
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

    log.info16("LLW", .{}, @ptrCast(libname16[0..std.mem.len(libname16)]));
    const ret_addr: usize = @returnAddress();
    const cookie = pushCallerActCtx(ret_addr);
    defer if (cookie) |c| GLOBAL_DLL_LOADER.actctx_mgr.popContext(c);
    GLOBAL_DLL_LOADER.lockLoader();
    defer GLOBAL_DLL_LOADER.unlockLoader();
    const queue_start = GLOBAL_DLL_LOADER.pending_dll_mains.items.len;
    const d = (&GLOBAL_DLL_LOADER).ZLoadLibrary(@ptrCast(libname16[0..std.mem.len(libname16)])) catch {
        GLOBAL_DLL_LOADER.runPendingDllMains(queue_start);
        return null;
    };
    GLOBAL_DLL_LOADER.runPendingDllMains(queue_start);

    const kernel32 = (GLOBAL_DLL_LOADER.getDllByName("kernel32.dll") catch
        unreachable);
    const SetLastError = kernel32.getProc(fn (c_int) callconv(.winapi) void, "SetLastError") catch unreachable;
    SetLastError(0);
    if (d) |dll| return dll.BaseAddr;
    return null;
}

fn pushCallerActCtx(addr: usize) ?usize {
    const self = &GLOBAL_DLL_LOADER;
    var it = self.LoadedDlls.valueIterator();
    while (it.next()) |dll_pp| {
        const d = dll_pp.*;
        const base = @intFromPtr(d.BaseAddr);
        const dos: *align(1) const win.IMAGE_DOS_HEADER = @ptrCast(d.BaseAddr);
        const nt_off: usize = @intCast(dos.e_lfanew);
        const nt: *align(1) const win.IMAGE_NT_HEADERS64 =
            @ptrCast(@alignCast(d.BaseAddr[nt_off..]));
        if (nt.Signature != 0x4550) continue;
        const sz: usize = nt.OptionalHeader.SizeOfImage;
        if (addr >= base and addr < base + sz) {
            const ctx = self.actctx_mgr.lookupDllContext(d.BaseAddr);
            return self.actctx_mgr.pushContext(ctx);
        }
    }
    return null;
}

pub fn LoadLibraryExA_stub(libname: [*:0]const u8, file: ?*anyopaque, flags: u32) callconv(.winapi) ?[*]u8 {
    _ = file;
    _ = flags;
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

    log.info("LLEA {s}", .{libname});
    const self = &GLOBAL_DLL_LOADER;
    var name16 = OwnedZ16.fromU8z(self.Allocator, libname) catch return null;
    defer name16.deinit();
    return LoadLibraryExW_stub(@ptrCast(name16.viewMut().ptr), null, 0);
}

pub fn LoadLibraryExW_stub(libname16: [*:0]u16, file: ?*anyopaque, flags: u32) callconv(.winapi) ?[*]u8 {
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

    log.info16("LLEW ", .{}, @ptrCast(libname16[0..std.mem.len(libname16)]));
    if (file) |file_deref| log.info("File ptr: {*}", .{file_deref});
    log.info("Flags : {x}", .{flags});
    const self = &GLOBAL_DLL_LOADER;
    const ret_addr: usize = @returnAddress();
    const cookie = pushCallerActCtx(ret_addr);
    defer if (cookie) |c| self.actctx_mgr.popContext(c);
    self.lockLoader();
    defer self.unlockLoader();
    const queue_start = self.pending_dll_mains.items.len;
    const result = self.ZLoadLibrary(@ptrCast(libname16[0..std.mem.len(libname16)])) catch {
        self.runPendingDllMains(queue_start);
        return null;
    };
    self.runPendingDllMains(queue_start);
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
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

    const self = &GLOBAL_DLL_LOADER;
    self.lockLoader();
    defer self.unlockLoader();
    const lib_u8z: [*:0]const u8 = @ptrCast(parent_base[descriptor.DllNameRVA..]);
    var owned = OwnedZ16.fromU8z(self.Allocator, lib_u8z) catch return null;
    defer owned.deinit();
    log.info16("DelayLoading: ", .{}, owned.view());
    if (apiset.ApiSetResolve(owned.view(), &.{})) |host_z| {
        const host_sz: [:0]u16 = @ptrCast(host_z);
        owned.replaceWithZ16(host_sz) catch return null;
    }
    owned.canonicalUpperDll() catch return null;
    const queue_start = self.pending_dll_mains.items.len;
    const library = (self.ZLoadLibrary(owned.view()) catch {
        self.runPendingDllMains(queue_start);
        return null;
    }) orelse {
        self.runPendingDllMains(queue_start);
        return null;
    };
    self.runPendingDllMains(queue_start);
    var addr: ?*anyopaque = null;
    const orig_thunk_va = descriptor.ImportNameTableRVA;
    if (orig_thunk_va != 0) {
        var int_ptr: *win.IMAGE_THUNK_DATA64 = @ptrCast(@alignCast(parent_base[orig_thunk_va..]));
        var iat_ptr: *win.IMAGE_THUNK_DATA64 = @ptrCast(@alignCast(parent_base[descriptor.ImportAddressTableRVA..]));
        var tmpname: [256]u8 = undefined;
        var resolved_name_buf: [256]u8 = undefined;
        var resolved_name_len: usize = 0;
        while (int_ptr.u1.AddressOfData != 0) : ({
            int_ptr = @ptrFromInt(@intFromPtr(int_ptr) + @sizeOf(win.IMAGE_THUNK_DATA64));
            iat_ptr = @ptrFromInt(@intFromPtr(iat_ptr) + @sizeOf(win.IMAGE_THUNK_DATA64));
        }) {
            if (@intFromPtr(iat_ptr) != @intFromPtr(thunk)) continue;
            if (isOrdinalLookup64(int_ptr.u1.AddressOfData)) {
                const ord = ordinalOf64(int_ptr.u1.AddressOfData);
                addr = library.ResolveByOrdinal(ord);
                if (std.fmt.bufPrint(&resolved_name_buf, "#ord{d}", .{ord})) |s| {
                    resolved_name_len = s.len;
                } else |_| {
                    resolved_name_buf[0] = '?';
                    resolved_name_len = 1;
                }
            } else {
                const ibn: *const win.IMAGE_IMPORT_BY_NAME =
                    @ptrCast(@alignCast(parent_base[int_ptr.u1.AddressOfData..]));
                const name_z: [*:0]const u8 = @ptrCast(&ibn.Name);
                const real_name = std.mem.sliceTo(name_z, 0);
                resolved_name_len = @min(real_name.len, resolved_name_buf.len);
                @memcpy(resolved_name_buf[0..resolved_name_len], real_name[0..resolved_name_len]);
                const up = toUpperTemp(&tmpname, real_name);
                addr = library.ResolveByName(up);
            }
            if (addr) |a| {
                // Render the parent DLL name as ASCII for the log tag.
                var dll_tag: [128]u8 = undefined;
                const dll_w = owned.view();
                const dll_tag_len = blk: {
                    const n = @min(dll_w.len, dll_tag.len);
                    for (0..n) |i| dll_tag[i] = if (dll_w[i] < 0x80) @intCast(dll_w[i]) else '?';
                    break :blk n;
                };
                _ = self.writeProtectedSlot(
                    @ptrCast(thunk),
                    @intFromPtr(a),
                    dll_tag[0..dll_tag_len],
                    resolved_name_buf[0..resolved_name_len],
                ) catch |e| {
                    log.crit("[delay] writeProtectedSlot failed: {}", .{e});
                };
            }

            break;
        }
    }
    return addr;
}

fn lookupModulePath(hModule: ?[*]u8) ?[:0]const u16 {
    const self = &GLOBAL_DLL_LOADER;
    if (hModule) |base| {
        var it = self.LoadedDlls.valueIterator();
        while (it.next()) |dll_ptr| {
            const d = dll_ptr.*;
            if (d.BaseAddr == base) return d.Path.full.z;

            if (d.MuiBase) |mb| if (mb == base) return d.Path.full.z;
            if (d.MunBase) |mb| if (mb == base) return d.Path.full.z;
        }
        return null;
    }
    // hModule == null → process EXE.
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
            return full;
        }
    }
    return null;
}

pub fn GetModuleFileNameW_stub(
    hModule: ?[*]u8,
    lpFilename: [*]u16,
    nSize: u32,
) callconv(.winapi) u32 {
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

    if (nSize == 0) return 0;
    const full = lookupModulePath(hModule) orelse {
        log.info("GetModuleFileNameW: hModule=0x{x} NOT FOUND", .{
            if (hModule) |b| @intFromPtr(b) else 0,
        });
        return 0;
    };
    const cap: usize = @as(usize, nSize) - 1;
    if (full.len > cap) {
        @memcpy(lpFilename[0..cap], full[0..cap]);
        lpFilename[cap] = 0;
        return nSize;
    }
    @memcpy(lpFilename[0..full.len], full[0..full.len]);
    lpFilename[full.len] = 0;
    return @intCast(full.len);
}

pub fn GetModuleFileNameA_stub(
    hModule: ?[*]u8,
    lpFilename: [*]u8,
    nSize: u32,
) callconv(.winapi) u32 {
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

    if (nSize == 0) return 0;
    const full = lookupModulePath(hModule) orelse {
        log.info("GetModuleFileNameA: hModule=0x{x} NOT FOUND", .{
            if (hModule) |b| @intFromPtr(b) else 0,
        });
        return 0;
    };
    // DLL paths are pure ASCII on Windows — direct low-byte truncation is
    // safe and avoids pulling in WideCharToMultiByte / a real codepage.
    const cap: usize = @as(usize, nSize) - 1;
    const truncated = full.len > cap;
    const copy_len: usize = if (truncated) cap else full.len;
    var i: usize = 0;
    while (i < copy_len) : (i += 1) {
        const wc = full[i];
        lpFilename[i] = if (wc < 0x80) @intCast(wc) else '?';
    }
    lpFilename[copy_len] = 0;
    return if (truncated) nSize else @intCast(copy_len);
}

pub fn GetModuleHandleExW_stub(
    dwFlags: u32,
    lpModuleName: ?*anyopaque,
    phModule: *?[*]u8,
) callconv(.winapi) i32 {
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

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
    var scope = log.pushEnum(logtags.HookF);
    defer scope.end();

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

pub const DllLoader = struct {
    LoadedDlls: u16HashMapType = undefined,
    Allocator: std.mem.Allocator,
    HeapAllocator: sneaky_memory.HeapAllocator = undefined,
    InFlight: U16Set = undefined,
    WinVer: sigscan.WinVer = undefined,
    HostExeBase: ?[*]u8 = null,
    actctx_mgr: actctx.ActCtxManager,

    loading_depth: usize = 0,
    pending_dll_mains: std.ArrayList(*Dll) = .empty,

    // Reentrant loader lock; same role as ntdll!LdrpLoaderLock.
    loader_lock_state: u32 = 0,
    loader_lock_owner_tid: u32 = 0,
    loader_lock_recursion: usize = 0,

    const Self = @This();

    pub fn lockLoader(self: *Self) void {
        const my_tid = winz.GetCurrentThreadId();
        if (@atomicLoad(u32, &self.loader_lock_owner_tid, .acquire) == my_tid) {
            self.loader_lock_recursion += 1;
            return;
        }
        while (true) {
            if (@cmpxchgWeak(u32, &self.loader_lock_state, 0, 1, .acquire, .monotonic) == null) {
                break;
            }
            std.Thread.yield() catch {};
        }
        @atomicStore(u32, &self.loader_lock_owner_tid, my_tid, .release);
        self.loader_lock_recursion = 1;
    }

    pub fn unlockLoader(self: *Self) void {
        self.loader_lock_recursion -= 1;
        if (self.loader_lock_recursion == 0) {
            @atomicStore(u32, &self.loader_lock_owner_tid, 0, .release);
            @atomicStore(u32, &self.loader_lock_state, 0, .release);
        }
    }

    pub fn init(allocator: std.mem.Allocator) !void {
        if (GLOBAL_DLL_INIT == false) {
            GLOBAL_DLL_LOADER = Self{
                .LoadedDlls = undefined,
                .Allocator = allocator,
                .InFlight = U16Set.init(allocator),
                .actctx_mgr = undefined,
            };
            init_logger_zload();
            const loader = &GLOBAL_DLL_LOADER;
            try loader.getLoadedDlls();
            const kb_ = try loader.getDllByName("kernelbase.dll");
            const ntd_ = try loader.getDllByName("ntdll.dll");
            try loader.actctx_mgr.init(allocator);
            loader.actctx_mgr.captureRealFns(kb_, ntd_);
            var it = loader.LoadedDlls.valueIterator();
            while (it.next()) |dll_ptr| try loader.PatchExportTableLoaderStubs(dll_ptr.*);
            try loader.resolveKnownForwarders();

            if (actctx.captureRealLdrLoadDllForRedirect(ntd_)) {
                _ = loader.patchImportThunk(
                    kb_.BaseAddr,
                    "ntdll.dll",
                    "LdrLoadDll",
                    @intFromPtr(&actctx.LdrLoadDll_hook),
                ) catch |e| log.crit("[iat] kernelbase->ntdll!LdrLoadDll patch failed: {}", .{e});
            }

            inline for (.{ "LdrResolveDelayLoadedAPI", "LdrResolveDelayLoadedAPIEx" }) |fname| {
                _ = loader.patchImportThunk(
                    kb_.BaseAddr,
                    "ntdll.dll",
                    fname,
                    @intFromPtr(&ResolveDelayLoadedAPI_stub),
                ) catch |e| log.crit("[iat] kernelbase->ntdll!{s} patch failed: {}", .{ fname, e });
            }

            GLOBAL_DLL_LOADER.WinVer = try sigscan.getWinVer(loader);
            GLOBAL_DLL_INIT = true;
        }
    }
    pub fn deinit() void {
        const self = &GLOBAL_DLL_LOADER;
        const ntdll = self.getDllByName("ntdll.dll") catch null;
        self.actctx_mgr.deinit();
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
        var detach_list = std.ArrayList(*Dll).initCapacity(self.Allocator, self.LoadedDlls.unmanaged.size) catch unreachable;
        defer detach_list.deinit(self.Allocator);
        {
            var it = self.LoadedDlls.valueIterator();
            while (it.next()) |dll_ptr| {
                const d = dll_ptr.*;
                if (!peb_bases.contains(@intFromPtr(d.BaseAddr)))
                    detach_list.append(self.Allocator, d) catch {};
            }
        }
        var i: usize = detach_list.items.len;
        while (i > 0) {
            i -= 1;
            self.DetachDll(detach_list.items[i]);
        }
        var it = self.LoadedDlls.valueIterator();
        while (it.next()) |dll_ptr| {
            const d = dll_ptr.*;

            var key_it = d.NameExports.keyIterator();
            while (key_it.next()) |k| self.Allocator.free(k.*);
            d.NameExports.deinit();

            d.OrdinalExports.deinit();

            d.Path.deinit();
            self.Allocator.destroy(d.Path);

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
    pub fn DetachDll(_: *Self, dll_rec: *Dll) void {
        // TODO reverse the FLS/TLS unload, not sure if viable
        const nt = DllLoader.ResolveNtHeaders(dll_rec.BaseAddr) catch return;

        // Fire TLS callbacks with DLL_PROCESS_DETACH first
        if (nt.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_TLS)].Size != 0) {
            const tls_dir: *const win.IMAGE_TLS_DIRECTORY64 = @ptrCast(@alignCast(
                dll_rec.BaseAddr[nt.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_TLS)].VirtualAddress..],
            ));
            if (tls_dir.AddressOfCallBacks != 0) {
                var p: [*]?*const types.DLLEntry = @ptrFromInt(tls_dir.AddressOfCallBacks);
                const hinst: win.HINSTANCE = @ptrCast(dll_rec.BaseAddr);
                while (p[0]) |cb| : (p = p[1..]) _ = cb(hinst, win.DLL_PROCESS_DETACH, null);
            }
        }

        if (nt.OptionalHeader.AddressOfEntryPoint != 0) {
            const dll_entry: ?*const types.DLLEntry = @ptrCast(
                dll_rec.BaseAddr[nt.OptionalHeader.AddressOfEntryPoint..],
            );
            if (dll_entry) |run| {
                const hinst: win.HINSTANCE = @ptrCast(dll_rec.BaseAddr);
                log.info16("DLL_PROCESS_DETACH -> ", .{}, dll_rec.Path.shortView());
                _ = run(hinst, win.DLL_PROCESS_DETACH, null);
            }
        }
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

                dll_rec.* = .{};
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
        var scope = log.pushEnum(logtags.ExpTable);
        defer scope.end();

        const bytes = dll_rec.BaseAddr;
        const dos: *win.IMAGE_DOS_HEADER = @ptrCast(@alignCast(bytes));
        const nt: *align(1) const win.IMAGE_NT_HEADERS64 = @ptrCast(@alignCast(bytes[@intCast(dos.e_lfanew)..]));
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
            if (dep.ResolveByName(up)) |a| return a;

            const last = if (up.len > 0) up[up.len - 1] else 0;
            if (last != 'W' and last != 'A' and up.len + 1 < buf.len) {
                buf[up.len] = 'W';
                const w_name = buf[0 .. up.len + 1];
                if (dep.ResolveByName(w_name)) |a| {
                    log.info(
                        "[fwd] {s} FWD -> {s}: missing base name, resolved via 'W' suffix ({s})",
                        .{ up, fwd, w_name },
                    );
                    return a;
                }
                buf[up.len] = 'A';
                const a_name = buf[0 .. up.len + 1];
                if (dep.ResolveByName(a_name)) |a| {
                    log.info(
                        "[fwd] {s} FWD -> {s}: missing base name, resolved via 'A' suffix ({s})",
                        .{ up, fwd, a_name },
                    );
                    return a;
                }
            }

            log.crit("FUNCTION THAT FAILED TO RESOLVE: {s} FWD -> {s} (also tried W/A suffixes)", .{ up, fwd });
            log.crit16("Master dll: ", .{}, targetPath.short.z);
            return error.FuncResolutionByNameFailed;
        }
    }

    pub fn resolveExportForwarders(self: *Self, dll_rec: *Dll) !void {
        var scope = log.pushEnum(logtags.ExpTable);
        defer scope.end();

        var name_it = dll_rec.NameExports.iterator();
        while (name_it.next()) |entry| {
            const ptr: [*]const u8 = @ptrCast(entry.value_ptr.*);
            if (!looksLikeForwarderString(ptr)) continue;
            const fwd_slice = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(ptr)), 0);
            const resolved = self.resolveForwarder(fwd_slice, dll_rec.Path) catch |err| {
                log.crit("  failed: {}", .{err});
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
                log.crit("  failed: {}", .{err});
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
        var scope = log.pushEnum(logtags.PathRes);
        defer scope.end();

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

        if (self.actctx_mgr.resolveSxsPath(self.Allocator, libname16_)) |sxs_path| {
            defer self.Allocator.free(sxs_path);
            log.info16("[sxs] redirected -> ", .{}, sxs_path);
            return try makePath(self.Allocator, sxs_path);
        }

        // Search order: EXE dir, system32, ".\", %PATH%. Matches OS safe-search.
        var PATH: [33000:0]u16 = undefined;
        const PATH_s = W("PATH");
        var len: usize = 0;

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

                var sep: usize = 0;
                var si: usize = 0;
                while (si < full.len) : (si += 1) {
                    if (full[si] == '\\' or full[si] == '/') sep = si;
                }
                if (sep == 0) continue;
                const dir = full[0..sep];

                if (len + dir.len + 2 < 33000) {
                    std.mem.copyForwards(u16, PATH[len..][0..dir.len], dir);
                    PATH[len + dir.len] = @intCast(';');
                    PATH[len + dir.len + 1] = 0;
                    len += dir.len + 1;
                }
                break;
            }
        }

        const syslen: usize = @intCast(GetSystemDirectoryW(PATH[len..].ptr, @intCast(33000 - len - 4)));
        PATH[len + syslen] = @intCast(';');
        PATH[len + syslen + 1] = 0;
        len += syslen + 1;

        PATH[len] = @intCast('.');
        PATH[len + 1] = @intCast('\\');
        PATH[len + 2] = @intCast(';');
        PATH[len + 3] = 0;
        len += 3;

        if (33000 > len + 2) {
            const remaining: c_uint = @intCast(33000 - len - 2);
            const env_chars: usize = @intCast(GetEnvironmentVariableW(PATH_s.ptr, PATH[len..].ptr, remaining));
            if (env_chars > 0) {
                if (PATH[len + env_chars - 1] != @as(u16, @intCast(';'))) {
                    PATH[len + env_chars] = @intCast(';');
                    PATH[len + env_chars + 1] = 0;
                    len += env_chars + 1;
                } else {
                    PATH[len + env_chars] = 0;
                    len += env_chars;
                }
            }
        }

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

                // allocSentinel reserves+zeros the trailing u16 so downstream :0 slicing doesn't panic.
                const dir_len = end_pointer - start_pointer;
                const tmp_len = dir_len + 1 + libname16_.len;
                const tmp_z = try self.Allocator.allocSentinel(u16, tmp_len, 0);
                defer self.Allocator.free(tmp_z);

                std.mem.copyForwards(u16, tmp_z[0..dir_len], PATH[start_pointer..end_pointer]);
                tmp_z[dir_len] = @intCast('\\');
                std.mem.copyForwards(u16, tmp_z[dir_len + 1 ..], libname16_);

                SetLastError(0);
                _ = GetFileAttributesW(tmp_z.ptr);
                const err: c_int = GetLastError();
                if (err == 0) {
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

        const dll_handle = CreateFileW(dllPath.fullView(), GENERIC_READ, 1, null, OPEN_EXISTING, 0, null);
        defer _ = CloseHandle(dll_handle);
        if (dll_handle == win.INVALID_HANDLE_VALUE) {
            log.crit16("Failed to load file", .{}, dllPath.fullView());
            return error.FileNotFound;
        }

        var dll_size_i: i64 = 0;
        if ((GetFileSizeEx(dll_handle, &dll_size_i) <= 0)) return DllError.Size;
        dllSize.* = @intCast(dll_size_i);

        const dll_bytes: [*]u8 = (try self.Allocator.alloc(u8, dllSize.*)).ptr;
        var bytes_read: u32 = 0;
        _ = ReadFile(dll_handle, dll_bytes, @as(u32, @intCast(dllSize.*)), &bytes_read, null);
        return dll_bytes;
    }

    pub fn ResolveNtHeaders(dll_bytes: [*]u8) !*align(1) const win.IMAGE_NT_HEADERS64 {
        const dos_headers: *align(1) win.IMAGE_DOS_HEADER = @ptrCast(@alignCast(dll_bytes));
        const nt_headers: *align(1) const win.IMAGE_NT_HEADERS64 =
            @ptrCast(@alignCast(dll_bytes[@intCast(dos_headers.e_lfanew)..]));
        if (nt_headers.Signature != 0x4550) return error.InvalidPESignature;
        return nt_headers;
    }

    pub fn MapSections(
        self: *Self,
        nt_headers: *align(1) const win.IMAGE_NT_HEADERS64,
        dll_bytes: [*]u8,
        delta_image_base: *isize,
    ) ![*]u8 {
        const ntdll_dll = (try self.getDllByName("ntdll.dll"));
        const ZwAllocateVirtualMemory = try ntdll_dll.getProc(
            fn (i64, *?[*]u8, usize, *usize, u32, u32) callconv(.winapi) c_int,
            "ZwAllocateVirtualMemory",
        );

        var dll_base_dirty: ?[*]u8 = null;
        var virtAllocSize: usize = nt_headers.OptionalHeader.SizeOfImage;

        const status: c_int = ZwAllocateVirtualMemory(
            -1,
            &dll_base_dirty,
            0,
            &virtAllocSize,
            MEM_RESERVE | MEM_COMMIT,
            PAGE_EXECUTE_READWRITE,
        );
        if (status != 0 or dll_base_dirty == null) return DllError.VirtualAllocNull;
        const dll_base = dll_base_dirty.?;
        log.info("dllbase -> {*}", .{dll_base});
        delta_image_base.* = @as(isize, @intCast(@intFromPtr(dll_base))) - @as(isize, @intCast(nt_headers.OptionalHeader.ImageBase));

        std.mem.copyForwards(
            u8,
            dll_base[0..nt_headers.OptionalHeader.SizeOfHeaders],
            dll_bytes[0..nt_headers.OptionalHeader.SizeOfHeaders],
        );

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

    pub fn ResolveRVA(dll_base: [*]u8, nt_headers: *align(1) const win.IMAGE_NT_HEADERS64, delta_image_base: isize) !void {
        var scope = log.pushEnum(logtags.RVAres);
        defer scope.end();

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
                    const adjuststed_ptr = @as(isize, @intCast(ptr.*)) + delta_image_base;
                    ptr.* = @intCast(adjuststed_ptr);
                }
                relocations_processed += @sizeOf(types.BASE_RELOCATION_ENTRY);
            }
        }
    }

    pub fn validateImportTable(
        self: *Self,
        dll_base: [*]u8,
        nt_headers: *align(1) const win.IMAGE_NT_HEADERS64,
        dll_struct: *Dll,
    ) usize {
        _ = self;
        const impdir = nt_headers.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_IMPORT)];
        if (impdir.Size == 0) return 0;

        var bad: usize = 0;
        var desc: *const win.IMAGE_IMPORT_DESCRIPTOR =
            @ptrCast(@alignCast(dll_base[impdir.VirtualAddress..]));
        while (desc.Name != 0) : (desc =
            @ptrFromInt(@intFromPtr(desc) + @sizeOf(win.IMAGE_IMPORT_DESCRIPTOR)))
        {
            const dll_name_z: [*:0]const u8 = @ptrCast(dll_base[desc.Name..]);
            const dll_name = std.mem.sliceTo(dll_name_z, 0);
            if (dll_name.len == 0) continue;

            var int_rva: u32 = desc.Anonymous.OriginalFirstThunk;
            const iat_rva: u32 = desc.FirstThunk;
            if (int_rva == 0) int_rva = iat_rva;

            var int_thunk: *align(4) const win.IMAGE_THUNK_DATA64 =
                @ptrCast(@alignCast(dll_base[int_rva..]));
            var iat_thunk: *align(4) const win.IMAGE_THUNK_DATA64 =
                @ptrCast(@alignCast(dll_base[iat_rva..]));

            var idx: usize = 0;
            while (int_thunk.u1.AddressOfData != 0) : ({
                int_thunk = @ptrFromInt(@intFromPtr(int_thunk) + @sizeOf(win.IMAGE_THUNK_DATA64));
                iat_thunk = @ptrFromInt(@intFromPtr(iat_thunk) + @sizeOf(win.IMAGE_THUNK_DATA64));
                idx += 1;
            }) {
                const slot_val: usize = iat_thunk.u1.Function;
                if (slot_val >= 0x10000) continue;

                bad += 1;
                if (isOrdinalLookup64(int_thunk.u1.AddressOfData)) {
                    const ord = ordinalOf64(int_thunk.u1.AddressOfData);
                    log.crit(
                        "[iat-audit] import #{d} from {s}!#ord{d}: slot=0x{x} value=0x{x} (UNRESOLVED)",
                        .{ idx, dll_name, ord, @intFromPtr(iat_thunk), slot_val },
                    );
                    log.crit16("  in DLL: ", .{}, dll_struct.Path.short.view());
                } else {
                    const ibn: *const win.IMAGE_IMPORT_BY_NAME =
                        @ptrCast(@alignCast(dll_base[int_thunk.u1.AddressOfData..]));
                    const name_z: [*:0]const u8 = @ptrCast(&ibn.Name);
                    const fname = std.mem.sliceTo(name_z, 0);
                    log.crit(
                        "[iat-audit] import #{d} from {s}!{s}: slot=0x{x} value=0x{x} (UNRESOLVED)",
                        .{ idx, dll_name, fname, @intFromPtr(iat_thunk), slot_val },
                    );
                    log.crit16("  in DLL: ", .{}, dll_struct.Path.short.view());
                }
            }
        }
        if (bad != 0) {
            log.crit("[iat-audit] TOTAL UNRESOLVED IAT SLOTS = {d}", .{bad});
        }
        return bad;
    }

    pub fn ResolveImportTable(
        self: *Self,
        dll_base: [*]u8,
        nt_headers: *align(1) const win.IMAGE_NT_HEADERS64,
        dllPath: *DllPath,
        dll_struct: *Dll,
    ) !void {
        var scope = log.pushEnum(logtags.ImpRes);
        defer scope.end();

        const impdir = nt_headers.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_IMPORT)];
        if (impdir.Size == 0) return;

        var import_descriptor: *const win.IMAGE_IMPORT_DESCRIPTOR =
            @ptrCast(@alignCast(dll_base[impdir.VirtualAddress..]));

        while (import_descriptor.Name != 0) : (import_descriptor =
            @ptrFromInt(@intFromPtr(import_descriptor) + @sizeOf(win.IMAGE_IMPORT_DESCRIPTOR)))
        {
            const lib_u8z: [*:0]const u8 = @ptrCast(dll_base[import_descriptor.Name..]);
            if (std.mem.len(lib_u8z) == 0) continue;

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

            const library: *Dll = blk: {
                if (std.mem.eql(u16, dllPath.shortKey(), libraryNameToLoad16.raw)) {
                    break :blk dll_struct;
                }
                const loaded = (try self.ZLoadLibrary(libraryNameToLoad16.z)) orelse {
                    log.crit16("Failed to resolve DURING IMOPRTS: ", .{}, libraryNameToLoad16.z);
                    return error.ImportDllIsNull;
                };
                break :blk loaded;
            };

            var orig_thunk_rva: u32 = import_descriptor.Anonymous.OriginalFirstThunk;
            const thunk_rva: u32 = import_descriptor.FirstThunk;
            if (orig_thunk_rva == 0) orig_thunk_rva = import_descriptor.FirstThunk;

            log.info("orig ptr {*}\n", .{dll_base[orig_thunk_rva..]});
            var orig: *align(4) win.IMAGE_THUNK_DATA64 = @ptrCast(@alignCast(dll_base[orig_thunk_rva..]));
            var thunk: *align(4) win.IMAGE_THUNK_DATA64 = @ptrCast(@alignCast(dll_base[thunk_rva..]));
            var tmpname: [256]u8 = undefined;

            while (orig.u1.AddressOfData != 0) : ({
                thunk = @ptrFromInt(@intFromPtr(thunk) + @sizeOf(win.IMAGE_THUNK_DATA64));
                orig = @ptrFromInt(@intFromPtr(orig) + @sizeOf(win.IMAGE_THUNK_DATA64));
            }) {
                if (isOrdinalLookup64(orig.u1.AddressOfData)) {
                    const ord = ordinalOf64(orig.u1.AddressOfData);
                    var addr = library.ResolveByOrdinal(ord) orelse {
                        log.info16("Failed ordinal {x} lookup for library -> ", .{ord}, libraryNameToLoad16.raw);
                        return DllError.FuncResolutionFailed;
                    };
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
                    var addr = library.ResolveByName(up) orelse {
                        log.crit16("Failed name lookup ", .{}, libraryNameToLoad16.raw);
                        log.crit("  symbol: {s}", .{up});
                        return DllError.FuncResolutionFailed;
                    };
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

    pub fn PatchExportTableLoaderStubs(self: *Self, dll_rec: *Dll) !void {
        var scope = log.pushEnum(logtags.ImpFix);
        defer scope.end();

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
        const k11a = toUpperTemp(&tmp, "GetModuleFileNameA");
        if (dll_rec.NameExports.getPtr(k11a)) |vp| vp.* = @ptrCast(@constCast(&GetModuleFileNameA_stub));
        const k12 = toUpperTemp(&tmp, "GetModuleHandleExW");
        if (dll_rec.NameExports.getPtr(k12)) |vp| vp.* = @ptrCast(@constCast(&GetModuleHandleExW_stub));
        const k13 = toUpperTemp(&tmp, "GetModuleHandleExA");
        if (dll_rec.NameExports.getPtr(k13)) |vp| vp.* = @ptrCast(@constCast(&GetModuleHandleExA_stub));
        // Diagnostic hooks (InitCommonControlsEx in comctl32, RegisterClassExW
        // in user32). No-op pass-through that logs entry/exit + GetLastError.
        actctx.patchDiagnosticHooks(&self.actctx_mgr, dll_rec);
    }

    fn getVirtualProtect(self: *Self) !*const fn ([*]u8, usize, u32, *u32) callconv(.winapi) i32 {
        const VP_T = fn ([*]u8, usize, u32, *u32) callconv(.winapi) i32;
        const kb = self.getDllByName("kernelbase.dll") catch null;
        if (kb) |k| {
            if (k.getProc(VP_T, "VirtualProtect")) |fp| return fp else |_| {}
        }
        const k32 = try self.getDllByName("kernel32.dll");
        return try k32.getProc(VP_T, "VirtualProtect");
    }

    pub fn writeProtectedSlot(
        self: *Self,
        slot_ptr: [*]u8,
        new_value: usize,
        tag_dll: []const u8,
        tag_func: []const u8,
    ) !?usize {
        const VirtualProtect = try self.getVirtualProtect();
        const old: usize = @as(*usize, @ptrCast(@alignCast(slot_ptr))).*;
        const PROT_RW: u32 = 0x04;
        var old_prot: u32 = 0;
        const ok1 = VirtualProtect(slot_ptr, @sizeOf(usize), PROT_RW, &old_prot);
        if (ok1 == 0) {
            log.crit(
                "[iat] VirtualProtect(RW) FAILED for {s}!{s} slot=0x{x}",
                .{ tag_dll, tag_func, @intFromPtr(slot_ptr) },
            );
            return null;
        }
        @as(*usize, @ptrCast(@alignCast(slot_ptr))).* = new_value;
        var dummy_prot: u32 = 0;
        const ok2 = VirtualProtect(slot_ptr, @sizeOf(usize), old_prot, &dummy_prot);
        if (ok2 == 0) {
            log.crit(
                "[iat] VirtualProtect(restore=0x{x}) FAILED for {s}!{s} slot=0x{x}",
                .{ old_prot, tag_dll, tag_func, @intFromPtr(slot_ptr) },
            );
        }
        log.info(
            "[iat] slot patched {s}!{s} addr=0x{x}: 0x{x} -> 0x{x} (oldProt=0x{x})",
            .{ tag_dll, tag_func, @intFromPtr(slot_ptr), old, new_value, old_prot },
        );
        return old;
    }

    pub fn patchImportThunk(
        self: *Self,
        target_base: [*]u8,
        import_dll: []const u8,
        import_func: []const u8,
        hook_addr: usize,
    ) !?usize {
        const dos: *align(1) const win.IMAGE_DOS_HEADER = @ptrCast(target_base);
        const nt_off: usize = @intCast(dos.e_lfanew);
        const nt: *align(1) const win.IMAGE_NT_HEADERS64 =
            @ptrCast(@alignCast(target_base[nt_off..]));
        if (nt.Signature != 0x4550) return null;
        const impdir = nt.OptionalHeader.DataDirectory[@intFromEnum(win.IMAGE_DIRECTORY_ENTRY_IMPORT)];
        if (impdir.Size == 0) return null;

        var desc: *align(1) const win.IMAGE_IMPORT_DESCRIPTOR =
            @ptrCast(@alignCast(target_base[impdir.VirtualAddress..]));
        while (desc.Name != 0) : (desc = @ptrFromInt(@intFromPtr(desc) + @sizeOf(win.IMAGE_IMPORT_DESCRIPTOR))) {
            const dll_name_z: [*:0]const u8 = @ptrCast(target_base[desc.Name..]);
            const dll_name = std.mem.sliceTo(dll_name_z, 0);
            if (!eqlIgnoreCaseAscii(dll_name, import_dll)) continue;

            var orig_thunk_rva: u32 = desc.Anonymous.OriginalFirstThunk;
            const thunk_rva: u32 = desc.FirstThunk;
            if (orig_thunk_rva == 0) orig_thunk_rva = thunk_rva;

            var orig: *align(1) win.IMAGE_THUNK_DATA64 =
                @ptrCast(@alignCast(target_base[orig_thunk_rva..]));
            var thunk: *align(1) win.IMAGE_THUNK_DATA64 =
                @ptrCast(@alignCast(target_base[thunk_rva..]));
            while (orig.u1.AddressOfData != 0) : ({
                thunk = @ptrFromInt(@intFromPtr(thunk) + @sizeOf(win.IMAGE_THUNK_DATA64));
                orig = @ptrFromInt(@intFromPtr(orig) + @sizeOf(win.IMAGE_THUNK_DATA64));
            }) {
                if (isOrdinalLookup64(orig.u1.AddressOfData)) continue;
                const ibn: *const win.IMAGE_IMPORT_BY_NAME =
                    @ptrCast(@alignCast(target_base[orig.u1.AddressOfData..]));
                const name_z: [*:0]const u8 = @ptrCast(&ibn.Name);
                const name = std.mem.sliceTo(name_z, 0);
                if (!std.mem.eql(u8, name, import_func)) continue;

                return self.writeProtectedSlot(
                    @ptrCast(thunk),
                    hook_addr,
                    import_dll,
                    import_func,
                );
            }
        }
        return null;
    }

    pub fn IMAGE_FIRST_SECTION(nt_headers: *align(1) const win.IMAGE_NT_HEADERS64) [*]const win.IMAGE_SECTION_HEADER {
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
                log.info("Starting DLLMain", .{});
                const dllmain_result = run(hinst, 1, null);
                log.info("Out of dllmain -> {}", .{dllmain_result});
            }
        }
    }

    /// Finalise a freshly mapped + import-resolved DLL: set up its static-TLS
    /// block, then immediately run its DllMain. Mirrors ntdll's depth-first
    /// `LdrpInitializeNode` ordering — by the time this returns, the DLL is
    /// fully usable, so the caller (its parent's import-resolution loop) can
    /// safely bind IAT slots against this DLL's exports knowing the underlying
    /// implementation has had its CSes / atexit table / etc. initialised.
    ///
    /// Map a single satellite PE file (`.mun` or `.mui`) data-only at `path`.
    /// Returns the mapped base + SizeOfImage on success, null tuple if the
    /// file isn't there or the parse failed. Callers should silently skip
    /// when the file doesn't exist — most DLLs don't ship every variant.
    ///
    /// Critical: handles BOTH PE32 (`Magic == 0x010B`) and PE32+ (`0x020B`).
    /// Modern Windows `.mun` files are deliberately PE32 (32-bit, Machine ==
    /// IMAGE_FILE_MACHINE_I386) so they're architecture-neutral resource
    /// containers reusable on x86 and x64. Going through the existing
    /// `MapSections` would mis-parse PE32 files because it assumes
    /// `IMAGE_NT_HEADERS64` (240-byte OptionalHeader) instead of the actual
    /// 224-byte PE32 OptionalHeader — pushing the section table 16 bytes
    /// past where it really is and corrupting `DataDirectory[2]`.
    ///
    /// We avoid that by parsing offsets manually — both PE32 and PE32+ have
    /// `SizeOfImage` / `SizeOfHeaders` at the same OptionalHeader offset
    /// (56 / 60), and the section table location is dictated by
    /// `FileHeader.SizeOfOptionalHeader`. Each section header is 40 bytes
    /// regardless of arch.
    fn mapSatelliteFile(self: *Self, path: [*:0]const u16) ?struct { base: [*]u8, size: usize } {
        const kernel32 = self.getDllByName("kernel32.dll") catch return null;
        const CreateFileW = kernel32.getProc(
            fn ([*:0]const u16, u32, u32, ?*win.SECURITY_ATTRIBUTES, u32, u32, ?*anyopaque) callconv(.winapi) *anyopaque,
            "CreateFileW",
        ) catch return null;
        const CloseHandle = kernel32.getProc(
            fn (*anyopaque) callconv(.winapi) c_int,
            "CloseHandle",
        ) catch return null;
        const GetFileSizeEx = kernel32.getProc(
            fn (*anyopaque, *i64) callconv(.winapi) c_int,
            "GetFileSizeEx",
        ) catch return null;
        const ReadFile = kernel32.getProc(
            fn (*anyopaque, [*]u8, u32, ?*u32, ?*win.OVERLAPPED) callconv(.winapi) c_int,
            "ReadFile",
        ) catch return null;

        const h = CreateFileW(path, GENERIC_READ, 1, null, OPEN_EXISTING, 0, null);
        if (h == win.INVALID_HANDLE_VALUE) return null;
        defer _ = CloseHandle(h);

        var size_i: i64 = 0;
        if (GetFileSizeEx(h, &size_i) <= 0) return null;
        const file_size: usize = @intCast(size_i);
        if (file_size < 0x100) return null;
        const file_bytes = self.Allocator.alloc(u8, file_size) catch return null;
        defer self.Allocator.free(file_bytes);
        var bytes_read: u32 = 0;
        if (ReadFile(h, file_bytes.ptr, @intCast(file_size), &bytes_read, null) == 0) return null;

        const fb = file_bytes;
        if (fb[0] != 'M' or fb[1] != 'Z') return null;
        const nt_off: usize = std.mem.readInt(u32, fb[60..64], .little);
        if (nt_off + 24 > file_size) return null;
        const sig: u32 = std.mem.readInt(u32, fb[nt_off..][0..4], .little);
        if (sig != 0x4550) return null;

        const fh_off = nt_off + 4;
        const num_sections: u16 = std.mem.readInt(u16, fb[fh_off + 2 ..][0..2], .little);
        const size_of_opt: u16 = std.mem.readInt(u16, fb[fh_off + 16 ..][0..2], .little);
        const opt_off = fh_off + 20;
        if (opt_off + size_of_opt > file_size) return null;
        // OptionalHeader Magic at opt_off (PE32 = 0x010B, PE32+ = 0x020B).
        const magic: u16 = std.mem.readInt(u16, fb[opt_off..][0..2], .little);
        if (magic != 0x010B and magic != 0x020B) return null;
        // SizeOfImage / SizeOfHeaders are at fixed offsets 56 / 60 in BOTH
        // PE32 and PE32+ optional headers (Microsoft kept them aligned).
        const size_of_image: u32 = std.mem.readInt(u32, fb[opt_off + 56 ..][0..4], .little);
        const size_of_headers: u32 = std.mem.readInt(u32, fb[opt_off + 60 ..][0..4], .little);
        if (size_of_image == 0 or size_of_image > 0x4000_0000) return null; // 1 GiB sanity
        if (size_of_headers > file_size) return null;

        const ntdll_dll = self.getDllByName("ntdll.dll") catch return null;
        const ZwAllocateVirtualMemory = ntdll_dll.getProc(
            fn (i64, *?[*]u8, usize, *usize, u32, u32) callconv(.winapi) c_int,
            "ZwAllocateVirtualMemory",
        ) catch return null;
        var base_dirty: ?[*]u8 = null;
        var alloc_size: usize = size_of_image;
        const status: c_int = ZwAllocateVirtualMemory(
            -1,
            &base_dirty,
            0,
            &alloc_size,
            MEM_RESERVE | MEM_COMMIT,
            PAGE_READWRITE,
        );
        if (status != 0 or base_dirty == null) return null;
        const base = base_dirty.?;
        std.mem.copyForwards(u8, base[0..size_of_headers], fb[0..size_of_headers]);

        // Section table starts at `opt_off + size_of_opt`. Each entry is 40
        // bytes (IMAGE_SECTION_HEADER, identical for PE32 and PE32+).
        const sec_off_base = opt_off + size_of_opt;
        var i: usize = 0;
        while (i < num_sections) : (i += 1) {
            const sh_off = sec_off_base + i * 40;
            if (sh_off + 40 > file_size) break;
            const sec_va: u32 = std.mem.readInt(u32, fb[sh_off + 12 ..][0..4], .little);
            const sec_raw_size: u32 = std.mem.readInt(u32, fb[sh_off + 16 ..][0..4], .little);
            const sec_raw_off: u32 = std.mem.readInt(u32, fb[sh_off + 20 ..][0..4], .little);
            if (sec_raw_size == 0) continue; // bss-style, nothing to copy
            if (@as(usize, sec_raw_off) + sec_raw_size > file_size) continue;
            if (@as(usize, sec_va) + sec_raw_size > size_of_image) continue;
            std.mem.copyForwards(
                u8,
                base[sec_va .. sec_va + sec_raw_size],
                fb[sec_raw_off .. sec_raw_off + sec_raw_size],
            );
        }
        return .{ .base = base, .size = size_of_image };
    }

    /// Get the user's default locale name (e.g. "en-US"). Writes UTF-16 into
    /// `buf` (excluding sentinel) and returns the length. On failure returns
    /// the literal "en-US" as the ultimate fallback (matches case 11 in
    /// ntdll's `LdrpSearchResourceSection_U` lang-fallback walk).
    fn getUserLocaleName(self: *Self, buf: []u16) usize {
        const fallback = std.unicode.utf8ToUtf16LeStringLiteral("en-US");
        const writeFallback = struct {
            fn run(b: []u16, src: []const u16) usize {
                const n = @min(src.len, b.len);
                @memcpy(b[0..n], src[0..n]);
                return n;
            }
        }.run;
        const kernel32 = self.getDllByName("kernel32.dll") catch return writeFallback(buf, fallback);
        const GetUserDefaultLocaleName = kernel32.getProc(
            fn ([*]u16, c_int) callconv(.winapi) c_int,
            "GetUserDefaultLocaleName",
        ) catch return writeFallback(buf, fallback);
        // GetUserDefaultLocaleName returns char count INCLUDING the trailing
        // null; truncate it.
        const written = GetUserDefaultLocaleName(buf.ptr, @intCast(buf.len));
        if (written <= 1) return writeFallback(buf, fallback);
        return @intCast(written - 1);
    }

    fn buildSatellitePath(
        self: *Self,
        dir: []const u16, // includes trailing \
        sub: []const u16, // e.g. "en-US" or "SystemResources" — NO trailing \
        basename: []const u16,
        ext: []const u16, // e.g. ".mun" or ".mui"
    ) ?[:0]u16 {
        const total = dir.len + sub.len + 1 + basename.len + ext.len;
        const buf = self.Allocator.allocSentinel(u16, total, 0) catch return null;
        var idx: usize = 0;
        @memcpy(buf[idx .. idx + dir.len], dir);
        idx += dir.len;
        @memcpy(buf[idx .. idx + sub.len], sub);
        idx += sub.len;
        buf[idx] = '\\';
        idx += 1;
        @memcpy(buf[idx .. idx + basename.len], basename);
        idx += basename.len;
        @memcpy(buf[idx .. idx + ext.len], ext);
        idx += ext.len;
        return buf;
    }

    pub fn loadMuiSatellite(self: *Self, dll_rec: *Dll) void {
        const full = dll_rec.Path.full.view();
        var last_sep: ?usize = null;
        var i: usize = full.len;
        while (i > 0) {
            i -= 1;
            const c = full[i];
            if (c == '\\' or c == '/') {
                last_sep = i;
                break;
            }
        }
        const sep = last_sep orelse return;
        const dir = full[0 .. sep + 1]; // includes trailing \
        const basename = full[sep + 1 ..];

        const sysres = std.unicode.utf8ToUtf16LeStringLiteral("SystemResources");
        const ext_mun = std.unicode.utf8ToUtf16LeStringLiteral(".mun");
        const ext_mui = std.unicode.utf8ToUtf16LeStringLiteral(".mui");
        var mun_loaded = false;
        if (self.buildSatellitePath(dir, sysres, basename, ext_mun)) |path| {
            defer self.Allocator.free(path);
            log.info16("[mun] try a) ", .{}, path);
            if (self.mapSatelliteFile(path.ptr)) |sat| {
                dll_rec.MunBase = sat.base;
                dll_rec.MunSize = sat.size;
                mun_loaded = true;
                log.info16("[mun] mapped SystemResources (a) for ", .{}, dll_rec.Path.short.view());
            }
        }
        if (!mun_loaded) {
            if (dir.len >= 2) {
                var j: usize = dir.len - 1; // points at trailing \
                if (j > 0) j -= 1;
                while (j > 0) : (j -= 1) {
                    const c = dir[j];
                    if (c == '\\' or c == '/') break;
                }
                if (j > 0) {
                    const parent_dir = dir[0 .. j + 1]; // includes trailing \
                    if (self.buildSatellitePath(parent_dir, sysres, basename, ext_mun)) |path| {
                        defer self.Allocator.free(path);
                        log.info16("[mun] try b) ", .{}, path);
                        if (self.mapSatelliteFile(path.ptr)) |sat| {
                            dll_rec.MunBase = sat.base;
                            dll_rec.MunSize = sat.size;
                            log.info16("[mun] mapped SystemResources (b) for ", .{}, dll_rec.Path.short.view());
                        }
                    }
                }
            }
        }

        var locale_buf: [85]u16 = undefined; // LOCALE_NAME_MAX_LENGTH
        const locale_len = self.getUserLocaleName(&locale_buf);
        if (self.buildSatellitePath(dir, locale_buf[0..locale_len], basename, ext_mui)) |path| {
            defer self.Allocator.free(path);
            if (self.mapSatelliteFile(path.ptr)) |sat| {
                dll_rec.MuiBase = sat.base;
                dll_rec.MuiSize = sat.size;
                log.info16("[mui] mapped satellite for ", .{}, dll_rec.Path.short.view());
            }
        }
    }

    fn preInitAndQueueDll(self: *Self, dll_rec: *Dll) !void {
        if (dll_rec.Initialized) return;
        dll_rec.Initialized = true;
        static_tls.ldrpHandleTlsData(self, dll_rec) catch |err| {
            log.crit("TLS pass failed for dll: {}", .{err});
        };
        try self.pending_dll_mains.append(self.Allocator, dll_rec);
    }

    pub fn runPendingDllMains(self: *Self, queue_start: usize) void {
        self.lockLoader();
        defer self.unlockLoader();

        while (self.pending_dll_mains.items.len > queue_start) {
            const dll_rec = self.pending_dll_mains.orderedRemove(queue_start);
            const dll_ctx = self.actctx_mgr.lookupDllContext(dll_rec.BaseAddr);
            const cookie = self.actctx_mgr.pushContext(dll_ctx);
            defer if (cookie) |c| self.actctx_mgr.popContext(c);
            self.ExecuteDll(dll_rec) catch |err| {
                log.crit16("ExecuteDll failed for ", .{}, dll_rec.Path.short.view());
                log.crit("  error: {}", .{err});
            };
        }
    }

    fn finalizeAndInitDll(self: *Self, dll_rec: *Dll) !void {
        if (dll_rec.Initialized) return;
        dll_rec.Initialized = true;
        static_tls.ldrpHandleTlsData(self, dll_rec) catch |err| {
            log.crit("TLS pass failed for dll: {}", .{err});
        };
        const dll_ctx = self.actctx_mgr.lookupDllContext(dll_rec.BaseAddr);
        const cookie = self.actctx_mgr.pushContext(dll_ctx);
        defer if (cookie) |c| self.actctx_mgr.popContext(c);
        try self.ExecuteDll(dll_rec);
    }

    pub fn ZLoadExe(self: *Self, libname16_: [:0]const u16) anyerror!?*Dll {
        var scope = log.pushEnum(logtags.RefLoad);
        defer scope.end();

        self.lockLoader();
        defer self.unlockLoader();

        var resolved = try OwnedZ16.fromU16(self.Allocator, libname16_);
        defer resolved.deinit();
        resolved.toUpperAsciiInPlace();

        var dllPath = (try self.getDllPaths(resolved.view())) orelse return null;
        dllPath.normalize();

        var dll_struct: *Dll = try self.Allocator.create(Dll);
        dll_struct.* = .{};
        dll_struct.Path = dllPath;

        var dll_size: usize = 0;
        const dll_bytes = try self.LoadDllInMemory(dllPath, &dll_size) orelse return null;
        defer self.Allocator.free(dll_bytes[0..dll_size]);

        var nt = try ResolveNtHeaders(dll_bytes);

        if (nt.FileHeader.Characteristics.DLL != 0) {
            log.crit("ZLoadExe: target is a DLL not an EXE", .{});
            return DllError.LoadFailed;
        }

        var delta: isize = 0;
        log.info16("Mapping: ", .{}, dll_struct.Path.short.z);
        const base = try self.MapSections(nt, dll_bytes, &delta);
        dll_struct.BaseAddr = base;
        nt = try ResolveNtHeaders(base);

        try ResolveRVA(base, nt, delta);
        try self.ResolveExports(dll_struct);
        self.actctx_mgr.registerExe(dll_struct.BaseAddr);
        try self.LoadedDlls.put(dllPath.shortKey(), dll_struct);

        try self.PatchExportTableLoaderStubs(dll_struct);
        try self.ResolveImportTable(base, nt, dllPath, dll_struct);
        try self.resolveExportForwarders(dll_struct);
        self.HostExeBase = base;

        log.info("[exe-drain] flushing {d} pending DllMains for EXE dep tree", .{
            self.pending_dll_mains.items.len,
        });
        self.runPendingDllMains(0);

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
                while (p[0]) |cb| : (p = p[1..]) _ = cb(
                    hinst,
                    win.DLL_PROCESS_ATTACH,
                    null,
                );
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

    fn makeDllPathFromName(self: *Self, name16: [:0]const u16) !*DllPath {
        var full_owned = try OwnedZ16.fromU16(self.Allocator, name16[0 .. name16.len + 1]);
        errdefer full_owned.deinit();
        var short_owned = try OwnedZ16.fromU16(self.Allocator, name16[0 .. name16.len + 1]);
        errdefer short_owned.deinit();
        var dp = try self.Allocator.create(DllPath);
        dp.* = .{ .full = full_owned, .short = short_owned };
        dp.normalize();
        return dp;
    }

    pub fn ZLoadLibraryFromMemory(
        self: *Self,
        dll_name16: [:0]const u16,
        bytes: []const u8,
    ) anyerror!?*Dll {
        var scope = log.pushEnum(logtags.RefLoad);
        defer scope.end();

        var resolved = try OwnedZ16.fromU16(self.Allocator, dll_name16[0 .. dll_name16.len + 1]);
        defer resolved.deinit();
        try resolved.canonicalUpperDll();

        if (apiset.ApiSetResolve(resolved.view(), &.{})) |host_z| {
            const host_sz: [:0]u16 = @ptrCast(host_z);
            try resolved.replaceWithZ16(host_sz);
            try resolved.canonicalUpperDll();
        }

        if (self.LoadedDlls.get(resolved.raw)) |d| return d;

        if (self.InFlight.contains(resolved.raw)) return null;
        try self.InFlight.put(resolved.raw, {});

        var dllPath = try self.makeDllPathFromName(resolved.view());
        errdefer {
            dllPath.deinit();
            self.Allocator.destroy(dllPath);
        }

        var dll_struct: *Dll = try self.Allocator.create(Dll);
        errdefer self.Allocator.destroy(dll_struct);
        dll_struct.* = .{};
        dll_struct.Path = dllPath;

        var nt = try ResolveNtHeaders(@constCast(bytes.ptr));
        var delta: isize = 0;

        log.info16("ZLoadLibraryFromMemory mapping: ", .{}, dllPath.short.z);
        const base = try self.MapSections(nt, @constCast(bytes.ptr), &delta);
        dll_struct.BaseAddr = base;
        nt = try ResolveNtHeaders(base);

        try ResolveRVA(base, nt, delta);
        try self.ResolveExports(dll_struct);
        try self.PatchExportTableLoaderStubs(dll_struct);
        try self.LoadedDlls.put(dllPath.shortKey(), dll_struct);

        const dll_ctx = self.actctx_mgr.registerDll(dll_struct.BaseAddr);
        const ctx_cookie = self.actctx_mgr.pushContext(dll_ctx);
        defer if (ctx_cookie) |c| self.actctx_mgr.popContext(c);

        self.ResolveImportTable(base, nt, dllPath, dll_struct) catch |e| {
            log.crit("ZLoadLibraryFromMemory: import resolution failed: {}", .{e});
            return e;
        };

        try self.resolveExportForwarders(dll_struct);
        try self.finalizeAndInitDll(dll_struct);
        _ = self.InFlight.remove(resolved.raw);

        return dll_struct;
    }

    pub fn ZLoadExeFromMemory(
        self: *Self,
        exe_name16: [:0]const u16,
        bytes: []const u8,
    ) anyerror!?*Dll {
        var scope = log.pushEnum(logtags.RefLoad);
        defer scope.end();

        var resolved = try OwnedZ16.fromU16(self.Allocator, exe_name16[0 .. exe_name16.len + 1]);
        defer resolved.deinit();
        resolved.toUpperAsciiInPlace();

        var nt = try ResolveNtHeaders(@constCast(bytes.ptr));
        if (nt.FileHeader.Characteristics.DLL != 0) {
            log.crit("ZLoadExeFromMemory: supplied image is a DLL, not an EXE", .{});
            return DllError.LoadFailed;
        }

        var dllPath = try self.makeDllPathFromName(resolved.view());
        errdefer {
            dllPath.deinit();
            self.Allocator.destroy(dllPath);
        }

        var dll_struct: *Dll = try self.Allocator.create(Dll);
        errdefer self.Allocator.destroy(dll_struct);
        dll_struct.* = .{};
        dll_struct.Path = dllPath;

        var delta: isize = 0;
        log.info16("ZLoadExeFromMemory mapping: ", .{}, dllPath.short.z);
        const base = try self.MapSections(nt, @constCast(bytes.ptr), &delta);
        dll_struct.BaseAddr = base;
        nt = try ResolveNtHeaders(base);

        try ResolveRVA(base, nt, delta);
        try self.ResolveExports(dll_struct);
        self.actctx_mgr.registerExe(dll_struct.BaseAddr);
        try self.LoadedDlls.put(dllPath.shortKey(), dll_struct);
        try self.PatchExportTableLoaderStubs(dll_struct);
        try self.ResolveImportTable(base, nt, dllPath, dll_struct);
        try self.resolveExportForwarders(dll_struct);
        self.HostExeBase = base;

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
                while (p[0]) |cb| : (p = p[1..]) _ = cb(
                    hinst,
                    win.DLL_PROCESS_ATTACH,
                    null,
                );
            }
        }

        log.info16("ZLoadExeFromMemory done -> ", .{}, dll_struct.Path.shortView());
        return dll_struct;
    }

    pub fn ZLoadLibrary(self: *Self, libname16_: [:0]const u16) anyerror!?*Dll {
        var scope = log.pushEnum(logtags.RefLoad);
        defer scope.end();

        self.lockLoader();
        defer self.unlockLoader();

        self.loading_depth += 1;
        log.info16("[zlib-enter] depth={d} queue_len={d} name=", .{
            self.loading_depth, self.pending_dll_mains.items.len,
        }, libname16_);
        defer {
            self.loading_depth -= 1;
            log.info16("[zlib-leave] depth={d} queue_len={d} name=", .{
                self.loading_depth, self.pending_dll_mains.items.len,
            }, libname16_);
        }

        var resolved = try OwnedZ16.fromU16(self.Allocator, libname16_);
        defer resolved.deinit();
        try resolved.canonicalUpperDll();

        if (apiset.ApiSetResolve(resolved.view(), &.{})) |host_z| {
            const host_sz: [:0]u16 = @ptrCast(host_z);
            try resolved.replaceWithZ16(host_sz);
            try resolved.canonicalUpperDll();
        }

        if (self.actctx_mgr.pushed_count == 0 and
            actctx.isInvalid(self.actctx_mgr.active_context))
        {
            if (self.LoadedDlls.get(resolved.raw)) |d| return d;
        }

        var dllPath = (try self.getDllPaths(resolved.view())) orelse return null;
        dllPath.normalize();
        const key = dllPath.shortKey();

        {
            var it = self.LoadedDlls.valueIterator();
            while (it.next()) |dll_pp| {
                const d = dll_pp.*;
                if (eqlIgnoreCaseW(d.Path.full.view(), dllPath.full.view())) {
                    dllPath.deinit();
                    self.Allocator.destroy(dllPath);
                    return d;
                }
            }
        }

        if (self.InFlight.contains(key)) {
            log.info16("ZLoadLibrary: re-entrant load skipped for ", .{}, dllPath.short.view());
            dllPath.deinit();
            self.Allocator.destroy(dllPath);
            return null;
        }
        try self.InFlight.put(key, {});

        var dll_struct_created = false;
        var loaded_dlls_inserted = false;
        var dll_struct: *Dll = undefined;
        var success = false;

        errdefer {
            if (!success) {
                if (loaded_dlls_inserted) _ = self.LoadedDlls.remove(dllPath.shortKey());
                _ = self.InFlight.remove(key);
                if (dll_struct_created) {
                    dll_struct.Path.deinit();
                    self.Allocator.destroy(dll_struct.Path);
                    self.Allocator.destroy(dll_struct);
                } else {
                    dllPath.deinit();
                    self.Allocator.destroy(dllPath);
                }
            }
        }

        dll_struct = try self.Allocator.create(Dll);
        dll_struct.* = .{};
        dll_struct.Path = dllPath;
        dll_struct_created = true;

        log.info16("starting to load {d}", .{dllPath.full.raw.len}, dllPath.full.raw);

        var dll_size: usize = 0;
        const dll_bytes = (try self.LoadDllInMemory(dllPath, &dll_size)) orelse {
            log.crit16("ZLoadLibrary: file load failed (LoadDllInMemory returned null) for ", .{}, dllPath.short.view());
            return error.LoadDllInMemoryFailed;
        };
        defer self.Allocator.free(dll_bytes[0..dll_size]);

        var nt = try ResolveNtHeaders(dll_bytes);
        var delta: isize = 0;
        const base = try self.MapSections(nt, dll_bytes, &delta);
        dll_struct.BaseAddr = base;
        nt = try ResolveNtHeaders(base);

        try ResolveRVA(base, nt, delta);
        try self.ResolveExports(dll_struct);
        try self.PatchExportTableLoaderStubs(dll_struct);
        try self.LoadedDlls.put(dllPath.shortKey(), dll_struct);
        loaded_dlls_inserted = true;

        const dll_ctx = self.actctx_mgr.registerDllByPath(dll_struct.BaseAddr, dllPath.full.z);
        const ctx_cookie = self.actctx_mgr.pushContext(dll_ctx);
        defer if (ctx_cookie) |c| self.actctx_mgr.popContext(c);

        self.loadMuiSatellite(dll_struct);

        self.ResolveImportTable(base, nt, dllPath, dll_struct) catch |e| {
            log.crit("Failed to resolve imports {}", .{e});
            return e;
        };

        _ = self.validateImportTable(base, nt, dll_struct);

        try self.resolveExportForwarders(dll_struct);
        try self.preInitAndQueueDll(dll_struct);
        _ = self.InFlight.remove(key);

        success = true;
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
