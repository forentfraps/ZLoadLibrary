const std = @import("std");
const str = @import("u16str.zig");
const dll_mod = @import("dll.zig");
const log = &dll_mod.log;

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
};
const ImageNtHeaders64 = extern struct {
    Signature: u32,
    FileHeader: ImageFileHeader,
    OptionalHeader: ImageOptionalHeader64,
};
const ImageDataDirectory = extern struct { VirtualAddress: u32, Size: u32 };
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

const DIR_RESOURCE: usize = 2;

fn ntHeaders(base: [*]u8) ?*align(1) const ImageNtHeaders64 {
    const dos: *align(1) const ImageDosHeader = @ptrCast(base);
    const nt: *align(1) const ImageNtHeaders64 =
        @ptrCast(@alignCast(base[@intCast(dos.e_lfanew)..]));
    if (nt.Signature != 0x4550) return null;
    return nt;
}

fn dataDir(base: [*]u8, index: usize) ?ImageDataDirectory {
    const dos: *align(1) const ImageDosHeader = @ptrCast(base);
    const nt_off: usize = @intCast(dos.e_lfanew);
    const sig_ptr: *align(1) const u32 = @ptrCast(@alignCast(base[nt_off..]));
    if (sig_ptr.* != 0x4550) return null;
    const opt_off = nt_off + 4 + 20; // Signature(4) + FileHeader(20)
    const magic_ptr: *align(1) const u16 = @ptrCast(@alignCast(base[opt_off..]));
    const dd_base_off = opt_off + (if (magic_ptr.* == 0x010B) @as(usize, 96) else @as(usize, 112));
    const dd_ptr: *align(1) const ImageDataDirectory =
        @ptrCast(@alignCast(base[dd_base_off + index * 8 ..]));
    if (dd_ptr.VirtualAddress == 0 or dd_ptr.Size == 0) return null;
    return dd_ptr.*;
}

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

const UNICODE_STRING = extern struct {
    Length: u16,
    MaximumLength: u16,
    _pad: u32 = 0,
    Buffer: ?[*]u16,
};

const INVALID_HANDLE: usize = ~@as(usize, 0);
pub inline fn isInvalid(h: ?*anyopaque) bool {
    return h == null or @intFromPtr(h.?) == INVALID_HANDLE or @intFromPtr(h.?) == 0;
}

const STATUS_SUCCESS: u32 = 0x0000_0000;
const STATUS_SXS_SECTION_NOT_FOUND: u32 = 0xC015_0001;
const STATUS_SXS_CANT_GEN_ACTCTX: u32 = 0xC015_0002;
const STATUS_SXS_INVALID_ACTCTXDATA_FORMAT: u32 = 0xC015_0003;
const STATUS_SXS_ASSEMBLY_NOT_FOUND: u32 = 0xC015_0004;
const STATUS_SXS_MANIFEST_FORMAT_ERROR: u32 = 0xC015_0005;
const STATUS_SXS_MANIFEST_PARSE_ERROR: u32 = 0xC015_0006;
const STATUS_SXS_ACTIVATION_CONTEXT_DISABLED: u32 = 0xC015_0007;
const STATUS_SXS_KEY_NOT_FOUND: u32 = 0xC015_0008;
const STATUS_SXS_VERSION_CONFLICT: u32 = 0xC015_0009;
const STATUS_SXS_WRONG_SECTION_TYPE: u32 = 0xC015_000A;

fn ntStatusName(s: u32) []const u8 {
    return switch (s) {
        STATUS_SUCCESS => "STATUS_SUCCESS",
        STATUS_SXS_SECTION_NOT_FOUND => "STATUS_SXS_SECTION_NOT_FOUND",
        STATUS_SXS_CANT_GEN_ACTCTX => "STATUS_SXS_CANT_GEN_ACTCTX",
        STATUS_SXS_INVALID_ACTCTXDATA_FORMAT => "STATUS_SXS_INVALID_ACTCTXDATA_FORMAT",
        STATUS_SXS_ASSEMBLY_NOT_FOUND => "STATUS_SXS_ASSEMBLY_NOT_FOUND",
        STATUS_SXS_MANIFEST_FORMAT_ERROR => "STATUS_SXS_MANIFEST_FORMAT_ERROR",
        STATUS_SXS_MANIFEST_PARSE_ERROR => "STATUS_SXS_MANIFEST_PARSE_ERROR",
        STATUS_SXS_ACTIVATION_CONTEXT_DISABLED => "STATUS_SXS_ACTIVATION_CONTEXT_DISABLED",
        STATUS_SXS_KEY_NOT_FOUND => "STATUS_SXS_KEY_NOT_FOUND",
        STATUS_SXS_VERSION_CONFLICT => "STATUS_SXS_VERSION_CONFLICT",
        STATUS_SXS_WRONG_SECTION_TYPE => "STATUS_SXS_WRONG_SECTION_TYPE",
        else => "<unknown NTSTATUS>",
    };
}

fn deriveWinSxsManifestPath(allocator: std.mem.Allocator, dll_path: [:0]const u16) ?[:0]u16 {
    var seg_starts: [16]usize = undefined;
    var seg_count: usize = 0;
    seg_starts[0] = 0;
    seg_count = 1;
    for (dll_path, 0..) |c, i| {
        if (c == '\\' or c == '/') {
            if (seg_count >= seg_starts.len) return null;
            seg_starts[seg_count] = i + 1;
            seg_count += 1;
        }
    }
    if (seg_count < 4) return null; // need at least drive\winsxs\<assembly>\<file>

    const dll_seg_start = seg_starts[seg_count - 1];
    const asm_seg_start = seg_starts[seg_count - 2];
    const winsxs_seg_start = seg_starts[seg_count - 3];

    const winsxs_seg_end = asm_seg_start - 1; // one before backslash
    const winsxs = dll_path[winsxs_seg_start..winsxs_seg_end];
    if (winsxs.len != 6) return null;
    const W = "winsxs";
    for (winsxs, 0..) |c, i| {
        const lc: u16 = if (c >= 'A' and c <= 'Z') c + 32 else c;
        if (lc != @as(u16, W[i])) return null;
    }

    const asm_seg_end = dll_seg_start - 1;
    const asm_dir = dll_path[asm_seg_start..asm_seg_end];

    const root = dll_path[0..asm_seg_start]; // includes trailing "\"
    const suffix = ".manifest";
    const manifests = "Manifests\\";
    const total = root.len + manifests.len + asm_dir.len + suffix.len;
    const out = allocator.allocSentinel(u16, total, 0) catch return null;
    var idx: usize = 0;
    @memcpy(out[idx .. idx + root.len], root);
    idx += root.len;
    for (manifests) |c| {
        out[idx] = c;
        idx += 1;
    }
    @memcpy(out[idx .. idx + asm_dir.len], asm_dir);
    idx += asm_dir.len;
    for (suffix) |c| {
        out[idx] = c;
        idx += 1;
    }
    return out;
}

/// Scan a WinSxS path for the assembly version segment
/// (e.g. "_6.0.19041.4355_" or "_5.82.26100.8115_") and return the
/// "MAJOR.MINOR" prefix. Returns null if the path doesn't match the
/// WinSxS assembly-directory shape.
fn sxsVersionPrefix(path: []const u8) ?[]const u8 {
    // Look for "_<digit>." after a winsxs-style underscore segment.
    var i: usize = 0;
    while (i + 4 < path.len) : (i += 1) {
        if (path[i] != '_') continue;
        if (path[i + 1] < '0' or path[i + 1] > '9') continue;
        // Walk until the next '_' to extract the version segment.
        var j = i + 1;
        while (j < path.len and path[j] != '_') : (j += 1) {}
        if (j == path.len) continue;
        const seg = path[i + 1 .. j];
        // Has to look like N.N.N.N
        var dots: usize = 0;
        for (seg) |c| if (c == '.') {
            dots += 1;
        };
        if (dots == 3) {
            // Slice off "MAJOR.MINOR".
            var k: usize = 0;
            var dot_count: usize = 0;
            while (k < seg.len) : (k += 1) {
                if (seg[k] == '.') {
                    dot_count += 1;
                    if (dot_count == 2) return seg[0..k];
                }
            }
            return seg;
        }
    }
    return null;
}

