const std = @import("std");
const str = @import("u16str.zig");
const dll_mod = @import("dll.zig");

// ─────────────────────────────────────────────────────────────────────────────
// Minimal PE types needed for IAT patching and resource walking
// ─────────────────────────────────────────────────────────────────────────────

const ImageDosHeader = extern struct {
    e_magic: u16,
    e_cblp: u16,
    e_cp: u16,
    e_crlc: u16,
    e_cparhdr: u16,
    e_minalloc: u16,
    e_maxalloc: u16,
    e_ss: u16,
    e_sp: u16,
    e_csum: u16,
    e_ip: u16,
    e_cs: u16,
    e_lfarlc: u16,
    e_ovno: u16,
    e_res: [4]u16,
    e_oemid: u16,
    e_oeminfo: u16,
    e_res2: [10]u16,
    e_lfanew: i32,
};
const ImageFileHeader = extern struct {
    Machine: u16,
    NumberOfSections: u16,
    TimeDateStamp: u32,
    PointerToSymbolTable: u32,
    NumberOfSymbols: u32,
    SizeOfOptionalHeader: u16,
    Characteristics: u16,
};
const ImageOptionalHeader64 = extern struct {
    Magic: u16,
    MajorLinkerVersion: u8,
    MinorLinkerVersion: u8,
    SizeOfCode: u32,
    SizeOfInitializedData: u32,
    SizeOfUninitializedData: u32,
    AddressOfEntryPoint: u32,
    BaseOfCode: u32,
    ImageBase: u64,
    SectionAlignment: u32,
    FileAlignment: u32,
    MajorOperatingSystemVersion: u16,
    MinorOperatingSystemVersion: u16,
    MajorImageVersion: u16,
    MinorImageVersion: u16,
    MajorSubsystemVersion: u16,
    MinorSubsystemVersion: u16,
    Win32VersionValue: u32,
    SizeOfImage: u32,
    SizeOfHeaders: u32,
    CheckSum: u32,
    Subsystem: u16,
    DllCharacteristics: u16,
    SizeOfStackReserve: u64,
    SizeOfStackCommit: u64,
    SizeOfHeapReserve: u64,
    SizeOfHeapCommit: u64,
    LoaderFlags: u32,
    NumberOfRvaAndSizes: u32,
    // DataDirectory[16] follows in memory
};
const ImageNtHeaders64 = extern struct {
    Signature: u32,
    FileHeader: ImageFileHeader,
    OptionalHeader: ImageOptionalHeader64,
};
const ImageDataDirectory = extern struct { VirtualAddress: u32, Size: u32 };
const ImageImportDescriptor = extern struct {
    OriginalFirstThunk: u32,
    TimeDateStamp: u32,
    ForwarderChain: u32,
    Name: u32,
    FirstThunk: u32,
};
const ImageThunkData64 = extern struct { AddressOfData: u64 };
const ImageResourceDirectory = extern struct {
    Characteristics: u32,
    TimeDateStamp: u32,
    MajorVersion: u16,
    MinorVersion: u16,
    NumberOfNamedEntries: u16,
    NumberOfIdEntries: u16,
};
const ImageResourceDirectoryEntry = extern struct {
    NameOffsetOrId: u32,
    DataEntryOffset: u32,
};
const ImageResourceDataEntry = extern struct {
    OffsetToData: u32,
    Size: u32,
    CodePage: u32,
    Reserved: u32,
};

const DIR_IMPORT: usize = 1;
const DIR_RESOURCE: usize = 2;

fn ntHeaders(base: [*]u8) ?*align(1) const ImageNtHeaders64 {
    const dos: *align(1) const ImageDosHeader = @ptrCast(base);
    const nt: *align(1) const ImageNtHeaders64 =
        @ptrCast(@alignCast(base[@intCast(dos.e_lfanew)..]));
    if (nt.Signature != 0x4550) return null;
    return nt;
}