pub const ActCtxManager = struct {
    allocator: std.mem.Allocator,
    active_context: ?*anyopaque = null,
    active_cookie: usize = 0,
    temp_files: std.ArrayList([:0]u16),
    dll_contexts: std.AutoHashMap(usize, ?*anyopaque) = undefined,

    pushed_count: usize = 0,
    real: RealFns,

    pub const RealFns = struct {
        CreateActCtxW: ?*const fn (*anyopaque) callconv(.winapi) ?*anyopaque = null,
        ActivateActCtx: ?*const fn (?*anyopaque, *usize) callconv(.winapi) i32 = null,
        DeactivateActCtx: ?*const fn (u32, usize) callconv(.winapi) i32 = null,
        ReleaseActCtx: ?*const fn (?*anyopaque) callconv(.winapi) void = null,
        RtlDosApplyFileIsolationRedirection_Ustr: ?*const fn (
            u32, // Flags (1 = redirect-only)
            *const UNICODE_STRING, // OriginalName
            ?*const UNICODE_STRING, // DefaultExtension
            ?*UNICODE_STRING, // StaticString
            *UNICODE_STRING, // DynamicString
            *?*UNICODE_STRING, // NewName (out: which buffer was used)
            ?*u32, // NewFlags (out)
            ?*usize, // FileNameSize (out)
            ?*usize, // RequiredLength (out)
        ) callconv(.winapi) i32 = null,
        RtlFreeUnicodeString: ?*const fn (*UNICODE_STRING) callconv(.winapi) void = null,
        GetLastError: ?*const fn () callconv(.winapi) u32 = null,
        GetTempPathW: ?*const fn (u32, [*:0]u16) callconv(.winapi) u32 = null,
        GetTempFileNameW: ?*const fn ([*:0]const u16, [*:0]const u16, u32, [*:0]u16) callconv(.winapi) u32 = null,
        CreateFileW: ?*const fn ([*:0]const u16, u32, u32, ?*anyopaque, u32, u32, ?*anyopaque) callconv(.winapi) ?*anyopaque = null,
        WriteFile: ?*const fn (?*anyopaque, [*]const u8, u32, ?*u32, ?*anyopaque) callconv(.winapi) i32 = null,
        CloseHandle: ?*const fn (?*anyopaque) callconv(.winapi) i32 = null,
        DeleteFileW: ?*const fn ([*:0]const u16) callconv(.winapi) i32 = null,
    };

    pub fn init(self: *ActCtxManager, allocator: std.mem.Allocator) !void {
        self.* = .{
            .allocator = allocator,
            .temp_files = try std.ArrayList([:0]u16).initCapacity(allocator, 1),
            .dll_contexts = std.AutoHashMap(usize, ?*anyopaque).init(allocator),
            .real = .{},
        };
    }

    pub fn deinit(self: *ActCtxManager) void {
        if (!isInvalid(self.active_context)) {
            if (self.active_cookie != 0) {
                if (self.real.DeactivateActCtx) |fn_| _ = fn_(0, self.active_cookie);
            }
            if (self.real.ReleaseActCtx) |fn_| fn_(self.active_context);
        }
        if (self.real.ReleaseActCtx) |rel| {
            var it = self.dll_contexts.valueIterator();
            while (it.next()) |hp| if (!isInvalid(hp.*)) rel(hp.*);
        }
        self.dll_contexts.deinit();
        if (self.real.DeleteFileW) |del| {
            for (self.temp_files.items) |p| {
                _ = del(p.ptr);
                self.allocator.free(p);
            }
        }
        self.temp_files.deinit();
    }

    pub fn captureRealFns(self: *ActCtxManager, kbase: anytype, ntdll: anytype) void {
        const G = struct {
            fn get(comptime T: type, dll: anytype, name: []const u8) ?*const T {
                return dll.getProc(T, name) catch null;
            }
        };
        self.real.CreateActCtxW = G.get(fn (*anyopaque) callconv(.winapi) ?*anyopaque, kbase, "CreateActCtxW");
        self.real.ActivateActCtx = G.get(fn (?*anyopaque, *usize) callconv(.winapi) i32, kbase, "ActivateActCtx");
        self.real.DeactivateActCtx = G.get(fn (u32, usize) callconv(.winapi) i32, kbase, "DeactivateActCtx");
        self.real.ReleaseActCtx = G.get(fn (?*anyopaque) callconv(.winapi) void, kbase, "ReleaseActCtx");
        self.real.GetTempPathW = G.get(fn (u32, [*:0]u16) callconv(.winapi) u32, kbase, "GetTempPathW");
        self.real.GetTempFileNameW = G.get(fn ([*:0]const u16, [*:0]const u16, u32, [*:0]u16) callconv(.winapi) u32, kbase, "GetTempFileNameW");
        self.real.CreateFileW = G.get(fn ([*:0]const u16, u32, u32, ?*anyopaque, u32, u32, ?*anyopaque) callconv(.winapi) ?*anyopaque, kbase, "CreateFileW");
        self.real.WriteFile = G.get(fn (?*anyopaque, [*]const u8, u32, ?*u32, ?*anyopaque) callconv(.winapi) i32, kbase, "WriteFile");
        self.real.CloseHandle = G.get(fn (?*anyopaque) callconv(.winapi) i32, kbase, "CloseHandle");
        self.real.DeleteFileW = G.get(fn ([*:0]const u16) callconv(.winapi) i32, kbase, "DeleteFileW");
        self.real.RtlDosApplyFileIsolationRedirection_Ustr = G.get(
            fn (
                u32,
                *const UNICODE_STRING,
                ?*const UNICODE_STRING,
                ?*UNICODE_STRING,
                *UNICODE_STRING,
                *?*UNICODE_STRING,
                ?*u32,
                ?*usize,
                ?*usize,
            ) callconv(.winapi) i32,
            ntdll,
            "RtlDosApplyFileIsolationRedirection_Ustr",
        );
        self.real.RtlFreeUnicodeString = G.get(fn (*UNICODE_STRING) callconv(.winapi) void, ntdll, "RtlFreeUnicodeString");
        self.real.GetLastError = G.get(fn () callconv(.winapi) u32, kbase, "GetLastError");

        if (g_real_LdrAccessResource == null) {
            g_real_LdrAccessResource = G.get(
                fn (?*anyopaque, ?*anyopaque, ?*?*anyopaque, ?*usize) callconv(.winapi) i32,
                ntdll,
                "LdrAccessResource",
            );
        }
        if (g_real_LoadResource == null) {
            g_real_LoadResource = G.get(
                fn (?*anyopaque, ?*anyopaque) callconv(.winapi) ?*anyopaque,
                kbase,
                "LoadResource",
            );
        }
        if (g_real_SizeofResource == null) {
            g_real_SizeofResource = G.get(
                fn (?*anyopaque, ?*anyopaque) callconv(.winapi) u32,
                kbase,
                "SizeofResource",
            );
        }
        if (g_real_LdrFindResource_U == null) {
            g_real_LdrFindResource_U = G.get(
                fn (?*anyopaque, *const LDR_RESOURCE_INFO, u32, *?*anyopaque) callconv(.winapi) i32,
                ntdll,
                "LdrFindResource_U",
            );
        }
    }

    fn extractManifestToTempFile(self: *ActCtxManager, base: [*]u8, resource_id: u16) ?[:0]u16 {
        const rsrc = dataDir(base, DIR_RESOURCE) orelse {
            log.crit("[reg] no resource directory in image base=0x{x}", .{@intFromPtr(base)});
            return null;
        };
        const res_base: [*]const u8 = @ptrCast(base[rsrc.VirtualAddress..]);

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
        if (type_off == 0) {
            log.crit("[reg] image base=0x{x} has no RT_MANIFEST type entry", .{@intFromPtr(base)});
            return null;
        }

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
        if (id_off == 0) {
            log.info("[reg] base=0x{x}: no manifest at resource id {d}", .{ @intFromPtr(base), resource_id });
            return null;
        }

        const ldir: *align(1) const ImageResourceDirectory = @ptrCast(res_base[id_off..]);
        const lents: [*]align(1) const ImageResourceDirectoryEntry =
            @ptrCast(res_base[id_off + @sizeOf(ImageResourceDirectory) ..]);
        if (ldir.NumberOfNamedEntries + ldir.NumberOfIdEntries == 0) return null;
        const data_off = lents[0].DataEntryOffset & 0x7FFF_FFFF;
        const de: *align(1) const ImageResourceDataEntry = @ptrCast(res_base[data_off..]);
        const manifest: []const u8 = base[de.OffsetToData..][0..de.Size];

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
        log.info16("[reg] manifest extracted (id={d}, {d} bytes) -> ", .{ resource_id, manifest.len }, out);

        const head_len: usize = @min(manifest.len, 384);
        log.info("[reg] manifest XML head ({d}/{d} bytes):\n{s}", .{
            head_len,
            manifest.len,
            manifest[0..head_len],
        });
        return out;
    }

    fn createContextFromImage(self: *ActCtxManager, base: [*]u8, resource_id: u16) ?*anyopaque {
        const tmp_path = self.extractManifestToTempFile(base, resource_id) orelse return null;
        self.temp_files.append(self.allocator, tmp_path) catch {
            self.allocator.free(tmp_path);
            return null;
        };
        const fn_create = self.real.CreateActCtxW orelse {
            log.crit("[reg] CreateActCtxW pointer not captured", .{});
            return null;
        };
        var ctx = std.mem.zeroes(ACTCTXW);
        ctx.cbSize = @sizeOf(ACTCTXW);
        ctx.lpSource = tmp_path.ptr;
        const h = fn_create(&ctx);
        if (isInvalid(h)) {
            log.crit16("[reg] CreateActCtxW returned INVALID_HANDLE for: ", .{}, tmp_path);
            return null;
        }
        log.info("[reg] CreateActCtxW ok (id={d}) -> handle 0x{x}", .{ resource_id, @intFromPtr(h) });
        return h;
    }

    pub fn registerExe(self: *ActCtxManager, base: [*]u8) void {
        const key = @intFromPtr(base);
        log.info("[reg] registerExe: base=0x{x}, probing embedded manifest ids 1,2,3", .{key});
        const h = blk: {
            for ([_]u16{ 1, 2, 3 }) |rid| {
                if (self.createContextFromImage(base, rid)) |h| break :blk h;
            }
            log.crit(
                "[reg] registerExe: NO embedded manifest in image base=0x{x}\n",
                .{key},
            );
            return;
        };
        const fn_act = self.real.ActivateActCtx orelse {
            log.crit("[reg] ActivateActCtx pointer not captured", .{});
            if (self.real.ReleaseActCtx) |rel| rel(h);
            return;
        };
        var cookie: usize = 0;
        if (fn_act(h, &cookie) == 0) {
            log.crit("[reg] ActivateActCtx FAILED for handle 0x{x}", .{@intFromPtr(h)});
            if (self.real.ReleaseActCtx) |rel| rel(h);
            return;
        }
        self.active_context = h;
        self.active_cookie = cookie;
        log.info("[reg] active_context = 0x{x}, cookie = 0x{x}", .{ @intFromPtr(h), cookie });
    }

    pub fn registerDll(self: *ActCtxManager, base: [*]u8) ?*anyopaque {
        const key = @intFromPtr(base);
        if (self.dll_contexts.get(key)) |cached| return cached;
        const h = self.createContextFromImage(base, 2);
        self.dll_contexts.put(key, h) catch {};
        if (h == null) {
            log.info("[reg] registerDll: base=0x{x} has no resource id 2 manifest", .{key});
        } else {
            log.info("[reg] registerDll: base=0x{x} -> handle 0x{x}", .{ key, @intFromPtr(h.?) });
        }
        return h;
    }
    pub fn registerDllByPath(
        self: *ActCtxManager,
        base: [*]u8,
        image_path: [:0]const u16,
    ) ?*anyopaque {
        const key = @intFromPtr(base);
        if (self.dll_contexts.get(key)) |cached| return cached;
        const fn_create = self.real.CreateActCtxW orelse {
            self.dll_contexts.put(key, null) catch {};
            return null;
        };

        var ctx = std.mem.zeroes(ACTCTXW);
        ctx.cbSize = @sizeOf(ACTCTXW);
        ctx.lpSource = image_path.ptr;
        const h = fn_create(&ctx);
        if (!isInvalid(h)) {
            self.dll_contexts.put(key, h) catch {};
            log.info16("[reg] registerDllByPath: CreateActCtxW(path) ok ", .{}, image_path);
            log.info("[reg]   handle = 0x{x}", .{@intFromPtr(h)});
            return h;
        }

        if (deriveWinSxsManifestPath(self.allocator, image_path)) |manifest_path| {
            defer self.allocator.free(manifest_path);
            var ctx2 = std.mem.zeroes(ACTCTXW);
            ctx2.cbSize = @sizeOf(ACTCTXW);
            ctx2.lpSource = manifest_path.ptr;
            const h2 = fn_create(&ctx2);
            if (!isInvalid(h2)) {
                self.dll_contexts.put(key, h2) catch {};
                log.info16("[reg] registerDllByPath: WinSxS manifest ok ", .{}, manifest_path);
                log.info("[reg]   handle = 0x{x}", .{@intFromPtr(h2)});
                return h2;
            }
            log.info16("[reg] registerDllByPath: WinSxS manifest FAILED ", .{}, manifest_path);
        }

        const h_embedded = self.createContextFromImage(base, 2);
        self.dll_contexts.put(key, h_embedded) catch {};
        if (h_embedded == null) {
            log.info16("[reg] registerDllByPath: no manifest (path/winsxs/embedded) for ", .{}, image_path);
        } else {
            log.info16("[reg] registerDllByPath: embedded id-2 fallback for ", .{}, image_path);
            log.info("[reg]   handle = 0x{x}", .{@intFromPtr(h_embedded.?)});
        }
        return h_embedded;
    }

    pub fn lookupDllContext(self: *ActCtxManager, base: [*]u8) ?*anyopaque {
        const key = @intFromPtr(base);
        return self.dll_contexts.get(key) orelse null;
    }

    pub fn pushContext(self: *ActCtxManager, h: ?*anyopaque) ?usize {
        if (isInvalid(h)) return null;
        const fn_act = self.real.ActivateActCtx orelse return null;
        var cookie: usize = 0;
        if (fn_act(h, &cookie) == 0) {
            log.crit("[ctx] ActivateActCtx FAILED for handle 0x{x}", .{@intFromPtr(h.?)});
            return null;
        }
        self.pushed_count +%= 1;
        return cookie;
    }

    pub fn popContext(self: *ActCtxManager, cookie: usize) void {
        if (self.real.DeactivateActCtx) |fn_| _ = fn_(0, cookie);
        if (self.pushed_count > 0) self.pushed_count -= 1;
    }

    pub fn resolveSxsPath(
        self: *ActCtxManager,
        allocator: std.mem.Allocator,
        bare_name: [:0]const u16,
    ) ?[:0]u16 {
        log.info16("[sxs] resolveSxsPath: ", .{}, bare_name);

        if (!isInvalid(self.active_context)) {
            log.info("[sxs] active_context = 0x{x}, cookie = 0x{x}", .{
                @intFromPtr(self.active_context),
                self.active_cookie,
            });
        } else {
            log.info("[sxs] no per-thread context — falling through to system default", .{});
        }

        const fn_apply = self.real.RtlDosApplyFileIsolationRedirection_Ustr orelse {
            log.crit("[sxs] RtlDosApplyFileIsolationRedirection_Ustr not captured", .{});
            return null;
        };

        const name_bytes: u16 = @intCast(bare_name.len * 2);
        const orig: UNICODE_STRING = .{
            .Length = name_bytes,
            .MaximumLength = name_bytes,
            .Buffer = @constCast(bare_name.ptr),
        };
        var dynamic: UNICODE_STRING = .{ .Length = 0, .MaximumLength = 0, .Buffer = null };
        var newp: ?*UNICODE_STRING = null;
        var new_flags: u32 = 0;
        const status = fn_apply(1, &orig, null, null, &dynamic, &newp, &new_flags, null, null);
        defer if (dynamic.Buffer != null) {
            if (self.real.RtlFreeUnicodeString) |fr| fr(&dynamic);
        };

        if (status != 0) {
            const ustatus: u32 = @bitCast(status);

            switch (ustatus) {
                STATUS_SXS_KEY_NOT_FOUND,
                STATUS_SXS_SECTION_NOT_FOUND,
                => log.info(
                    "[sxs] no manifest redirect ({s}) — falls through to PATH search",
                    .{ntStatusName(ustatus)},
                ),
                else => log.crit(
                    "[sxs] RtlDosApply…_Ustr FAILED status=0x{x} ({s}) new_flags=0x{x}",
                    .{ ustatus, ntStatusName(ustatus), new_flags },
                ),
            }
            return null;
        }
        if (newp == null) {
            log.crit("[sxs] RtlDosApply…_Ustr returned SUCCESS but NewName is null", .{});
            return null;
        }
        const result = newp.?;
        const buf = result.Buffer orelse {
            log.crit("[sxs] NewName.Buffer is null (Length={d})", .{result.Length});
            return null;
        };
        const chars: usize = result.Length / 2;
        if (chars == 0) {
            log.crit("[sxs] NewName.Length == 0", .{});
            return null;
        }

        const f_redirected = (new_flags & 0x01) != 0;
        const f_known = (new_flags & 0x02) != 0;
        const f_applied = (new_flags & 0x04) != 0;
        const f_default = (new_flags & 0x08) != 0;
        log.info(
            "[sxs] hit: chars={d} new_flags=0x{x} [redirected={} known_dll={} applied={} default_catalog={}]",
            .{ chars, new_flags, f_redirected, f_known, f_applied, f_default },
        );

        const out = allocator.allocSentinel(u16, chars, 0) catch {
            log.crit("[sxs] allocSentinel failed (chars={d})", .{chars});
            return null;
        };
        @memcpy(out[0..chars], buf[0..chars]);
        log.info16("[sxs] redirected to: ", .{}, out);

        var ascii: [768]u8 = undefined;
        const acopy = @min(chars, ascii.len);
        for (out[0..acopy], 0..) |c, i| ascii[i] = if (c < 0x80) @intCast(c) else '?';
        const ascii_path = ascii[0..acopy];
        if (sxsVersionPrefix(ascii_path)) |ver| {
            log.info("[sxs] resolved assembly version: {s}", .{ver});
        }
        return out;
    }
};

const INITCOMMONCONTROLSEX = extern struct { dwSize: u32, dwICC: u32 };
const WNDCLASSEXW = extern struct {
    cbSize: u32,
    style: u32,
    lpfnWndProc: ?*anyopaque,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: ?*anyopaque,
    hIcon: ?*anyopaque,
    hCursor: ?*anyopaque,
    hbrBackground: ?*anyopaque,
    lpszMenuName: ?[*:0]const u16,
    lpszClassName: ?[*:0]const u16,
    hIconSm: ?*anyopaque,
};

var g_real_InitCommonControlsEx: ?*const fn (*const INITCOMMONCONTROLSEX) callconv(.winapi) i32 = null;
var g_real_RegisterClassExW: ?*const fn (*const WNDCLASSEXW) callconv(.winapi) u16 = null;
var g_real_GetLastError: ?*const fn () callconv(.winapi) u32 = null;
var g_real_FreeLibraryWhenCallbackReturns: ?*const fn (?*anyopaque, ?[*]u8) callconv(.winapi) void = null;

inline fn tebSetLastError(v: u32) void {
    asm volatile (
        \\movl %[v], %%gs:0x68
        :
        : [v] "r" (v),
    );
}
inline fn tebGetLastError() u32 {
    return asm volatile (
        \\movl %%gs:0x68, %[ret]
        : [ret] "=r" (-> u32),
    );
}
var g_real_LdrGetDllHandleEx: ?*const fn (u32, ?[*:0]const u16, ?*const u32, *const UNICODE_STRING, *?*anyopaque) callconv(.winapi) i32 = null;
var g_real_LdrGetProcedureAddress: ?*const fn (?*anyopaque, ?*const UNICODE_STRING, u32, *?*anyopaque) callconv(.winapi) i32 = null;
var g_real_LdrLoadDll: ?*const fn (?[*:0]const u16, ?*u32, *const UNICODE_STRING, *?*anyopaque) callconv(.winapi) i32 = null;
var g_real_GetProcAddress: ?*const fn (?*anyopaque, [*:0]const u8) callconv(.winapi) ?*anyopaque = null;
var g_real_QueryActCtxW: ?*const fn (u32, ?*anyopaque, ?*anyopaque, u32, ?*anyopaque, usize, ?*usize) callconv(.winapi) i32 = null;
var g_real_RtlQueryInformationActivationContext: ?*const fn (u32, ?*anyopaque, ?*anyopaque, u32, ?*anyopaque, usize, ?*usize) callconv(.winapi) i32 = null;
var g_real_FindResourceW: ?*const fn (?*anyopaque, ?[*:0]const u16, ?[*:0]const u16) callconv(.winapi) ?*anyopaque = null;
var g_real_FindResourceExW: ?*const fn (?*anyopaque, ?[*:0]const u16, ?[*:0]const u16, u16) callconv(.winapi) ?*anyopaque = null;
const LDR_RESOURCE_INFO = extern struct { Type: usize, Name: usize, Language: usize };
var g_real_LdrFindResource_U: ?*const fn (?*anyopaque, *const LDR_RESOURCE_INFO, u32, *?*anyopaque) callconv(.winapi) i32 = null;
var g_real_LdrFindResourceEx_U: ?*const fn (u32, ?*anyopaque, *const LDR_RESOURCE_INFO, u32, *?*anyopaque) callconv(.winapi) i32 = null;
var g_real_LdrAccessResource: ?*const fn (?*anyopaque, ?*anyopaque, ?*?*anyopaque, ?*usize) callconv(.winapi) i32 = null;
var g_real_LoadResource: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.winapi) ?*anyopaque = null;
var g_real_SizeofResource: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.winapi) u32 = null;