fn dataDir(base: [*]u8, index: usize) ?ImageDataDirectory {
    const nt = ntHeaders(base) orelse return null;
    const dirs: [*]align(1) const ImageDataDirectory =
        @ptrCast(@alignCast(
            @as([*]const u8, @ptrCast(&nt.OptionalHeader))[@sizeOf(ImageOptionalHeader64)..],
        ));
    const d = dirs[index];
    if (d.VirtualAddress == 0 or d.Size == 0) return null;
    return d;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public ACTCTXW
// ─────────────────────────────────────────────────────────────────────────────

pub const ACTCTXW = extern struct {
    cbSize: u32 = @sizeOf(ACTCTXW),
    dwFlags: u32 = 0,
    lpSource: ?[*:0]const u16 = null,
    wProcessorArchitecture: u16 = 0,
    wLangId: u16 = 0,
    lpAssemblyDirectory: ?[*:0]const u16 = null,
    lpResourceName: ?*anyopaque = null,
    lpApplicationName: ?[*:0]const u16 = null,
    hModule: ?*anyopaque = null,
};

const INVALID_HANDLE: usize = ~@as(usize, 0);
inline fn isInvalid(h: ?*anyopaque) bool {
    return h == null or @intFromPtr(h.?) == INVALID_HANDLE or @intFromPtr(h.?) == 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shadow stack
// ─────────────────────────────────────────────────────────────────────────────

const MAX_SHADOW = 128;
const ShadowEntry = struct { handle: ?*anyopaque, cookie: usize };
var g_shadow: [MAX_SHADOW]ShadowEntry = undefined;
var g_depth: usize = 0;

fn shadowPush(handle: ?*anyopaque, cookie: usize) void {
    if (g_depth >= MAX_SHADOW) return;
    g_shadow[g_depth] = .{ .handle = handle, .cookie = cookie };
    g_depth += 1;
}
fn shadowPop(cookie: usize) void {
    var i = g_depth;
    while (i > 0) {
        i -= 1;
        if (g_shadow[i].cookie == cookie) {
            var j = i;
            while (j + 1 < g_depth) : (j += 1) g_shadow[j] = g_shadow[j + 1];
            g_depth -= 1;
            return;
        }
    }
}
fn shadowTop() ?*anyopaque {
    return if (g_depth == 0) null else g_shadow[g_depth - 1].handle;
}

// ─────────────────────────────────────────────────────────────────────────────
// Global
// ─────────────────────────────────────────────────────────────────────────────

var g_mgr: *ActCtxManager = undefined;
var g_ready: bool = false;

// ─────────────────────────────────────────────────────────────────────────────
// ActCtxManager
// ─────────────────────────────────────────────────────────────────────────────

pub const ActCtxManager = struct {
    allocator: std.mem.Allocator,
    /// Handles we created — value is a ref count (always 1 at creation).
    /// Lets hooks distinguish our handles from alien ones.
    owned_handles: std.AutoHashMap(usize, void),
    /// Per-DLL provider contexts (resource ID 2).
    dll_contexts: std.AutoHashMap(usize, ?*anyopaque),
    /// Guest EXE application context (resource ID 1). May be null if no manifest.
    active_context: ?*anyopaque,
    /// Temp manifest files to delete on deinit.
    temp_files: std.ArrayList([:0]u16),
    real: RealFns,

    pub const RealFns = struct {
        // ── Win32 actctx (from kernelbase — avoids pre-resolved forwarders) ─
        CreateActCtxW: ?*const fn (*anyopaque) callconv(.winapi) ?*anyopaque = null,
        CreateActCtxA: ?*const fn (*anyopaque) callconv(.winapi) ?*anyopaque = null,
        ActivateActCtx: ?*const fn (?*anyopaque, *usize) callconv(.winapi) i32 = null,
        DeactivateActCtx: ?*const fn (u32, usize) callconv(.winapi) i32 = null,
        ReleaseActCtx: ?*const fn (?*anyopaque) callconv(.winapi) void = null,
        AddRefActCtx: ?*const fn (?*anyopaque) callconv(.winapi) void = null,
        GetCurrentActCtx: ?*const fn (*?*anyopaque) callconv(.winapi) i32 = null,
        FindActCtxSectionStringW: ?*const fn (u32, ?*const [16]u8, u32, [*:0]const u16, ?*anyopaque) callconv(.winapi) i32 = null,
        FindActCtxSectionStringA: ?*const fn (u32, ?*const [16]u8, u32, [*:0]const u8, ?*anyopaque) callconv(.winapi) i32 = null,
        FindActCtxSectionGuid: ?*const fn (u32, ?*const [16]u8, u32, *const [16]u8, ?*anyopaque) callconv(.winapi) i32 = null,
        QueryActCtxW: ?*const fn (u32, ?*anyopaque, ?*anyopaque, u32, ?*anyopaque, usize, ?*usize) callconv(.winapi) i32 = null,
        ZombifyActCtx: ?*const fn (?*anyopaque) callconv(.winapi) i32 = null,
        // ── ntdll ────────────────────────────────────────────────────────────
        RtlActivateActivationContext: ?*const fn (u32, ?*anyopaque, *usize) callconv(.winapi) i32 = null,
        RtlDeactivateActivationContext: ?*const fn (u32, usize) callconv(.winapi) void = null,
        RtlGetActiveActivationContext: ?*const fn (*?*anyopaque) callconv(.winapi) i32 = null,
        RtlReleaseActivationContext: ?*const fn (?*anyopaque) callconv(.winapi) void = null,
        RtlAddRefActivationContext: ?*const fn (?*anyopaque) callconv(.winapi) void = null,
        RtlCreateActivationContext: ?*const fn (u32, ?*anyopaque, u32, ?*anyopaque, ?*anyopaque, *?*anyopaque) callconv(.winapi) i32 = null,
        RtlFindActivationContextSectionString: ?*const fn (u32, ?*const [16]u8, u32, *anyopaque, ?*anyopaque) callconv(.winapi) i32 = null,
        RtlFindActivationContextSectionGuid: ?*const fn (u32, ?*const [16]u8, u32, *const [16]u8, ?*anyopaque) callconv(.winapi) i32 = null,
        RtlQueryInformationActivationContext: ?*const fn (u32, ?*anyopaque, ?*anyopaque, u32, ?*anyopaque, usize, ?*usize) callconv(.winapi) i32 = null,
        RtlQueryInformationActiveActivationContext: ?*const fn (u32, u32, ?*anyopaque, usize, ?*usize) callconv(.winapi) i32 = null,
        // ── file I/O for temp manifest extraction (from kernelbase) ─────────
        NtProtectVirtualMemory: ?*const fn (i64, *?[*]u8, *usize, u32, *u32) callconv(.winapi) i32 = null,
        GetTempPathW: ?*const fn (u32, [*:0]u16) callconv(.winapi) u32 = null,
        GetTempFileNameW: ?*const fn ([*:0]const u16, [*:0]const u16, u32, [*:0]u16) callconv(.winapi) u32 = null,
        CreateFileW: ?*const fn ([*:0]const u16, u32, u32, ?*anyopaque, u32, u32, ?*anyopaque) callconv(.winapi) ?*anyopaque = null,
        WriteFile: ?*const fn (?*anyopaque, [*]const u8, u32, ?*u32, ?*anyopaque) callconv(.winapi) i32 = null,
        CloseHandle: ?*const fn (?*anyopaque) callconv(.winapi) i32 = null,
        DeleteFileW: ?*const fn ([*:0]const u16) callconv(.winapi) i32 = null,
    };

    // ── lifecycle ─────────────────────────────────────────────────────────

    pub fn init(self: *ActCtxManager, allocator: std.mem.Allocator) !void {
        self.* = .{
            .allocator = allocator,
            .owned_handles = std.AutoHashMap(usize, void).init(allocator),
            .dll_contexts = std.AutoHashMap(usize, ?*anyopaque).init(allocator),
            .active_context = null,
            .temp_files = try std.ArrayList([:0]u16).initCapacity(allocator, 1),
            .real = .{},
        };
        g_mgr = self;
        g_ready = true;
    }

    pub fn deinit(self: *ActCtxManager) void {
        g_ready = false;
        const rel = self.real.ReleaseActCtx;
        var it = self.dll_contexts.valueIterator();
        while (it.next()) |hptr| {
            if (!isInvalid(hptr.*)) if (rel) |fn_| fn_(hptr.*);
        }
        self.dll_contexts.deinit();
        if (!isInvalid(self.active_context)) if (rel) |fn_| fn_(self.active_context);
        self.owned_handles.deinit();
        if (self.real.DeleteFileW) |del| {
            for (self.temp_files.items) |p| {
                _ = del(p.ptr);
                self.allocator.free(p);
            }
        }
        self.temp_files.deinit();
    }

    // ── setup ─────────────────────────────────────────────────────────────

    /// Snapshot real function pointers from unpatched export tables.
    ///
    /// k32   — kernel32.dll  (kept so patchFns can overwrite its export table)
    /// kbase — kernelbase.dll (real implementations; no forwarders)
    /// ntdll — ntdll.dll
    ///
    /// Must be called BEFORE resolveKnownForwarders — at init time kernel32's
    /// actctx export entries still contain raw forwarder strings, not pointers.
    pub fn captureRealFns(self: *ActCtxManager, k32: anytype, kbase: anytype, ntdll: anytype) void {
        _ = k32;
        const G = struct {
            fn get(comptime T: type, dll: anytype, name: []const u8) ?*const T {
                return dll.getProc(T, name) catch null;
            }
        };
        self.real.CreateActCtxW = G.get(fn (*anyopaque) callconv(.winapi) ?*anyopaque, kbase, "CreateActCtxW");
        self.real.CreateActCtxA = G.get(fn (*anyopaque) callconv(.winapi) ?*anyopaque, kbase, "CreateActCtxA");
        self.real.ActivateActCtx = G.get(fn (?*anyopaque, *usize) callconv(.winapi) i32, kbase, "ActivateActCtx");
        self.real.DeactivateActCtx = G.get(fn (u32, usize) callconv(.winapi) i32, kbase, "DeactivateActCtx");
        self.real.ReleaseActCtx = G.get(fn (?*anyopaque) callconv(.winapi) void, kbase, "ReleaseActCtx");
        self.real.AddRefActCtx = G.get(fn (?*anyopaque) callconv(.winapi) void, kbase, "AddRefActCtx");
        self.real.GetCurrentActCtx = G.get(fn (*?*anyopaque) callconv(.winapi) i32, kbase, "GetCurrentActCtx");
        self.real.FindActCtxSectionStringW = G.get(fn (u32, ?*const [16]u8, u32, [*:0]const u16, ?*anyopaque) callconv(.winapi) i32, kbase, "FindActCtxSectionStringW");
        self.real.FindActCtxSectionStringA = G.get(fn (u32, ?*const [16]u8, u32, [*:0]const u8, ?*anyopaque) callconv(.winapi) i32, kbase, "FindActCtxSectionStringA");
        self.real.FindActCtxSectionGuid = G.get(fn (u32, ?*const [16]u8, u32, *const [16]u8, ?*anyopaque) callconv(.winapi) i32, kbase, "FindActCtxSectionGuid");
        self.real.QueryActCtxW = G.get(fn (u32, ?*anyopaque, ?*anyopaque, u32, ?*anyopaque, usize, ?*usize) callconv(.winapi) i32, kbase, "QueryActCtxW");
        self.real.ZombifyActCtx = G.get(fn (?*anyopaque) callconv(.winapi) i32, kbase, "ZombifyActCtx");
        self.real.GetTempPathW = G.get(fn (u32, [*:0]u16) callconv(.winapi) u32, kbase, "GetTempPathW");
        self.real.GetTempFileNameW = G.get(fn ([*:0]const u16, [*:0]const u16, u32, [*:0]u16) callconv(.winapi) u32, kbase, "GetTempFileNameW");
        self.real.CreateFileW = G.get(fn ([*:0]const u16, u32, u32, ?*anyopaque, u32, u32, ?*anyopaque) callconv(.winapi) ?*anyopaque, kbase, "CreateFileW");
        self.real.WriteFile = G.get(fn (?*anyopaque, [*]const u8, u32, ?*u32, ?*anyopaque) callconv(.winapi) i32, kbase, "WriteFile");
        self.real.CloseHandle = G.get(fn (?*anyopaque) callconv(.winapi) i32, kbase, "CloseHandle");
        self.real.DeleteFileW = G.get(fn ([*:0]const u16) callconv(.winapi) i32, kbase, "DeleteFileW");
        self.real.RtlActivateActivationContext = G.get(fn (u32, ?*anyopaque, *usize) callconv(.winapi) i32, ntdll, "RtlActivateActivationContext");
        self.real.RtlDeactivateActivationContext = G.get(fn (u32, usize) callconv(.winapi) void, ntdll, "RtlDeactivateActivationContext");
        self.real.RtlGetActiveActivationContext = G.get(fn (*?*anyopaque) callconv(.winapi) i32, ntdll, "RtlGetActiveActivationContext");
        self.real.RtlReleaseActivationContext = G.get(fn (?*anyopaque) callconv(.winapi) void, ntdll, "RtlReleaseActivationContext");
        self.real.RtlAddRefActivationContext = G.get(fn (?*anyopaque) callconv(.winapi) void, ntdll, "RtlAddRefActivationContext");
        self.real.RtlCreateActivationContext = G.get(fn (u32, ?*anyopaque, u32, ?*anyopaque, ?*anyopaque, *?*anyopaque) callconv(.winapi) i32, ntdll, "RtlCreateActivationContext");
        self.real.RtlFindActivationContextSectionString = G.get(fn (u32, ?*const [16]u8, u32, *anyopaque, ?*anyopaque) callconv(.winapi) i32, ntdll, "RtlFindActivationContextSectionString");
        self.real.RtlFindActivationContextSectionGuid = G.get(fn (u32, ?*const [16]u8, u32, *const [16]u8, ?*anyopaque) callconv(.winapi) i32, ntdll, "RtlFindActivationContextSectionGuid");
        self.real.RtlQueryInformationActivationContext = G.get(fn (u32, ?*anyopaque, ?*anyopaque, u32, ?*anyopaque, usize, ?*usize) callconv(.winapi) i32, ntdll, "RtlQueryInformationActivationContext");
        self.real.RtlQueryInformationActiveActivationContext = G.get(fn (u32, u32, ?*anyopaque, usize, ?*usize) callconv(.winapi) i32, ntdll, "RtlQueryInformationActiveActivationContext");
        self.real.NtProtectVirtualMemory = G.get(fn (i64, *?[*]u8, *usize, u32, *u32) callconv(.winapi) i32, ntdll, "NtProtectVirtualMemory");
    }

    // ── owned handle tracking ─────────────────────────────────────────────

    fn trackHandle(self: *ActCtxManager, h: ?*anyopaque) void {
        if (!isInvalid(h)) self.owned_handles.put(@intFromPtr(h.?), {}) catch {};
    }

    pub fn isOwned(self: *ActCtxManager, h: ?*anyopaque) bool {
        if (isInvalid(h)) return false;
        return self.owned_handles.contains(@intFromPtr(h.?));
    }

    /// Create an activation context from a temp-file manifest and track the handle.
    /// Returns null if CreateActCtxW is unavailable or fails.
    fn createContext(self: *ActCtxManager, tmp_path: [:0]const u16) ?*anyopaque {
        const fn_create = self.real.CreateActCtxW orelse return null;
        var ctx = std.mem.zeroes(ACTCTXW);
        ctx.cbSize = @sizeOf(ACTCTXW);
        ctx.dwFlags = 0;
        ctx.lpSource = tmp_path.ptr;
        const h = fn_create(&ctx);
        if (isInvalid(h)) return null;
        self.trackHandle(h);
        return h;
    }

    // ── manifest extraction ───────────────────────────────────────────────

    /// Extract the raw manifest XML (RT_MANIFEST / type 24) for the given
    /// resource ID from a mapped PE image, write to a temp file, and return
    /// the heap-allocated path (stored in temp_files; freed by deinit).
    fn extractManifestToTempFile(self: *ActCtxManager, base: [*]u8, resource_id: u16) ?[:0]u16 {
        const rsrc = dataDir(base, DIR_RESOURCE) orelse return null;
        const res_base: [*]const u8 = @ptrCast(base[rsrc.VirtualAddress..]);

        // Level 1 — type directory, find RT_MANIFEST (24)
        const RT_MANIFEST: u32 = 24;
        const tdir: *align(1) const ImageResourceDirectory = @ptrCast(res_base);
        const tents: [*]align(1) const ImageResourceDirectoryEntry =
            @ptrCast(res_base[@sizeOf(ImageResourceDirectory)..]);
        var type_off: u32 = 0;
        for (0..@as(u32, tdir.NumberOfNamedEntries) + tdir.NumberOfIdEntries) |i| {
            const e = tents[i];
            if ((e.NameOffsetOrId & 0x8000_0000) != 0) continue;
            if ((e.NameOffsetOrId & 0xFFFF) != RT_MANIFEST) continue;
            if ((e.DataEntryOffset & 0x8000_0000) == 0) return null;
            type_off = e.DataEntryOffset & 0x7FFF_FFFF;
            break;
        }
        if (type_off == 0) return null;

        // Level 2 — id directory, find our resource_id
        const idir: *align(1) const ImageResourceDirectory = @ptrCast(res_base[type_off..]);
        const ients: [*]align(1) const ImageResourceDirectoryEntry =
            @ptrCast(res_base[type_off + @sizeOf(ImageResourceDirectory) ..]);
        var id_off: u32 = 0;
        for (0..@as(u32, idir.NumberOfNamedEntries) + idir.NumberOfIdEntries) |i| {
            const e = ients[i];
            if ((e.NameOffsetOrId & 0x8000_0000) != 0) continue;
            if ((e.NameOffsetOrId & 0xFFFF) != resource_id) continue;
            if ((e.DataEntryOffset & 0x8000_0000) == 0) return null;
            id_off = e.DataEntryOffset & 0x7FFF_FFFF;
            break;
        }
        if (id_off == 0) return null;

        // Level 3 — language directory, take first entry
        const ldir: *align(1) const ImageResourceDirectory = @ptrCast(res_base[id_off..]);
        const lents: [*]align(1) const ImageResourceDirectoryEntry =
            @ptrCast(res_base[id_off + @sizeOf(ImageResourceDirectory) ..]);
        if (ldir.NumberOfNamedEntries + ldir.NumberOfIdEntries == 0) return null;
        const data_off = lents[0].DataEntryOffset & 0x7FFF_FFFF;
        const de: *align(1) const ImageResourceDataEntry = @ptrCast(res_base[data_off..]);
        const manifest: []const u8 = base[de.OffsetToData..][0..de.Size];

        // Write to temp file
        const fn_tmppath = self.real.GetTempPathW orelse return null;
        const fn_tmpname = self.real.GetTempFileNameW orelse return null;
        const fn_create = self.real.CreateFileW orelse return null;
        const fn_write = self.real.WriteFile orelse return null;
        const fn_close = self.real.CloseHandle orelse return null;

        var tmp_dir: [512:0]u16 = std.mem.zeroes([512:0]u16);
        _ = fn_tmppath(511, &tmp_dir);

        const prefix = [4:0]u16{ 'z', 'l', 'd', 0 };
        var tmp_path: [512:0]u16 = std.mem.zeroes([512:0]u16);
        if (fn_tmpname(&tmp_dir, &prefix, 0, &tmp_path) == 0) return null;

        const h = fn_create(&tmp_path, 0x4000_0000, 0, null, 2, 0x100, null) orelse return null;
        if (@intFromPtr(h) == INVALID_HANDLE) return null;
        var written: u32 = 0;
        _ = fn_write(h, manifest.ptr, @intCast(manifest.len), &written, null);
        _ = fn_close(h);

        const path_len = std.mem.len(@as([*:0]const u16, &tmp_path));
        const out = self.allocator.allocSentinel(u16, path_len, 0) catch return null;
        @memcpy(out[0..path_len], tmp_path[0..path_len]);
        return out;
    }

    // ── per-image registration ────────────────────────────────────────────

    /// Register the guest EXE's application context (resource ID 1).
    /// Sets active_context; used by scopedActivate for all DllMain calls.
    /// If the EXE has no manifest, active_context stays null and DllMain
    /// runs under whatever context is already on the TEB (correct behaviour).
    pub fn registerExe(self: *ActCtxManager, base: [*]u8) void {
        const key = @intFromPtr(base);
        const tmp_path = self.extractManifestToTempFile(base, 1) orelse return;
        self.temp_files.append(self.allocator, tmp_path) catch {
            self.allocator.free(tmp_path);
            return;
        };
        const h = self.createContext(tmp_path) orelse return;
        if (!isInvalid(self.active_context))
            if (self.real.ReleaseActCtx) |fn_| fn_(self.active_context);
        self.active_context = h;
        self.dll_contexts.put(key, h) catch {};
    }

    /// Register a DLL's provider context (resource ID 2).
    /// For QueryActCtxW / FindActCtxSection queries only.
    pub fn registerDll(self: *ActCtxManager, base: [*]u8) void {
        const key = @intFromPtr(base);
        if (self.dll_contexts.contains(key)) return;
        const tmp_path = self.extractManifestToTempFile(base, 2) orelse {
            self.dll_contexts.put(key, null) catch {};
            return;
        };
        self.temp_files.append(self.allocator, tmp_path) catch {
            self.allocator.free(tmp_path);
            self.dll_contexts.put(key, null) catch {};
            return;
        };
        const h = self.createContext(tmp_path);
        self.dll_contexts.put(key, h) catch {};
    }

    fn replaceIatSlot(self: *ActCtxManager, slot: *align(4) usize, new_fn: usize) void {
        if (slot.* == new_fn) return;

        const protect = self.real.NtProtectVirtualMemory orelse return;
        var addr: ?[*]u8 = @ptrCast(slot);
        var sz: usize = @sizeOf(usize);
        var old_prot: u32 = 0;
        const PAGE_READWRITE: u32 = 0x04;
        if (protect(-1, @ptrCast(&addr), &sz, PAGE_READWRITE, &old_prot) != 0) return;
        slot.* = new_fn;
        _ = protect(-1, @ptrCast(&addr), &sz, old_prot, &old_prot);
    }

    pub fn safeWriteUsize(self: *ActCtxManager, ptr: *usize, value: usize) void {
        const protect = self.real.NtProtectVirtualMemory orelse return;
        var addr: ?[*]u8 = @ptrCast(ptr);
        var sz: usize = @sizeOf(usize);
        var old_prot: u32 = 0;
        const PAGE_READWRITE: u32 = 0x04;
        if (protect(-1, @ptrCast(&addr), &sz, PAGE_READWRITE, &old_prot) != 0) return;
        ptr.* = value;
        _ = protect(-1, @ptrCast(&addr), &sz, old_prot, &old_prot);
    }

    pub fn safeZeroBytes(self: *ActCtxManager, ptr: *anyopaque, len: usize) void {
        if (len == 0) return;
        const protect = self.real.NtProtectVirtualMemory orelse return;
        var addr: ?[*]u8 = @ptrCast(ptr);
        var sz: usize = len;
        var old_prot: u32 = 0;
        const PAGE_READWRITE: u32 = 0x04;
        if (protect(-1, @ptrCast(&addr), &sz, PAGE_READWRITE, &old_prot) != 0) return;
        @memset(@as([*]u8, @ptrCast(ptr))[0..len], 0);
        _ = protect(-1, @ptrCast(&addr), &sz, old_prot, &old_prot);
    }

    pub fn patchIat(self: *ActCtxManager, base: [*]u8) void {
        const imp_dir = dataDir(base, DIR_IMPORT) orelse return;
        var desc: *align(1) const ImageImportDescriptor =
            @ptrCast(@alignCast(base[imp_dir.VirtualAddress..]));

        while (desc.Name != 0) : (desc = @ptrFromInt(@intFromPtr(desc) + @sizeOf(ImageImportDescriptor))) {
            const thunk_rva = if (desc.FirstThunk != 0) desc.FirstThunk else continue;
            var thunk: *align(4) ImageThunkData64 =
                @ptrCast(@alignCast(base[thunk_rva..]));

            while (thunk.AddressOfData != 0) : (thunk = @ptrFromInt(@intFromPtr(thunk) + @sizeOf(ImageThunkData64))) {
                const slot: *align(4) usize = @ptrCast(thunk);
                const cur = slot.*;

                // Match against every real activation-context pointer we captured.
                // Cast function pointers to usize for comparison.
                inline for (comptime hookPairs()) |pair| {
                    const real_fn_ptr = @field(self.real, pair.real_field);
                    if (real_fn_ptr) |rfp| {
                        if (cur == @intFromPtr(rfp)) {
                            self.replaceIatSlot(slot, @intFromPtr(pair.hook_fn));
                        }
                    }
                }
            }
        }
    }

    /// IAT-patch all DLLs currently in LoadedDlls.
    /// Call after captureRealFns, before PatchExportTableLoaderStubs.
    pub fn patchIatAll(self: *ActCtxManager) void {
        var it = dll_mod.GLOBAL_DLL_LOADER.LoadedDlls.valueIterator();
        while (it.next()) |dll_ptr| {
            self.patchIat(dll_ptr.*.BaseAddr);
        }
    }

    // ── DllMain scoped activation ─────────────────────────────────────────

    /// Activate active_context (guest EXE manifest) for the duration of
    /// DllMain / TLS callbacks.  If active_context is null (EXE has no
    /// manifest), this is a no-op — the existing TEB context is used as-is,
    /// which is correct: InitCommonControlsEx works without a manifest when
    /// run normally, so we must not disturb the TEB context in that case.
    pub fn scopedActivate(self: *ActCtxManager, base: [*]u8) ScopedCtx {
        _ = base;
        const handle = self.active_context orelse return .{};
        if (isInvalid(handle)) return .{};
        const fn_act = self.real.ActivateActCtx orelse return .{};
        var cookie: usize = 0;
        if (fn_act(handle, &cookie) == 0) return .{};
        shadowPush(handle, cookie);
        return .{ .cookie = cookie, .active = true };
    }

    // ── effective handle resolution ───────────────────────────────────────

    /// Given a handle argument from a hook, return the handle to actually use:
    ///   • null / INVALID / 0  →  substitute active_context (or pass null)
    ///   • owned handle        →  use as-is (we created it; it's valid)
    ///   • alien handle        →  use as-is (let the real function handle it)
    pub fn effectiveHandle(self: *ActCtxManager, h: ?*anyopaque) ?*anyopaque {
        if (isInvalid(h)) return self.active_context orelse shadowTop() orelse h;
        return h;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Hook ↔ real-field pairing table (comptime)
// ─────────────────────────────────────────────────────────────────────────────

const HookPair = struct {
    real_field: []const u8,
    hook_fn: *const anyopaque,
};

fn hookPairs() []const HookPair {
    return &[_]HookPair{
        .{ .real_field = "ActivateActCtx", .hook_fn = @ptrCast(&ActivateActCtx_hook) },
        .{ .real_field = "DeactivateActCtx", .hook_fn = @ptrCast(&DeactivateActCtx_hook) },
        .{ .real_field = "GetCurrentActCtx", .hook_fn = @ptrCast(&GetCurrentActCtx_hook) },
        .{ .real_field = "ReleaseActCtx", .hook_fn = @ptrCast(&ReleaseActCtx_hook) },
        .{ .real_field = "AddRefActCtx", .hook_fn = @ptrCast(&AddRefActCtx_hook) },
        .{ .real_field = "CreateActCtxW", .hook_fn = @ptrCast(&CreateActCtxW_hook) },
        .{ .real_field = "CreateActCtxA", .hook_fn = @ptrCast(&CreateActCtxA_hook) },
        .{ .real_field = "FindActCtxSectionStringW", .hook_fn = @ptrCast(&FindActCtxSectionStringW_hook) },
        .{ .real_field = "FindActCtxSectionStringA", .hook_fn = @ptrCast(&FindActCtxSectionStringA_hook) },
        .{ .real_field = "FindActCtxSectionGuid", .hook_fn = @ptrCast(&FindActCtxSectionGuid_hook) },
        .{ .real_field = "QueryActCtxW", .hook_fn = @ptrCast(&QueryActCtxW_hook) },
        .{ .real_field = "ZombifyActCtx", .hook_fn = @ptrCast(&ZombifyActCtx_hook) },
        .{ .real_field = "RtlActivateActivationContext", .hook_fn = @ptrCast(&RtlActivateActivationContext_hook) },
        .{ .real_field = "RtlDeactivateActivationContext", .hook_fn = @ptrCast(&RtlDeactivateActivationContext_hook) },
        .{ .real_field = "RtlGetActiveActivationContext", .hook_fn = @ptrCast(&RtlGetActiveActivationContext_hook) },
        .{ .real_field = "RtlReleaseActivationContext", .hook_fn = @ptrCast(&RtlReleaseActivationContext_hook) },
        .{ .real_field = "RtlAddRefActivationContext", .hook_fn = @ptrCast(&RtlAddRefActivationContext_hook) },
        .{ .real_field = "RtlCreateActivationContext", .hook_fn = @ptrCast(&RtlCreateActivationContext_hook) },
        .{ .real_field = "RtlFindActivationContextSectionString", .hook_fn = @ptrCast(&RtlFindActivationContextSectionString_hook) },
        .{ .real_field = "RtlFindActivationContextSectionGuid", .hook_fn = @ptrCast(&RtlFindActivationContextSectionGuid_hook) },
        .{ .real_field = "RtlQueryInformationActivationContext", .hook_fn = @ptrCast(&RtlQueryInformationActivationContext_hook) },
        .{ .real_field = "RtlQueryInformationActiveActivationContext", .hook_fn = @ptrCast(&RtlQueryInformationActiveActivationContext_hook) },
    };
}

// ─────────────────────────────────────────────────────────────────────────────
// ScopedCtx
// ─────────────────────────────────────────────────────────────────────────────

pub const ScopedCtx = struct {
    cookie: usize = 0,
    active: bool = false,

    pub fn end(self: *ScopedCtx) void {
        if (!self.active) return;
        if (g_ready) {
            if (g_mgr.real.DeactivateActCtx) |fn_| _ = fn_(0, self.cookie);
        }
        shadowPop(self.cookie);
        self.active = false;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Hook stubs
// ─────────────────────────────────────────────────────────────────────────────

pub fn CreateActCtxW_hook(p: *anyopaque) callconv(.winapi) ?*anyopaque {
    if (!g_ready) return @ptrFromInt(INVALID_HANDLE);
    const h = (g_mgr.real.CreateActCtxW orelse return @ptrFromInt(INVALID_HANDLE))(p);
    g_mgr.trackHandle(h);
    return h;
}
pub fn CreateActCtxA_hook(p: *anyopaque) callconv(.winapi) ?*anyopaque {
    if (!g_ready) return @ptrFromInt(INVALID_HANDLE);
    const h = (g_mgr.real.CreateActCtxA orelse return @ptrFromInt(INVALID_HANDLE))(p);
    g_mgr.trackHandle(h);
    return h;
}
pub fn ActivateActCtx_hook(hActCtx: ?*anyopaque, lpCookie: *usize) callconv(.winapi) i32 {
    if (!g_ready) return 0;
    const fn_ = g_mgr.real.ActivateActCtx orelse return 0;
    const ok = fn_(hActCtx, lpCookie);
    if (ok != 0) shadowPush(hActCtx, lpCookie.*);
    return ok;
}
pub fn DeactivateActCtx_hook(dwFlags: u32, ulCookie: usize) callconv(.winapi) i32 {
    if (!g_ready) return 0;
    const fn_ = g_mgr.real.DeactivateActCtx orelse return 0;
    const ok = fn_(dwFlags, ulCookie);
    if (ok != 0) shadowPop(ulCookie);
    return ok;
}
pub fn GetCurrentActCtx_hook(lphActCtx: *?*anyopaque) callconv(.winapi) i32 {
    if (!g_ready) {
        g_mgr.safeWriteUsize(@ptrCast(lphActCtx), 0);
        return 0;
    }
    if (shadowTop()) |top| {
        g_mgr.safeWriteUsize(@ptrCast(lphActCtx), @intFromPtr(top));
        if (!isInvalid(top)) if (g_mgr.real.AddRefActCtx) |fn_| fn_(top);
        return 1;
    }
    if (g_mgr.real.GetCurrentActCtx) |fn_| return fn_(lphActCtx);
    g_mgr.safeWriteUsize(@ptrCast(lphActCtx), @intFromPtr(g_mgr.active_context));
    if (!isInvalid(g_mgr.active_context))
        if (g_mgr.real.AddRefActCtx) |fn_| fn_(g_mgr.active_context);
    return 1;
}
pub fn ReleaseActCtx_hook(h: ?*anyopaque) callconv(.winapi) void {
    if (g_ready) if (g_mgr.real.ReleaseActCtx) |fn_| fn_(h);
}
pub fn AddRefActCtx_hook(h: ?*anyopaque) callconv(.winapi) void {
    if (g_ready) if (g_mgr.real.AddRefActCtx) |fn_| fn_(h);
}
pub fn FindActCtxSectionStringW_hook(f: u32, g: ?*const [16]u8, s: u32, n: [*:0]const u16, r: ?*anyopaque) callconv(.winapi) i32 {
    if (!g_ready) return 0;
    return (g_mgr.real.FindActCtxSectionStringW orelse return 0)(f, g, s, n, r);
}
pub fn FindActCtxSectionStringA_hook(f: u32, g: ?*const [16]u8, s: u32, n: [*:0]const u8, r: ?*anyopaque) callconv(.winapi) i32 {
    if (!g_ready) return 0;
    return (g_mgr.real.FindActCtxSectionStringA orelse return 0)(f, g, s, n, r);
}
pub fn FindActCtxSectionGuid_hook(f: u32, g: ?*const [16]u8, s: u32, guid: *const [16]u8, r: ?*anyopaque) callconv(.winapi) i32 {
    if (!g_ready) return 0;
    return (g_mgr.real.FindActCtxSectionGuid orelse return 0)(f, g, s, guid, r);
}
pub fn QueryActCtxW_hook(dwFlags: u32, hActCtx: ?*anyopaque, pvSub: ?*anyopaque, cls: u32, pvBuf: ?*anyopaque, cbBuf: usize, pcbWritten: ?*usize) callconv(.winapi) i32 {
    if (!g_ready) return 0;
    const fn_ = g_mgr.real.QueryActCtxW orelse return 0;
    return fn_(dwFlags, g_mgr.effectiveHandle(hActCtx), pvSub, cls, pvBuf, cbBuf, pcbWritten);
}
pub fn ZombifyActCtx_hook(h: ?*anyopaque) callconv(.winapi) i32 {
    if (!g_ready) return 0;
    return (g_mgr.real.ZombifyActCtx orelse return 0)(h);
}
pub fn RtlActivateActivationContext_hook(Flags: u32, Ctx: ?*anyopaque, Cookie: *usize) callconv(.winapi) i32 {
    if (!g_ready) return @bitCast(@as(u32, 0xC000_0034));
    const fn_ = g_mgr.real.RtlActivateActivationContext orelse return @bitCast(@as(u32, 0xC000_0034));
    const status = fn_(Flags, Ctx, Cookie);
    if (status == 0) shadowPush(Ctx, Cookie.*);
    return status;
}
pub fn RtlDeactivateActivationContext_hook(Flags: u32, Cookie: usize) callconv(.winapi) void {
    if (!g_ready) return;
    if (g_mgr.real.RtlDeactivateActivationContext) |fn_| fn_(Flags, Cookie);
    shadowPop(Cookie);
}
pub fn RtlGetActiveActivationContext_hook(pCtx: *?*anyopaque) callconv(.winapi) i32 {
    // Fully in-house: return our managed context, never forward to ntdll.
    if (!g_ready) {
        g_mgr.safeWriteUsize(@ptrCast(pCtx), 0);
        return @bitCast(@as(u32, 0xC000_0034));
    }
    const ctx: ?*anyopaque = shadowTop() orelse g_mgr.active_context;
    g_mgr.safeWriteUsize(@ptrCast(pCtx), @intFromPtr(ctx));
    if (!isInvalid(ctx)) if (g_mgr.real.RtlAddRefActivationContext) |fn_| fn_(ctx);
    return 0; // STATUS_SUCCESS — even when ctx is null, match what ntdll does on empty TEB stack
}
pub fn RtlReleaseActivationContext_hook(h: ?*anyopaque) callconv(.winapi) void {
    if (g_ready) if (g_mgr.real.RtlReleaseActivationContext) |fn_| fn_(h);
}
pub fn RtlAddRefActivationContext_hook(h: ?*anyopaque) callconv(.winapi) void {
    if (g_ready) if (g_mgr.real.RtlAddRefActivationContext) |fn_| fn_(h);
}
pub fn RtlCreateActivationContext_hook(Flags: u32, Data: ?*anyopaque, Extra: u32, NR: ?*anyopaque, NC: ?*anyopaque, Ret: *?*anyopaque) callconv(.winapi) i32 {
    if (!g_ready) return @bitCast(@as(u32, 0xC000_0034));
    const fn_ = g_mgr.real.RtlCreateActivationContext orelse return @bitCast(@as(u32, 0xC000_0034));
    const status = fn_(Flags, Data, Extra, NR, NC, Ret);
    if (status == 0) g_mgr.trackHandle(Ret.*);
    return status;
}
pub fn RtlFindActivationContextSectionString_hook(Flags: u32, ExtGuid: ?*const [16]u8, SectionId: u32, StringToFind: *anyopaque, ReturnedData: ?*anyopaque) callconv(.winapi) i32 {
    if (!g_ready) return @bitCast(@as(u32, 0xC000_0034));
    return (g_mgr.real.RtlFindActivationContextSectionString orelse return @bitCast(@as(u32, 0xC000_0034)))(Flags, ExtGuid, SectionId, StringToFind, ReturnedData);
}
pub fn RtlFindActivationContextSectionGuid_hook(Flags: u32, ExtGuid: ?*const [16]u8, SectionId: u32, GuidToFind: *const [16]u8, ReturnedData: ?*anyopaque) callconv(.winapi) i32 {
    if (!g_ready) return @bitCast(@as(u32, 0xC000_0034));
    return (g_mgr.real.RtlFindActivationContextSectionGuid orelse return @bitCast(@as(u32, 0xC000_0034)))(Flags, ExtGuid, SectionId, GuidToFind, ReturnedData);
}
/// In-house query: never forward to ntdll.
/// If the caller passed a handle we own (created via CreateActCtxW from our
/// temp-file manifest), forward to the real function — it is a legitimate
/// kernel object and ntdll CAN answer it.
/// For null / invalid / alien handles (the common case from comctl32 etc.
/// when there is no active TEB context), answer ourselves:
///   • substitute active_context if we have one and it is owned, else
///   • zero the output buffer and return STATUS_SUCCESS so callers don't
///     interpret the missing-context condition as a hard error.
pub fn RtlQueryInformationActivationContext_hook(Flags: u32, Ctx: ?*anyopaque, SubIdx: ?*anyopaque, InfoClass: u32, Buf: ?*anyopaque, BufLen: usize, RetLen: ?*usize) callconv(.winapi) i32 {
    if (!g_ready) return @bitCast(@as(u32, 0xC000_0034));
    // Determine which context handle to use.
    const effective: ?*anyopaque = blk: {
        if (!isInvalid(Ctx)) break :blk Ctx; // caller supplied a real handle
        // null/invalid → use our active context if owned
        const ac = g_mgr.active_context orelse break :blk null;
        if (g_mgr.isOwned(ac)) break :blk ac;
        break :blk null;
    };
    if (!isInvalid(effective) and g_mgr.isOwned(effective)) {
        // Our owned handle — ntdll can answer this correctly.
        const fn_ = g_mgr.real.RtlQueryInformationActivationContext orelse
            return @bitCast(@as(u32, 0xC000_0034));
        return fn_(Flags, effective, SubIdx, InfoClass, Buf, BufLen, RetLen);
    }
    // No usable context: return success with zeroed/empty data.
    // Callers that check for success first (comctl32, ole32) will proceed
    // without treating an absent context as a fatal error.
    if (RetLen) |rl| g_mgr.safeWriteUsize(@ptrCast(rl), 0);
    if (Buf) |b| g_mgr.safeZeroBytes(b, BufLen);
    return 0; // STATUS_SUCCESS
}
/// Same policy for the "active context" variant — fully in-house, no ntdll call.
pub fn RtlQueryInformationActiveActivationContext_hook(Flags: u32, InfoClass: u32, Buf: ?*anyopaque, BufLen: usize, RetLen: ?*usize) callconv(.winapi) i32 {
    if (!g_ready) return @bitCast(@as(u32, 0xC000_0034));
    const ac = shadowTop() orelse g_mgr.active_context;
    if (!isInvalid(ac) and g_mgr.isOwned(ac)) {
        const fn_ = g_mgr.real.RtlQueryInformationActivationContext orelse
            return @bitCast(@as(u32, 0xC000_0034));
        return fn_(Flags, ac, null, InfoClass, Buf, BufLen, RetLen);
    }
    if (RetLen) |rl| g_mgr.safeWriteUsize(@ptrCast(rl), 0);
    if (Buf) |b| g_mgr.safeZeroBytes(b, BufLen);
    return 0; // STATUS_SUCCESS
}

// ─────────────────────────────────────────────────────────────────────────────
// patchFns — export-table patching for newly loaded DLLs
// ─────────────────────────────────────────────────────────────────────────────

pub fn patchFns(dll_rec: anytype) void {
    var tmp: [96]u8 = undefined;
    const t = str.toUpperTemp;
    if (dll_rec.NameExports.getPtr(t(&tmp, "CreateActCtxW"))) |vp| vp.* = @ptrCast(@constCast(&CreateActCtxW_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "CreateActCtxA"))) |vp| vp.* = @ptrCast(@constCast(&CreateActCtxA_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "ActivateActCtx"))) |vp| vp.* = @ptrCast(@constCast(&ActivateActCtx_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "DeactivateActCtx"))) |vp| vp.* = @ptrCast(@constCast(&DeactivateActCtx_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "GetCurrentActCtx"))) |vp| vp.* = @ptrCast(@constCast(&GetCurrentActCtx_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "ReleaseActCtx"))) |vp| vp.* = @ptrCast(@constCast(&ReleaseActCtx_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "AddRefActCtx"))) |vp| vp.* = @ptrCast(@constCast(&AddRefActCtx_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "FindActCtxSectionStringW"))) |vp| vp.* = @ptrCast(@constCast(&FindActCtxSectionStringW_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "FindActCtxSectionStringA"))) |vp| vp.* = @ptrCast(@constCast(&FindActCtxSectionStringA_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "FindActCtxSectionGuid"))) |vp| vp.* = @ptrCast(@constCast(&FindActCtxSectionGuid_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "QueryActCtxW"))) |vp| vp.* = @ptrCast(@constCast(&QueryActCtxW_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "ZombifyActCtx"))) |vp| vp.* = @ptrCast(@constCast(&ZombifyActCtx_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "RtlActivateActivationContext"))) |vp| vp.* = @ptrCast(@constCast(&RtlActivateActivationContext_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "RtlDeactivateActivationContext"))) |vp| vp.* = @ptrCast(@constCast(&RtlDeactivateActivationContext_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "RtlGetActiveActivationContext"))) |vp| vp.* = @ptrCast(@constCast(&RtlGetActiveActivationContext_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "RtlReleaseActivationContext"))) |vp| vp.* = @ptrCast(@constCast(&RtlReleaseActivationContext_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "RtlAddRefActivationContext"))) |vp| vp.* = @ptrCast(@constCast(&RtlAddRefActivationContext_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "RtlCreateActivationContext"))) |vp| vp.* = @ptrCast(@constCast(&RtlCreateActivationContext_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "RtlFindActivationContextSectionString"))) |vp| vp.* = @ptrCast(@constCast(&RtlFindActivationContextSectionString_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "RtlFindActivationContextSectionGuid"))) |vp| vp.* = @ptrCast(@constCast(&RtlFindActivationContextSectionGuid_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "RtlQueryInformationActivationContext"))) |vp| vp.* = @ptrCast(@constCast(&RtlQueryInformationActivationContext_hook));
    if (dll_rec.NameExports.getPtr(t(&tmp, "RtlQueryInformationActiveActivationContext"))) |vp| vp.* = @ptrCast(@constCast(&RtlQueryInformationActiveActivationContext_hook));
}