fn className16To8(name_ptr: ?[*:0]const u16, buf: []u8) usize {
    const np = name_ptr orelse return 0;
    if (@intFromPtr(np) < 0x10000) return 0;
    var i: usize = 0;
    while (i + 1 < buf.len) : (i += 1) {
        const c = np[i];
        if (c == 0) break;
        buf[i] = if (c < 0x80) @intCast(c) else '?';
    }
    return i;
}

pub fn InitCommonControlsEx_hook(p: *const INITCOMMONCONTROLSEX) callconv(.winapi) i32 {
    const real = g_real_InitCommonControlsEx orelse return 0;
    log.info("[diag] InitCommonControlsEx ENTRY: dwSize={d} dwICC=0x{x}", .{ p.dwSize, p.dwICC });
    tebSetLastError(0);
    // asm volatile (".byte 0xcc");
    const r = real(p);
    const le = tebGetLastError();
    log.info("[diag] InitCommonControlsEx EXIT: returned={d} GetLastError=0x{x} (cleared to 0 before call)", .{ r, le });
    return r;
}

pub fn RegisterClassExW_hook(p: *const WNDCLASSEXW) callconv(.winapi) u16 {
    const real = g_real_RegisterClassExW orelse return 0;
    var name_buf: [128]u8 = undefined;
    const nlen = className16To8(p.lpszClassName, &name_buf);
    tebSetLastError(0);
    const r = real(p);
    const le = tebGetLastError();
    if (nlen > 0) {
        log.info(
            "[diag] RegisterClassExW: class=\"{s}\" hInstance=0x{x} -> atom=0x{x} lasterr=0x{x}",
            .{ name_buf[0..nlen], @intFromPtr(p.hInstance), r, le },
        );
    } else {
        log.info(
            "[diag] RegisterClassExW: class=<atom/null> hInstance=0x{x} -> atom=0x{x} lasterr=0x{x}",
            .{ @intFromPtr(p.hInstance), r, le },
        );
    }
    return r;
}

// No-op for our reflective DLLs to avoid 0xC000070E in TppCallbackEpilog (LdrUnloadDll on a base not in PEB.Ldr).
pub fn FreeLibraryWhenCallbackReturns_hook(
    instance: ?*anyopaque,
    hModule: ?[*]u8,
) callconv(.winapi) void {
    if (hModule) |base| {
        if (lookupOwningDllBase(@intFromPtr(base)) != null or
            lookupDllByBase(@intFromPtr(base)) != null)
        {
            log.info(
                "[ldr] FreeLibraryWhenCallbackReturns: NOOP for our DLL base=0x{x}",
                .{@intFromPtr(base)},
            );
            return;
        }
    }
    if (g_real_FreeLibraryWhenCallbackReturns) |real| {
        real(instance, hModule);
    }
}

fn ustrToAscii(us: ?*const UNICODE_STRING, buf: []u8) usize {
    const u = us orelse return 0;
    const ptr = u.Buffer orelse return 0;
    const chars: usize = @as(usize, u.Length) / 2;
    const n = @min(chars, buf.len);
    for (0..n) |i| buf[i] = if (ptr[i] < 0x80) @intCast(ptr[i]) else '?';
    return n;
}

fn cstrToAscii(p: ?[*:0]const u8, buf: []u8) usize {
    const ptr = p orelse return 0;
    var i: usize = 0;
    while (i < buf.len) : (i += 1) {
        const c = ptr[i];
        if (c == 0) break;
        buf[i] = c;
    }
    return i;
}

pub fn LdrGetDllHandleEx_hook(
    flags: u32,
    path: ?[*:0]const u16,
    sxs_flags: ?*const u32,
    name: *const UNICODE_STRING,
    out: *?*anyopaque,
) callconv(.winapi) i32 {
    var nbuf: [128]u8 = undefined;
    const nlen = ustrToAscii(name, &nbuf);
    const real = g_real_LdrGetDllHandleEx orelse return @bitCast(@as(u32, 0xC000_0135));
    const status = real(flags, path, sxs_flags, name, out);
    log.info(
        "[diag] LdrGetDllHandleEx: name=\"{s}\" flags=0x{x} -> status=0x{x} handle=0x{x}",
        .{ nbuf[0..nlen], flags, @as(u32, @bitCast(status)), @intFromPtr(out.*) },
    );
    return status;
}

pub fn LdrGetProcedureAddress_hook(
    module: ?*anyopaque,
    name: ?*const UNICODE_STRING,
    ord: u32,
    out: *?*anyopaque,
) callconv(.winapi) i32 {
    var nbuf: [128]u8 = undefined;
    const nlen = ustrToAscii(name, &nbuf);
    const real = g_real_LdrGetProcedureAddress orelse return @bitCast(@as(u32, 0xC000_0139));
    const status = real(module, name, ord, out);
    if (nlen > 0) {
        log.info(
            "[diag] LdrGetProcedureAddress: module=0x{x} name=\"{s}\" -> status=0x{x} addr=0x{x}",
            .{ @intFromPtr(module), nbuf[0..nlen], @as(u32, @bitCast(status)), @intFromPtr(out.*) },
        );
    } else {
        log.info(
            "[diag] LdrGetProcedureAddress: module=0x{x} ord={d} -> status=0x{x} addr=0x{x}",
            .{ @intFromPtr(module), ord, @as(u32, @bitCast(status)), @intFromPtr(out.*) },
        );
    }
    return status;
}

pub fn captureRealLdrLoadDllForRedirect(_: anytype) bool {
    return g_real_LdrLoadDll != null;
}

const STATUS_DLL_NOT_FOUND: u32 = 0xC000_0135;
const STATUS_INVALID_PARAMETER: u32 = 0xC000_000D;
const STATUS_NAME_TOO_LONG: u32 = 0xC000_0106;
const STATUS_RECURSIVE_DISPATCH: u32 = 0xC000_025C;

threadlocal var g_in_ldr_load_dll_hook: bool = false;

pub fn LdrLoadDll_hook(
    path: ?[*:0]const u16,
    flags: ?*u32,
    name: *const UNICODE_STRING,
    out: *?*anyopaque,
) callconv(.winapi) i32 {
    var nbuf: [256]u8 = undefined;
    const nlen = ustrToAscii(name, &nbuf);
    const flags_val: u32 = if (flags) |f| f.* else 0;

    const path_addr: usize = @intFromPtr(path);
    const path_is_real_ptr: bool = path_addr >= 0x10000;
    var pbuf: [128]u8 = undefined;
    var plen: usize = 0;
    if (path_is_real_ptr) {
        const p = @as([*:0]const u16, @ptrFromInt(path_addr));
        while (plen < pbuf.len) : (plen += 1) {
            const wc = p[plen];
            if (wc == 0) break;
            pbuf[plen] = if (wc < 0x80) @intCast(wc) else '?';
        }
    }

    log.info("[ldr] LdrLoadDll ENTRY name=\"{s}\" path=0x{x}{s}{s} flags=0x{x}", .{
        nbuf[0..nlen],
        path_addr,
        if (path_is_real_ptr) " text=\"" else "",
        if (path_is_real_ptr) pbuf[0..plen] else "",
        flags_val,
    });

    if (g_in_ldr_load_dll_hook) {
        log.crit(
            "[ldr] LdrLoadDll RECURSION REFUSED name=\"{s}\"",
            .{nbuf[0..nlen]},
        );
        out.* = null;
        return @bitCast(STATUS_RECURSIVE_DISPATCH);
    }

    const buf = name.Buffer orelse {
        log.crit("[ldr] LdrLoadDll FAIL: name.Buffer is null", .{});
        out.* = null;
        return @bitCast(STATUS_INVALID_PARAMETER);
    };
    const chars: usize = @as(usize, name.Length) / 2;
    if (chars == 0) {
        log.crit("[ldr] LdrLoadDll FAIL: name.Length is 0", .{});
        out.* = null;
        return @bitCast(STATUS_INVALID_PARAMETER);
    }

    var tmp: [520]u16 = undefined;
    if (chars + 1 > tmp.len) {
        log.crit("[ldr] LdrLoadDll FAIL: name length {d} > buffer {d}", .{ chars, tmp.len });
        out.* = null;
        return @bitCast(STATUS_NAME_TOO_LONG);
    }

    if (path_is_real_ptr) {
        log.info("[ldr] LdrLoadDll path-pinned (path=\"{s}\")", .{pbuf[0..plen]});
    } else if (path_addr != 0) {
        log.info("[ldr] LdrLoadDll path sentinel 0x{x}", .{path_addr});
    }

    g_in_ldr_load_dll_hook = true;
    defer g_in_ldr_load_dll_hook = false;

    @memcpy(tmp[0..chars], buf[0..chars]);
    tmp[chars] = 0;
    const name_z: [:0]u16 = tmp[0..chars :0];

    const self = &dll_mod.GLOBAL_DLL_LOADER;
    self.lockLoader();
    defer self.unlockLoader();
    const queue_start = self.pending_dll_mains.items.len;
    const z_result = self.ZLoadLibrary(name_z);
    defer self.runPendingDllMains(queue_start);

    if (z_result) |maybe_dll| {
        if (maybe_dll) |dll| {
            out.* = @ptrCast(dll.BaseAddr);
            log.info("[ldr] LdrLoadDll OK name=\"{s}\" base=0x{x}", .{
                nbuf[0..nlen], @intFromPtr(dll.BaseAddr),
            });
            return 0;
        } else {
            log.crit(
                "[ldr] LdrLoadDll FAIL name=\"{s}\" ZLoadLibrary returned null",
                .{nbuf[0..nlen]},
            );
            out.* = null;
            return @bitCast(STATUS_DLL_NOT_FOUND);
        }
    } else |err| {
        log.crit(
            "[ldr] LdrLoadDll FAIL name=\"{s}\" error: {s}",
            .{ nbuf[0..nlen], @errorName(err) },
        );
        out.* = null;
        return @bitCast(STATUS_DLL_NOT_FOUND);
    }
}

fn queryInfoClassName(c: u32) []const u8 {
    return switch (c) {
        1 => "ActivationContextBasicInformation",
        2 => "ActivationContextDetailedInformation",
        3 => "AssemblyDetailedInformationInActivationContext",
        4 => "FileInformationInAssemblyOfAssemblyInActivationContext",
        5 => "RunlevelInformationInActivationContext",
        6 => "CompatibilityInformationInActivationContext",
        7 => "ActivationContextManifestResourceName",
        else => "<unknown InfoClass>",
    };
}

fn lookupOwningDllBase(addr: usize) ?[*]u8 {
    var it = dll_mod.GLOBAL_DLL_LOADER.LoadedDlls.valueIterator();
    while (it.next()) |dll_pp| {
        const d = dll_pp.*;
        const base = @intFromPtr(d.BaseAddr);
        // Read SizeOfImage from the in-memory NT headers for this DLL.
        const dos: *align(1) const ImageDosHeader = @ptrCast(d.BaseAddr);
        const nt_off: usize = @intCast(dos.e_lfanew);
        const nt: *align(1) const ImageNtHeaders64 =
            @ptrCast(@alignCast(d.BaseAddr[nt_off..]));
        if (nt.Signature != 0x4550) continue;
        const size_of_image: usize = nt.OptionalHeader.SizeOfImage;
        if (addr >= base and addr < base + size_of_image) return d.BaseAddr;
    }
    return null;
}

const IMG_RES_DIR = extern struct {
    Characteristics: u32,
    TimeDateStamp: u32,
    MajorVersion: u16,
    MinorVersion: u16,
    NumberOfNamedEntries: u16,
    NumberOfIdEntries: u16,
};
const IMG_RES_DIR_ENTRY = extern struct {
    Name: u32,
    OffsetToData: u32,
};

fn dumpResourceTree(base: [*]u8, label: []const u8) void {
    const rsrc = dataDir(base, DIR_RESOURCE) orelse {
        log.info("[walk] {s}: no resource directory", .{label});
        return;
    };
    const root_addr: usize = @intFromPtr(base) + rsrc.VirtualAddress;
    const root: *align(1) const IMG_RES_DIR = @ptrFromInt(root_addr);
    const total_types: usize = @as(usize, root.NumberOfNamedEntries) + @as(usize, root.NumberOfIdEntries);
    log.info("[walk] {s}: {d} type entries (named={d} id={d})", .{
        label, total_types, root.NumberOfNamedEntries, root.NumberOfIdEntries,
    });
    const type_entries: [*]align(1) const IMG_RES_DIR_ENTRY =
        @ptrFromInt(root_addr + @sizeOf(IMG_RES_DIR));
    var i: usize = 0;
    while (i < total_types and i < 64) : (i += 1) {
        const e = type_entries[i];
        const id_or_off = e.Name & 0x7FFFFFFF;
        const is_string_type = (e.Name & 0x80000000) != 0;
        if ((e.OffsetToData & 0x80000000) == 0) continue; // unexpected — leaf at type level
        const sub_off = e.OffsetToData & 0x7FFFFFFF;
        const name_dir: *align(1) const IMG_RES_DIR = @ptrFromInt(root_addr + sub_off);
        const total_names: usize = @as(usize, name_dir.NumberOfNamedEntries) + @as(usize, name_dir.NumberOfIdEntries);
        if (is_string_type) {
            log.info("[walk] {s}: type=<str@0x{x}> ({d} names)", .{ label, id_or_off, total_names });
        } else {
            log.info("[walk] {s}: type=#{d} ({d} names)", .{ label, id_or_off, total_names });
        }
        const name_entries: [*]align(1) const IMG_RES_DIR_ENTRY =
            @ptrFromInt(@intFromPtr(name_dir) + @sizeOf(IMG_RES_DIR));
        var j: usize = 0;
        while (j < total_names and j < 96) : (j += 1) {
            const ne = name_entries[j];
            const ne_id = ne.Name & 0x7FFFFFFF;
            if ((ne.Name & 0x80000000) != 0) {
                log.info("[walk]   {s}: name=<str@0x{x}>", .{ label, ne_id });
            } else {
                log.info("[walk]   {s}: name=#{d}", .{ label, ne_id });
            }
        }
    }
}

var g_walked_bases: [16]usize = .{0} ** 16;
var g_walked_n: usize = 0;
fn alreadyDumped(base: usize) bool {
    var i: usize = 0;
    while (i < g_walked_n) : (i += 1) if (g_walked_bases[i] == base) return true;
    if (g_walked_n < g_walked_bases.len) {
        g_walked_bases[g_walked_n] = base;
        g_walked_n += 1;
    }
    return false;
}

fn lookupDllByBase(base: usize) ?*dll_mod.Dll {
    var it = dll_mod.GLOBAL_DLL_LOADER.LoadedDlls.valueIterator();
    while (it.next()) |dll_pp| {
        const d = dll_pp.*;
        if (@intFromPtr(d.BaseAddr) == base) return d;
    }
    return null;
}

fn lookupOwningImageBase(addr: usize) ?[*]u8 {
    var it = dll_mod.GLOBAL_DLL_LOADER.LoadedDlls.valueIterator();
    while (it.next()) |dll_pp| {
        const d = dll_pp.*;
        // Main image range.
        const main_base = @intFromPtr(d.BaseAddr);
        const dos: *align(1) const ImageDosHeader = @ptrCast(d.BaseAddr);
        const nt_off: usize = @intCast(dos.e_lfanew);
        const nt: *align(1) const ImageNtHeaders64 =
            @ptrCast(@alignCast(d.BaseAddr[nt_off..]));
        if (nt.Signature == 0x4550) {
            const main_size: usize = nt.OptionalHeader.SizeOfImage;
            if (addr >= main_base and addr < main_base + main_size) return d.BaseAddr;
        }
        // Satellite image ranges (.mui localized strings, .mun
        // language-neutral resources).
        if (d.MuiBase) |mb| {
            const mui_base = @intFromPtr(mb);
            if (d.MuiSize != 0 and addr >= mui_base and addr < mui_base + d.MuiSize) return mb;
        }
        if (d.MunBase) |mb| {
            const mun_base = @intFromPtr(mb);
            if (d.MunSize != 0 and addr >= mun_base and addr < mun_base + d.MunSize) return mb;
        }
    }
    return null;
}

fn lookupDllShortNameByBase(base: usize, buf: []u8) usize {
    var it = dll_mod.GLOBAL_DLL_LOADER.LoadedDlls.valueIterator();
    while (it.next()) |dll_pp| {
        const d = dll_pp.*;
        if (@intFromPtr(d.BaseAddr) != base) continue;
        const v = d.Path.short.view();
        var i: usize = 0;
        while (i + 1 < buf.len and i < v.len) : (i += 1) {
            const c = v[i];
            buf[i] = if (c < 0x80) @intCast(c) else '?';
        }
        return i;
    }
    return 0;
}

pub fn QueryActCtxW_hook(
    dwFlags: u32,
    hActCtx: ?*anyopaque,
    pvSubInstance: ?*anyopaque,
    ulInfoClass: u32,
    pvBuffer: ?*anyopaque,
    cbBuffer: usize,
    pcbWrittenOrRequired: ?*usize,
) callconv(.winapi) i32 {
    const real = g_real_QueryActCtxW orelse return 0;

    const QUERY_ACTCTX_FLAG_ACTCTX_IS_HMODULE: u32 = 0x0000_0008;
    const QUERY_ACTCTX_FLAG_ACTCTX_IS_ADDRESS: u32 = 0x0000_0010;
    const HMODULE_OR_ADDRESS_MASK: u32 = QUERY_ACTCTX_FLAG_ACTCTX_IS_HMODULE | QUERY_ACTCTX_FLAG_ACTCTX_IS_ADDRESS;

    var eff_flags = dwFlags;
    var eff_handle = hActCtx;
    if ((dwFlags & HMODULE_OR_ADDRESS_MASK) != 0) {
        if (hActCtx) |h| {
            const h_addr: usize = @intFromPtr(h);
            const mgr = &dll_mod.GLOBAL_DLL_LOADER.actctx_mgr;
            const owning_base: ?usize = blk: {
                if ((dwFlags & QUERY_ACTCTX_FLAG_ACTCTX_IS_HMODULE) != 0) {
                    if (mgr.dll_contexts.contains(h_addr)) break :blk h_addr;
                    break :blk null;
                }
                // ACTCTX_IS_ADDRESS — find which loaded DLL owns this address.
                if (lookupOwningDllBase(h_addr)) |bp| break :blk @intFromPtr(bp);
                break :blk null;
            };
            if (owning_base) |base| {
                if (mgr.dll_contexts.get(base)) |maybe_ctx| {
                    if (maybe_ctx) |our_ctx| {
                        log.info(
                            "[diag] QueryActCtxW: TRANSLATE HMODULE/ADDR 0x{x} (DLL base 0x{x}) -> our actctx 0x{x}",
                            .{ h_addr, base, @intFromPtr(our_ctx) },
                        );
                        eff_flags = dwFlags & ~HMODULE_OR_ADDRESS_MASK;
                        eff_handle = our_ctx;
                    } else {
                        log.info(
                            "[diag] QueryActCtxW: HMODULE/ADDR 0x{x} (DLL base 0x{x}) maps to NULL actctx — passing through",
                            .{ h_addr, base },
                        );
                    }
                }
            } else {
                log.info(
                    "[diag] QueryActCtxW: HMODULE/ADDR 0x{x} not in our LoadedDlls — passing through unchanged",
                    .{h_addr},
                );
            }
        }
    }

    const sub_val: usize = if (pvSubInstance) |p| @intFromPtr(p) else 0;
    log.info(
        "[diag] QueryActCtxW ENTRY: flags 0x{x}->0x{x} hActCtx 0x{x}->0x{x} sub=0x{x} class={d} ({s}) cb={d}",
        .{
            dwFlags,
            eff_flags,
            @intFromPtr(hActCtx),
            @intFromPtr(eff_handle),
            sub_val,
            ulInfoClass,
            queryInfoClassName(ulInfoClass),
            cbBuffer,
        },
    );
    tebSetLastError(0);
    const r = real(eff_flags, eff_handle, pvSubInstance, ulInfoClass, pvBuffer, cbBuffer, pcbWrittenOrRequired);
    const le = tebGetLastError();
    const written: usize = if (pcbWrittenOrRequired) |p| p.* else 0;
    log.info(
        "[diag] QueryActCtxW EXIT:  returned={d} GetLastError=0x{x} written/required={d}",
        .{ r, le, written },
    );
    return r;
}

pub fn RtlQueryInformationActivationContext_hook(
    dwFlags: u32,
    hActCtx: ?*anyopaque,
    pvSubInstance: ?*anyopaque,
    ulInfoClass: u32,
    pvBuffer: ?*anyopaque,
    cbBuffer: usize,
    pcbWrittenOrRequired: ?*usize,
) callconv(.winapi) i32 {
    const real = g_real_RtlQueryInformationActivationContext orelse
        return @bitCast(@as(u32, 0xC000_0008)); // STATUS_INVALID_HANDLE
    const QUERY_ACTCTX_FLAG_ACTCTX_IS_HMODULE: u32 = 0x0000_0008;
    const QUERY_ACTCTX_FLAG_ACTCTX_IS_ADDRESS: u32 = 0x0000_0010;
    const HMODULE_OR_ADDRESS_MASK: u32 = QUERY_ACTCTX_FLAG_ACTCTX_IS_HMODULE | QUERY_ACTCTX_FLAG_ACTCTX_IS_ADDRESS;

    var eff_flags = dwFlags;
    var eff_handle = hActCtx;
    if ((dwFlags & HMODULE_OR_ADDRESS_MASK) != 0) {
        if (hActCtx) |h| {
            const h_addr: usize = @intFromPtr(h);
            const mgr = &dll_mod.GLOBAL_DLL_LOADER.actctx_mgr;
            const owning_base: ?usize = blk: {
                if ((dwFlags & QUERY_ACTCTX_FLAG_ACTCTX_IS_HMODULE) != 0) {
                    if (mgr.dll_contexts.contains(h_addr)) break :blk h_addr;
                    break :blk null;
                }
                if (lookupOwningDllBase(h_addr)) |bp| break :blk @intFromPtr(bp);
                break :blk null;
            };
            if (owning_base) |base| {
                if (mgr.dll_contexts.get(base)) |maybe_ctx| {
                    if (maybe_ctx) |our_ctx| {
                        eff_flags = dwFlags & ~HMODULE_OR_ADDRESS_MASK;
                        eff_handle = our_ctx;
                        log.info(
                            "[diag] RtlQueryInformationActivationContext: TRANSLATE 0x{x}/base 0x{x} -> our actctx 0x{x}",
                            .{ h_addr, base, @intFromPtr(our_ctx) },
                        );
                    }
                }
            }
        }
    }

    const status = real(eff_flags, eff_handle, pvSubInstance, ulInfoClass, pvBuffer, cbBuffer, pcbWrittenOrRequired);
    const written: usize = if (pcbWrittenOrRequired) |p| p.* else 0;
    log.info(
        "[diag] RtlQueryInformationActivationContext: flags 0x{x}->0x{x} class={d} ({s}) cb={d} -> status=0x{x} written/req={d}",
        .{
            dwFlags,
            eff_flags,
            ulInfoClass,
            queryInfoClassName(ulInfoClass),
            cbBuffer,
            @as(u32, @bitCast(status)),
            written,
        },
    );
    return status;
}

fn formatResNameOrId(v: usize, buf: []u8) usize {
    if (v == 0) {
        const s = "<null>";
        const n = @min(s.len, buf.len);
        @memcpy(buf[0..n], s[0..n]);
        return n;
    }
    if (v < 0x10000) {
        // Well-known RT_* IDs from winuser.h / winres.h
        const id: u16 = @intCast(v & 0xFFFF);
        const known: ?[]const u8 = switch (id) {
            1 => "RT_CURSOR",
            2 => "RT_BITMAP",
            3 => "RT_ICON",
            4 => "RT_MENU",
            5 => "RT_DIALOG",
            6 => "RT_STRING",
            7 => "RT_FONTDIR",
            8 => "RT_FONT",
            9 => "RT_ACCELERATOR",
            10 => "RT_RCDATA",
            11 => "RT_MESSAGETABLE",
            12 => "RT_GROUP_CURSOR",
            14 => "RT_GROUP_ICON",
            16 => "RT_VERSION",
            17 => "RT_DLGINCLUDE",
            19 => "RT_PLUGPLAY",
            20 => "RT_VXD",
            21 => "RT_ANICURSOR",
            22 => "RT_ANIICON",
            23 => "RT_HTML",
            24 => "RT_MANIFEST",
            else => null,
        };
        if (known) |k| {
            const n = @min(k.len, buf.len);
            @memcpy(buf[0..n], k);
            return n;
        }
        const slice = std.fmt.bufPrint(buf, "#{d}", .{id}) catch return 0;
        return slice.len;
    }

    if ((v & 1) != 0) {
        const s = "<misaligned>";
        const n = @min(s.len, buf.len);
        @memcpy(buf[0..n], s[0..n]);
        return n;
    }
    const ptr: [*:0]const u16 = @ptrFromInt(v);
    var i: usize = 0;
    while (i + 1 < buf.len) : (i += 1) {
        const c = ptr[i];
        if (c == 0) break;
        buf[i] = if (c < 0x80) @intCast(c) else '?';
    }
    return i;
}

pub fn FindResourceExW_hook(
    hModule: ?*anyopaque,
    lpType: ?[*:0]const u16,
    lpName: ?[*:0]const u16,
    wLanguage: u16,
) callconv(.winapi) ?*anyopaque {
    const real = g_real_FindResourceExW orelse return null;
    var tbuf: [64]u8 = undefined;
    var nbuf: [128]u8 = undefined;
    var modbuf: [64]u8 = undefined;
    const tlen = formatResNameOrId(@intFromPtr(lpType), &tbuf);
    const nlen = formatResNameOrId(@intFromPtr(lpName), &nbuf);
    const modlen = lookupDllShortNameByBase(@intFromPtr(hModule), &modbuf);
    tebSetLastError(0);
    const r = real(hModule, lpType, lpName, wLanguage);
    const le = tebGetLastError();
    log.info(
        "[diag] FindResourceExW: hModule=0x{x} ({s}) type={s} name={s} lang=0x{x} -> 0x{x} lasterr=0x{x}",
        .{ @intFromPtr(hModule), modbuf[0..modlen], tbuf[0..tlen], nbuf[0..nlen], wLanguage, @intFromPtr(r), le },
    );

    if (r == null and g_real_LdrFindResourceEx_U != null and hModule != null) {
        if (lookupDllByBase(@intFromPtr(hModule))) |d| {
            if (!alreadyDumped(@intFromPtr(hModule))) {
                var buf: [80]u8 = undefined;
                const lbl = std.fmt.bufPrint(&buf, "BASE 0x{x} ({s})", .{ @intFromPtr(hModule), modbuf[0..modlen] }) catch buf[0..0];
                dumpResourceTree(@as([*]u8, @ptrCast(hModule.?)), lbl);
            }
            if (d.MunBase) |mb| {
                if (!alreadyDumped(@intFromPtr(mb))) {
                    var buf: [80]u8 = undefined;
                    const lbl = std.fmt.bufPrint(&buf, "MUN  0x{x} ({s})", .{ @intFromPtr(mb), modbuf[0..modlen] }) catch buf[0..0];
                    dumpResourceTree(mb, lbl);
                }
            }
            if (d.MuiBase) |mb| {
                if (!alreadyDumped(@intFromPtr(mb))) {
                    var buf: [80]u8 = undefined;
                    const lbl = std.fmt.bufPrint(&buf, "MUI  0x{x} ({s})", .{ @intFromPtr(mb), modbuf[0..modlen] }) catch buf[0..0];
                    dumpResourceTree(mb, lbl);
                }
            }
            // Flag 0x80000 inhibits LdrpSearchResourceSection_U's built-in MUI
            // fallback (which would re-trigger the same PEB.Ldr lookup that
            // already failed). Without this we'd recurse into the broken path.
            const NO_MUI: u32 = 0x80000;
            // 0xF2EE (-3346) is the MUN language sentinel — confirmed by ntdll
            // disassembly of LdrpLoadResourceFromAlternativeModule: when the
            // 0x1000000 flag selects the .mun branch, n3072_4 is hardcoded to
            // -3346 and stored into info.Language before LdrpSearchResourceSection_U.
            // .mun files store ALL resources under this single language.
            const MUN_LANG: u16 = 0xF2EE;
            const langs = [_]u16{ wLanguage, 0x0409, 0x09, 0 };
            var seen: [4]u16 = .{ 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF };
            var seen_n: usize = 0;

            // Try the BASE first (resource may live there at a lang we
            // weren't asked for; modern comdlg32 still ships English
            // RT_DIALOG entries in the base under 0x0409).
            for (langs) |lang| {
                var dup = false;
                for (seen[0..seen_n]) |s| if (s == lang) {
                    dup = true;
                    break;
                };
                if (dup) continue;
                seen[seen_n] = lang;
                seen_n += 1;
                const info = LDR_RESOURCE_INFO{
                    .Type = @intFromPtr(lpType),
                    .Name = @intFromPtr(lpName),
                    .Language = lang,
                };
                var out: ?*anyopaque = null;
                const status = g_real_LdrFindResourceEx_U.?(NO_MUI, hModule, &info, 3, &out);
                log.info(
                    "[mui]   probe BASE   lang=0x{x} -> status=0x{x} entry=0x{x}",
                    .{ lang, @as(u32, @bitCast(status)), @intFromPtr(out) },
                );
                if (status >= 0 and out != null) {
                    log.info("[mui] FindResourceExW satisfied from BASE at lang=0x{x}", .{lang});
                    return out;
                }
            }

            if (d.MunBase) |mun_base| {
                const mun_langs = [_]u16{ MUN_LANG, 0, wLanguage, 0x0409 };
                var mun_seen: [4]u16 = .{ 0xFFFE, 0xFFFE, 0xFFFE, 0xFFFE };
                var mun_seen_n: usize = 0;
                for (mun_langs) |lang| {
                    var dup = false;
                    for (mun_seen[0..mun_seen_n]) |s| if (s == lang) {
                        dup = true;
                        break;
                    };
                    if (dup) continue;
                    mun_seen[mun_seen_n] = lang;
                    mun_seen_n += 1;
                    const info = LDR_RESOURCE_INFO{
                        .Type = @intFromPtr(lpType),
                        .Name = @intFromPtr(lpName),
                        .Language = lang,
                    };
                    var out: ?*anyopaque = null;
                    const status = g_real_LdrFindResourceEx_U.?(NO_MUI, mun_base, &info, 3, &out);
                    log.info(
                        "[mui]   probe MUN    lang=0x{x} -> status=0x{x} entry=0x{x}",
                        .{ lang, @as(u32, @bitCast(status)), @intFromPtr(out) },
                    );
                    if (status >= 0 and out != null) {
                        log.info("[mui] FindResourceExW satisfied from MUN at lang=0x{x}", .{lang});
                        return out;
                    }
                }
            }

            if (d.MuiBase) |mui_base| {
                seen_n = 0;
                for (langs) |lang| {
                    var dup = false;
                    for (seen[0..seen_n]) |s| if (s == lang) {
                        dup = true;
                        break;
                    };
                    if (dup) continue;
                    seen[seen_n] = lang;
                    seen_n += 1;
                    const info = LDR_RESOURCE_INFO{
                        .Type = @intFromPtr(lpType),
                        .Name = @intFromPtr(lpName),
                        .Language = lang,
                    };
                    var out: ?*anyopaque = null;
                    const status = g_real_LdrFindResourceEx_U.?(NO_MUI, mui_base, &info, 3, &out);
                    log.info(
                        "[mui]   probe MUI    lang=0x{x} -> status=0x{x} entry=0x{x}",
                        .{ lang, @as(u32, @bitCast(status)), @intFromPtr(out) },
                    );
                    if (status >= 0 and out != null) {
                        log.info("[mui] FindResourceExW satisfied from MUI at lang=0x{x}", .{lang});
                        return out;
                    }
                }
            }
            log.info("[mui] satellite probe also missed for {s}", .{modbuf[0..modlen]});
        }
    }
    return r;
}

pub fn LoadResource_hook(hModule: ?*anyopaque, hResInfo: ?*anyopaque) callconv(.winapi) ?*anyopaque {
    if (hResInfo == null) return null;
    var owning = hModule;
    if (lookupOwningImageBase(@intFromPtr(hResInfo))) |b| {
        owning = b;
    }

    if (g_real_LdrAccessResource) |lar| {
        var data: ?*anyopaque = null;
        var size: usize = 0;
        const status = lar(owning, hResInfo, &data, &size);
        if (status >= 0) return data;
        return null;
    }
    if (g_real_LoadResource) |lr| return lr(owning, hResInfo);
    return null;
}

pub fn SizeofResource_hook(hModule: ?*anyopaque, hResInfo: ?*anyopaque) callconv(.winapi) u32 {
    if (hResInfo == null) return 0;
    var owning = hModule;
    if (lookupOwningImageBase(@intFromPtr(hResInfo))) |b| {
        owning = b;
    }
    if (g_real_LdrAccessResource) |lar| {
        var data: ?*anyopaque = null;
        var size: usize = 0;
        const status = lar(owning, hResInfo, &data, &size);
        if (status >= 0) return @intCast(size);
        return 0;
    }
    if (g_real_SizeofResource) |sr| return sr(owning, hResInfo);
    return 0;
}

pub fn FindResourceW_hook(
    hModule: ?*anyopaque,
    lpName: ?[*:0]const u16,
    lpType: ?[*:0]const u16,
) callconv(.winapi) ?*anyopaque {
    var tbuf: [64]u8 = undefined;
    var nbuf: [128]u8 = undefined;
    const tlen = formatResNameOrId(@intFromPtr(lpType), &tbuf);
    const nlen = formatResNameOrId(@intFromPtr(lpName), &nbuf);
    const r = FindResourceExW_hook(hModule, lpType, lpName, 0);
    log.info(
        "[diag] FindResourceW:   hModule=0x{x} type={s} name={s} -> 0x{x}",
        .{ @intFromPtr(hModule), tbuf[0..tlen], nbuf[0..nlen], @intFromPtr(r) },
    );
    return r;
}

pub fn LdrFindResourceEx_U_hook(
    flags: u32,
    base: ?*anyopaque,
    info: *const LDR_RESOURCE_INFO,
    level: u32,
    out: *?*anyopaque,
) callconv(.winapi) i32 {
    const real = g_real_LdrFindResourceEx_U orelse return @bitCast(@as(u32, 0xC000_0089));
    var tbuf: [64]u8 = undefined;
    var nbuf: [128]u8 = undefined;
    const tlen = formatResNameOrId(info.Type, &tbuf);
    const nlen = formatResNameOrId(info.Name, &nbuf);
    const status = real(flags, base, info, level, out);
    log.info(
        "[diag] LdrFindResourceEx_U: base=0x{x} flags=0x{x} type={s} name={s} lang=0x{x} level={d} -> status=0x{x} entry=0x{x}",
        .{ @intFromPtr(base), flags, tbuf[0..tlen], nbuf[0..nlen], info.Language, level, @as(u32, @bitCast(status)), @intFromPtr(out.*) },
    );
    return status;
}

pub fn LdrFindResource_U_hook(
    base: ?*anyopaque,
    info: *const LDR_RESOURCE_INFO,
    level: u32,
    out: *?*anyopaque,
) callconv(.winapi) i32 {
    const real = g_real_LdrFindResource_U orelse return @bitCast(@as(u32, 0xC000_0089));
    var tbuf: [64]u8 = undefined;
    var nbuf: [128]u8 = undefined;
    const tlen = formatResNameOrId(info.Type, &tbuf);
    const nlen = formatResNameOrId(info.Name, &nbuf);
    const status = real(base, info, level, out);
    log.info(
        "[diag] LdrFindResource_U:   base=0x{x} type={s} name={s} lang=0x{x} level={d} -> status=0x{x} entry=0x{x}",
        .{ @intFromPtr(base), tbuf[0..tlen], nbuf[0..nlen], info.Language, level, @as(u32, @bitCast(status)), @intFromPtr(out.*) },
    );
    return status;
}

pub fn GetProcAddress_hook(module: ?*anyopaque, name: [*:0]const u8) callconv(.winapi) ?*anyopaque {
    const real = g_real_GetProcAddress orelse return null;
    const r = real(module, name);
    // High 16 bits zero == ordinal lookup; otherwise it's a name pointer.
    if (@intFromPtr(name) < 0x10000) {
        log.info(
            "[diag] GetProcAddress: module=0x{x} ord={d} -> 0x{x}",
            .{ @intFromPtr(module), @intFromPtr(name) & 0xFFFF, @intFromPtr(r) },
        );
    } else {
        var nbuf: [128]u8 = undefined;
        const nlen = cstrToAscii(name, &nbuf);
        log.info(
            "[diag] GetProcAddress: module=0x{x} name=\"{s}\" -> 0x{x}",
            .{ @intFromPtr(module), nbuf[0..nlen], @intFromPtr(r) },
        );
    }
    return r;
}

pub fn patchDiagnosticHooks(mgr: *ActCtxManager, dll_rec: anytype) void {
    if (mgr.real.GetLastError != null and g_real_GetLastError == null) {
        g_real_GetLastError = mgr.real.GetLastError;
    }
    var tmp: [96]u8 = undefined;
    const t = str.toUpperTemp;
    inline for (.{
        .{ "InitCommonControlsEx", &g_real_InitCommonControlsEx, &InitCommonControlsEx_hook },
        .{ "RegisterClassExW", &g_real_RegisterClassExW, &RegisterClassExW_hook },
        .{ "FreeLibraryWhenCallbackReturns", &g_real_FreeLibraryWhenCallbackReturns, &FreeLibraryWhenCallbackReturns_hook },
        .{ "LdrGetDllHandleEx", &g_real_LdrGetDllHandleEx, &LdrGetDllHandleEx_hook },
        .{ "LdrGetProcedureAddress", &g_real_LdrGetProcedureAddress, &LdrGetProcedureAddress_hook },
        .{ "LdrLoadDll", &g_real_LdrLoadDll, &LdrLoadDll_hook },
        .{ "GetProcAddress", &g_real_GetProcAddress, &GetProcAddress_hook },
        .{ "QueryActCtxW", &g_real_QueryActCtxW, &QueryActCtxW_hook },
        .{ "RtlQueryInformationActivationContext", &g_real_RtlQueryInformationActivationContext, &RtlQueryInformationActivationContext_hook },
        .{ "FindResourceW", &g_real_FindResourceW, &FindResourceW_hook },
        .{ "FindResourceExW", &g_real_FindResourceExW, &FindResourceExW_hook },
        .{ "LdrFindResource_U", &g_real_LdrFindResource_U, &LdrFindResource_U_hook },
        .{ "LdrFindResourceEx_U", &g_real_LdrFindResourceEx_U, &LdrFindResourceEx_U_hook },
        .{ "LoadResource", &g_real_LoadResource, &LoadResource_hook },
        .{ "SizeofResource", &g_real_SizeofResource, &SizeofResource_hook },
    }) |entry| {
        const name, const real_slot, const hook_fn = entry;
        if (dll_rec.NameExports.getPtr(t(&tmp, name))) |vp| {
            if (real_slot.* == null) {
                real_slot.* = @ptrCast(@alignCast(vp.*));
                log.info("[diag] captured real {s} = 0x{x}", .{ name, @intFromPtr(vp.*) });
            }
            vp.* = @ptrCast(@constCast(hook_fn));
        }
    }
}
