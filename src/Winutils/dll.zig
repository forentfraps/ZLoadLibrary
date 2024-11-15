const std = @import("std");
const win = @import("std").os.windows;
const clr = @import("clr.zig");
const sneaky_memory = @import("memory.zig");
const logger = @import("../Logger/logger.zig");
const winc = @import("Windows.h.zig");
const apiset = @import("apiset.zig");

extern fn UniversalStub() void;

//const UniversalStubPtr: usize = @intFromPtr(&UniversalStub);

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
};

const print = std.debug.print;

const UNICODE_STRING = extern struct {
    Length: u16,
    MaximumLength: u16,
    alignment: u32,
    Buffer: ?[*:0]u16,
};

const LDR_DATA_TABLE_ENTRY = extern struct {
    Reserved1: [2]usize,
    //16
    InMemoryOrderLinks: winc.LIST_ENTRY,
    // 32
    Reserved2: [4]usize,
    // 64
    DllBase: ?*void,
    //72
    EntryPoint: ?*void,
    //80
    Reserved3: usize,
    //88
    fullDllName: UNICODE_STRING,
    //106
    BaseDllName: UNICODE_STRING,
    //120
    Reserved5: usize,
    TimeDateStamp: u32,
};

const PEB_LDR_DATA = extern struct {
    Reserved1: [3]usize,
    InMemoryOrderModuleList: [2]usize,
};

const PEB = extern struct {
    Reserved1: [2]u8,
    BeingDebugged: u8,
    Reserved2: [1]u8,
    Reserved3: [2]*void,
    Ldr: *PEB_LDR_DATA,
    Reserved4: [3]*void,
    Reserved5: [2]usize,
    Reserved6: *void,
    Reserved7: usize,
    Reserved8: [4]usize,
    Reserved9: [4]usize,
    Reserved10: [1]usize,
    PostProcessInitRoutine: *const usize,
    Reserved11: [1]usize,
    Reserved12: [1]usize,
    SessionId: u32,
};
const print16 = clr.print16;

const pref_list = [_][]const u8{ "RefLoad", "ExpTable", "ImpFix", "ImpRes", "RVAres", "HookF" };

const colour = logger.LoggerColour;
const colour_list = [_]colour{ colour.green, colour.blue, colour.cyan, colour.yellow, colour.pink, colour.red };

const logtags = enum {
    RefLoad,
    ExpTable,
    ImpFix,
    ImpRes,
    RVAres,
    HookF,
};

var log = logger.Logger.init(6, pref_list, colour_list);

pub const Dll = struct {
    NameExports: std.StringHashMap(*void) = undefined,
    OrdinalExports: std.AutoHashMap(u16, *void) = undefined,
    BaseAddr: [*]u8 = undefined,
    Path: *DllPath = undefined,
};

//Reasoning behind this is that for hooking GetProcAddress or GetModuleHandle
//We required hashmaps froms the initiated instance
//However during the call we are not allowed to pass them around
//Since the call will be from reflectively loaded dlls.
pub var GLOBAL_DLL_LOADER: *DllLoader = undefined;

pub fn GetProcAddress(hModule: [*]u8, procname: [*:0]const u8) callconv(.C) ?*void {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    log.info("[+] Hit GPA {s}\n", .{procname});
    const self = GLOBAL_DLL_LOADER;
    var it = self.LoadedDlls.keyIterator();
    return outer: while (true) {
        if (it.next()) |key| {
            const dll = self.LoadedDlls.get(key.*).?;
            if (dll.BaseAddr == hModule) {
                if (dll.NameExports.get(procname[0..std.mem.len(procname)])) |procaddr| {
                    log.info16("found in dll: ", .{}, key.*);
                    break :outer procaddr;
                }
            }
        } else {
            log.info("Did not find the funciton :(\n", .{});
            break :outer null;
        }
    };
}

pub fn GetModuleHandleA(moduleName_: ?[*:0]const u8) callconv(.C) ?[*]u8 {
    log.setContext(logtags.HookF);
    defer log.rollbackContext();
    if (moduleName_) |moduleName| {
        log.info("[+] Hit GMHA {s}\n", .{moduleName});
        const self = GLOBAL_DLL_LOADER;
        const utf16name: [*:0]u16 = @ptrCast(clr.lstring(self.Allocator, moduleName[0 .. std.mem.len(moduleName) + 1]) catch return null);
        return GetModuleHandleW(utf16name);
    } else {
        const peb: usize = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> usize),
            :
            : "memory"
        );
        const addr: [*]u8 = @ptrFromInt(peb + 0x10);
        log.info("got .exe call returning {*}\n", .{addr});
        return addr;
    }
}

pub fn GetModuleHandleW(moduleName16_: ?[*:0]const u16) callconv(.C) ?[*]u8 {
    //TODO Parse long path into short one
    log.setContext(logtags.HookF);
    defer log.rollbackContext();

    log.info("[+] Hit GMHW ptr {*}\n", .{moduleName16_});

    if (moduleName16_) |moduleName16| {
        const len = std.mem.len(moduleName16) + 1;
        log.info16("[+] GMHW name \n", .{}, moduleName16[0..len]);
        const self = GLOBAL_DLL_LOADER;
        const dllPath = (self.getDllPaths(@ptrCast(moduleName16[0..len])) catch {
            log.crit("Unable to discover a path\n", .{});
            return null;
        }) orelse {
            log.crit("Unable to discover a path\n", .{});
            return null;
        };
        log.info16("Resolved shortname of a module: ", .{}, dllPath.shortPath16);
        if (self.LoadedDlls.contains(@constCast(dllPath.shortPath16))) {
            return self.LoadedDlls.get(@constCast(dllPath.shortPath16)).?.BaseAddr;
        } else {
            log.crit16("Doing the unthinkable to \n", .{}, moduleName16[0..std.mem.len(moduleName16)]);
            const resulting_address = self.ZLoadLibrary(@as([:0]u16, @constCast(@ptrCast(
                moduleName16[0..len],
            )))) catch {
                return null;
            } orelse {
                return null;
            };
            return resulting_address.BaseAddr;
        }
    } else {
        const peb: usize = asm volatile ("mov %gs:0x60, %rax"
            : [peb] "={rax}" (-> usize),
            :
            : "memory"
        );
        const addr: *[*]u8 = @ptrFromInt(peb + 0x10);
        log.info("got self call returning {*}\n", .{addr.*});
        return addr.*;
    }
}

pub fn LoadLibraryW_stub(libname16: [*:0]u16) callconv(.C) ?[*]u8 {
    log.crit16("Someone actually did a loadlibraryW ", .{}, libname16[0..std.mem.len(libname16)]);
    if (GLOBAL_DLL_LOADER.LoadedDlls.contains(libname16[0..std.mem.len(libname16)])) {
        return GLOBAL_DLL_LOADER.LoadedDlls.get(libname16[0..std.mem.len(libname16)]).?.BaseAddr;
    }

    const dll = GLOBAL_DLL_LOADER.ZLoadLibrary(@ptrCast(libname16[0..std.mem.len(libname16)])) catch {
        log.crit("Failed to reflective load, returning null\n", .{});
        return null;
    } orelse {
        return null;
    };
    return dll.BaseAddr;
}

pub fn LoadLibraryA_stub(libname: [*:0]u8) callconv(.C) ?[*]u8 {
    log.crit("Someone actually did a loadlibraryA {s}\n", .{libname});
    const libname16 = lstring(GLOBAL_DLL_LOADER.Allocator, libname[0 .. std.mem.len(libname) + 1]) catch {
        log.crit("Failed to allocate string\n", .{});
        return null;
    };
    return LoadLibraryW_stub(@ptrCast(libname16.ptr));
}

const MappingContext = struct {
    pub fn hash(self: @This(), key: []u16) u64 {
        _ = self;

        const len = key.len;
        const u8ptr: [*]const u8 = @ptrCast(key.ptr);
        var hasher = std.hash.Wyhash.init(0);

        hasher.update(u8ptr[0 .. len * 2]);
        return hasher.final();
    }

    pub fn eql(self: @This(), key_1: []u16, key_2: []u16) bool {
        _ = self;

        return std.mem.eql(u16, key_1, key_2);
    }
};

pub const u16HashMapType = std.HashMap([]u16, *Dll, MappingContext, 80);

const lstring = clr.lstring;

pub const DllPath = struct {
    path16: [:0]u16,
    shortPath16: [:0]u16,
};

pub const DllLoader = struct {
    LoadedDlls: u16HashMapType = undefined,
    Allocator: std.mem.Allocator,
    HeapAllocator: sneaky_memory.HeapAllocator = undefined,

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .Allocator = allocator,
        };
    }

    pub fn getLoadedDlls(self: *@This()) !void {
        //const heap = win.kernel32.GetProcessHeap().?;

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
        //Skipping ListHead and .exe selfmodule
        while (count < 1000) : ({
            curr = curr.Flink;
            count += 1;
        }) {
            const entry: *LDR_DATA_TABLE_ENTRY = @ptrFromInt(@intFromPtr(curr) - 16);

            const BaseDllName: UNICODE_STRING = entry.BaseDllName;

            if (BaseDllName.Buffer != null and (BaseDllName.Length / 2) <= 260 and skipcount <= 0) {
                var dll: *Dll = @ptrCast(@alignCast(try self.Allocator.create(Dll)));
                dll.BaseAddr = @ptrCast(entry.DllBase);
                const dllName: [*:0]u16 = @ptrCast((try self.Allocator.alloc(u16, entry.fullDllName.Length / 2 + 1)).ptr);
                std.mem.copyForwards(u16, dllName[0 .. entry.fullDllName.Length / 2 + 1], entry.fullDllName.Buffer.?[0..(entry.fullDllName.Length / 2 + 1)]);
                dll.Path = try self.Allocator.create(DllPath);

                dll.Path.shortPath16 = @ptrCast(dllName[0 .. entry.fullDllName.Length / 2 + 1]);
                dll.Path.path16 = @ptrCast(dllName[0 .. entry.fullDllName.Length / 2 + 1]);
                try self.ResolveExports(dll);
                try self.LoadedDlls.put(BaseDllName.Buffer.?[0..(entry.BaseDllName.Length / 2 + 1)], dll);
                //print16(BaseDllName.Buffer.?[0..(entry.BaseDllName.Length / 2 + 1)].ptr);
                if (curr == head) {
                    break;
                }
            } else {
                skipcount -= 1;
            }
        }
        return;
    }

    pub fn ResolveImportInconsistencies(self: *@This(), dll: *Dll) !void {
        log.setContext(logtags.ImpFix);
        defer log.rollbackContext();

        log.crit16("Patching", .{}, dll.Path.path16);
        // Call After heap allocator init, a lot of stuff to allocate

        //const dll_base = dll.BaseAddr;
        //const dos_headers: *winc.IMAGE_DOS_HEADER = @ptrCast(@alignCast(dll_base));
        //const lfanewoffset: usize = @intCast(dos_headers.e_lfanew);
        //const nt_headers: *const winc.IMAGE_NT_HEADERS = @ptrCast(@alignCast(dll_base[lfanewoffset..]));
        //const dll_image_size = nt_headers.OptionalHeader.SizeOfImage;
        //var import_descriptor: *const winc.IMAGE_IMPORT_DESCRIPTOR = @ptrCast(@alignCast(dll_base[nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress..]));
        //var old_protect: winc.DWORD = 0;

        if (dll.NameExports.get("GetProcAddress")) |_| {
            try dll.NameExports.put("GetProcAddress", @as(*void, @ptrCast(@constCast(&GetProcAddress))));
        }
        if (dll.NameExports.get("GetModuleHandleA")) |_| {
            try dll.NameExports.put("GetModuleHandleA", @as(*void, @ptrCast(@constCast(&GetModuleHandleA))));
        }
        if (dll.NameExports.get("GetModuleHandleW")) |_| {
            try dll.NameExports.put("GetModuleHandleW", @as(*void, @ptrCast(@constCast(&GetModuleHandleW))));
        }

        if (dll.NameExports.get("LoadLibraryA")) |_| {
            try dll.NameExports.put("LoadLibraryA", @as(*void, @ptrCast(@constCast(&LoadLibraryA_stub))));
        }
        if (dll.NameExports.get("LoadLibraryW")) |_| {
            try dll.NameExports.put("LoadLibraryW", @as(*void, @ptrCast(@constCast(&LoadLibraryW_stub))));
        }

        var efit = dll.NameExports.keyIterator();
        import_cycle: while (true) {
            if (efit.next()) |fptr| {
                const faddr: [*]u8 = @ptrCast(dll.NameExports.get(fptr.*).?);
                if (!clr.looksLikeAscii(faddr[0..5])) {
                    // log.info("Function {s} looks OK\n", .{fptr.*});
                    continue;
                }

                // log.crit("Function {s} looks BAD\n", .{fptr.*});

                var exportFname: []const u8 = undefined;
                if (clr.findExportRealName(faddr)) |ename| {
                    exportFname = ename;
                } else {
                    exportFname = fptr.*;
                }

                var dll_nameexports = dll.NameExports;

                var it = self.LoadedDlls.keyIterator();
                while (true) {
                    if (it.next()) |key| {
                        if (dll.BaseAddr == self.LoadedDlls.get(key.*).?.BaseAddr) {
                            continue;
                        }
                        var some_random_dll = self.LoadedDlls.get(key.*).?.NameExports;

                        if (some_random_dll.get(exportFname)) |func_addr| {
                            log.info("Patched export {s}\n", .{fptr.*});
                            try dll_nameexports.put(fptr.*, func_addr);

                            continue :import_cycle;
                        }
                    } else {
                        continue :import_cycle;
                    }
                }
            } else {
                break;
            }
        }
    }

    pub fn ResolveExports(self: *@This(), dll: *Dll) !void {
        log.setContext(logtags.ExpTable);
        defer log.rollbackContext();
        log.crit16("resolving", .{}, dll.Path.shortPath16);
        // Please call this funciton after defining BaseAddr of the dll
        const dll_bytes: [*]u8 = dll.BaseAddr;
        const dos_headers: *winc.IMAGE_DOS_HEADER = @ptrCast(@alignCast(dll_bytes));
        const lfanewoffset: usize = @intCast(dos_headers.e_lfanew);
        const nt_headers: *const winc.IMAGE_NT_HEADERS = @ptrCast(@alignCast(dll_bytes[lfanewoffset..]));
        const export_descriptor: *const winc.IMAGE_EXPORT_DIRECTORY = @ptrCast(@alignCast(dll_bytes[nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress..]));
        const NumberOfNames = export_descriptor.NumberOfNames;
        //const NumberOfFunctions = export_descriptor.NumberOfFunctions;
        const exportAddressTable: [*]i32 = @ptrCast(@alignCast(dll_bytes[export_descriptor.AddressOfFunctions..]));
        const exportNamePointerTable: [*]i32 = @ptrCast(@alignCast(dll_bytes[export_descriptor.AddressOfNames..]));
        const exportNameOrdinalTable: [*]u16 = @ptrCast(@alignCast(dll_bytes[export_descriptor.AddressOfNameOrdinals..]));
        dll.NameExports = std.StringHashMap(*void).init(self.Allocator);
        dll.OrdinalExports = std.AutoHashMap(u16, *void).init(self.Allocator);

        // Really stupid ntdll ExportTable with the first entry having no name

        //var ordinal_high: u8 = 0;
        //var ordinal_low: u8 = 0;
        var ordinal: u16 = 0;
        for (0..NumberOfNames) |i| {
            const funcname: [*:0]u8 = @ptrCast(dll_bytes[@as(usize, @intCast(exportNamePointerTable[i]))..]);
            ordinal = exportNameOrdinalTable[i];
            //ordinal_low = ord_u8arr[1];
            //ordinal_high = ord_u8arr[0];
            //ordinal = (@as(u16, @intCast(ordinal_high)) << 0x8) | (@as(u16, @intCast(ordinal_low)));
            const fptr: *void = @ptrCast(dll_bytes[@as(usize, @intCast(exportAddressTable[ordinal]))..]);
            const fbytes: [*:0]const u8 = @ptrCast(fptr);
            if (clr.looksLikeAscii(fbytes[0..11])) {
                log.info("Function {s} looks like ascii ptr: {*} asci:{s}\n", .{ funcname, fptr, fbytes[0..std.mem.len(fbytes)] });
                //print("This function is blank {s}\n", .{funcname});
            }

            try dll.NameExports.putNoClobber(funcname[0..std.mem.len(funcname)], fptr);
            try dll.OrdinalExports.putNoClobber(
                ordinal,
                fptr,
            );
        }
    }

    pub fn getDllPaths(self: *@This(), libname16_: [:0]const u16) !?*DllPath {

        //Resolve dll path from PATH env var or CWD
        const kernel32_s = try lstring(self.Allocator, "KERNEL32.DLL");
        defer self.Allocator.free(kernel32_s);
        const kernel32 = self.LoadedDlls.get(kernel32_s).?.NameExports;

        const GetEnvironmentVariable: *const fn ([*]const u16, [*:0]u16, c_uint) callconv(.C) c_uint = @ptrCast(kernel32.get("GetEnvironmentVariableW") orelse return DllError.FuncResolutionFailed);
        const GetFileAttributesW: *const fn ([*:0]u16) callconv(.C) c_int = @ptrCast(kernel32.get("GetFileAttributesW") orelse return DllError.FuncResolutionFailed);
        const GetSystemDirectoryW: *const fn ([*]u16, usize) callconv(.C) c_int = @ptrCast(kernel32.get("GetSystemDirectoryW") orelse return DllError.FuncResolutionFailed);
        const GetLastError: *const fn () callconv(.C) c_int = @ptrCast(kernel32.get("GetLastError"));
        const SetLastError: *const fn (c_int) callconv(.C) void = @ptrCast(kernel32.get("SetLastError"));

        const dllPath: *DllPath = try self.Allocator.create(DllPath);

        if (clr.isFullPath(libname16_)) |symbol| {
            dllPath.path16 = @constCast(libname16_);
            var start_index: usize = 0;
            for (dllPath.path16, 0..) |item, index| {
                if (item == symbol) {
                    start_index = index + 1;
                }
            }
            dllPath.shortPath16 = dllPath.path16[start_index..];
        } else {
            dllPath.path16 = @ptrCast(try self.Allocator.alloc(u16, 260));
            var PATH: [33000:0]u16 = undefined;
            const PATH_s = try lstring(self.Allocator, "PATH");

            var len: usize = GetEnvironmentVariable(PATH_s.ptr, &PATH, 32767);
            self.Allocator.free(PATH_s);
            PATH[len] = @intCast('.');
            PATH[len + 1] = @intCast('\\');
            PATH[len + 2] = @intCast(';');
            len += 3;
            const syslen: usize = @intCast(GetSystemDirectoryW(PATH[len..].ptr, 30));

            PATH[len + syslen] = 0;

            var i: usize = 0;
            var start_pointer: usize = 0;
            var end_pointer: usize = 0;
            var found: bool = false;

            cycle: while (PATH[i] != 0) : (i += 1) {
                if ((PATH[i] & 0xff00 == 0) and @as(u8, @intCast(PATH[i])) == ';') {
                    end_pointer = i;

                    const tmp_str_len = end_pointer - start_pointer + 1 + libname16_.len + 1 + 1;
                    var u16searchString: [:0]u16 = @ptrCast(try self.Allocator.alloc(u16, tmp_str_len));
                    //std.mem.copyForwards(u16, u8searchString[0 .. end_pointer - start_pointer], PATH[start_pointer..end_pointer]);
                    std.mem.copyForwards(u16, u16searchString[0 .. end_pointer - start_pointer], PATH[start_pointer..end_pointer]);

                    u16searchString[end_pointer - start_pointer] = @intCast('\\');
                    std.mem.copyForwards(
                        u16,
                        u16searchString[end_pointer - start_pointer + 1 .. tmp_str_len],
                        libname16_,
                    );

                    u16searchString[tmp_str_len - 1] = 0;
                    _ = GetFileAttributesW(u16searchString.ptr);
                    const err: c_int = GetLastError();
                    if (err != 0) {
                        SetLastError(0);
                        start_pointer = end_pointer + 1;
                        self.Allocator.free(@as([]u16, @ptrCast(u16searchString[0..tmp_str_len])));
                        continue :cycle;
                    }
                    found = true;
                    dllPath.path16 = @ptrCast(u16searchString[0 .. tmp_str_len - 2]);
                    dllPath.shortPath16 = @constCast(libname16_);
                    break :cycle;
                }
            }

            if (!found) {
                return null;
            }
        }

        return dllPath;
    }

    pub fn LoadDllInMemory(self: *@This(), dllPath: *DllPath, dllSize: *usize) !?[*]u8 {
        // load DLL into memory

        const kernel32_s = try lstring(self.Allocator, "KERNEL32.DLL");
        defer self.Allocator.free(kernel32_s);
        const kernel32 = self.LoadedDlls.get(kernel32_s).?.NameExports;

        const CreateFileW: *const fn ([*:0]const u16, u32, u32, ?*win.SECURITY_ATTRIBUTES, u32, u32, ?*anyopaque) callconv(.C) *anyopaque = @ptrCast(kernel32.get("CreateFileW"));
        const CloseHandle: *const fn (*anyopaque) callconv(.C) c_int = @ptrCast(kernel32.get("CloseHandle"));
        const GetFileSizeEx: *const fn (*anyopaque, *i64) callconv(.C) c_int = @ptrCast(kernel32.get("GetFileSizeEx"));
        const ReadFile: *const fn (*anyopaque, [*]u8, u32, ?*u32, ?*win.OVERLAPPED) callconv(.C) c_int = @ptrCast(kernel32.get("ReadFile"));

        const dll_handle = CreateFileW(
            dllPath.path16,
            win.GENERIC_READ,
            0,
            null,
            win.OPEN_EXISTING,
            0,
            null,
        );
        defer _ = CloseHandle(dll_handle);

        var dll_size_i: i64 = 0;

        if ((GetFileSizeEx(dll_handle, &dll_size_i) <= 0)) {
            log.info("dll handle is {*}\n", .{dll_handle});
            return DllError.Size;
        }
        dllSize.* = @intCast(dll_size_i);

        const dll_bytes: [*]u8 = (try self.Allocator.alloc(u8, dllSize.*)).ptr;

        var bytes_read: winc.DWORD = 0;
        _ = ReadFile(dll_handle, dll_bytes, @as(u32, @intCast(dllSize.*)), &bytes_read, null);
        return dll_bytes;
    }

    pub fn ResolveNtHeaders(dll_bytes: [*]u8) *const winc.IMAGE_NT_HEADERS {
        const dos_headers: *winc.IMAGE_DOS_HEADER = @ptrCast(@alignCast(dll_bytes));
        const lfanewoffset: usize = @intCast(dos_headers.e_lfanew);
        const nt_headers: *const winc.IMAGE_NT_HEADERS = @ptrCast(@alignCast(dll_bytes[lfanewoffset..]));
        return nt_headers;
    }

    pub fn MapSections(
        self: *@This(),
        nt_headers: *const winc.IMAGE_NT_HEADERS,
        dll_bytes: [*]u8,
        delta_image_base: *usize,
    ) ![*]u8 {
        const ntdll_s = try lstring(self.Allocator, "ntdll.dll");
        defer self.Allocator.free(ntdll_s);
        const ntdll = self.LoadedDlls.get(ntdll_s).?.NameExports;

        const VirtualAlloc: *const fn (i64, *?[*]u8, usize, *usize, u32, u32) callconv(.C) c_int = @ptrCast(ntdll.get("ZwAllocateVirtualMemory"));

        var dll_base_dirty: ?[*]u8 = null;

        var section_index: usize = 0;
        var section: [*]const winc.IMAGE_SECTION_HEADER = @ptrFromInt(@intFromPtr(nt_headers) + @sizeOf(winc.IMAGE_NT_HEADERS));

        var end_size_resolution: usize = 0;
        while (section_index < nt_headers.FileHeader.NumberOfSections) {
            const cur_section = section[0];

            end_size_resolution = cur_section.VirtualAddress + cur_section.VirtualAddress;
            section_index += 1;

            section = section[1..];
        }

        var virtAllocSize: usize = end_size_resolution;

        log.info("VirtAllocSize {x}\n", .{virtAllocSize});
        var ntRes: c_int = VirtualAlloc(
            -1,
            &dll_base_dirty,
            0,
            &virtAllocSize,
            win.MEM_RESERVE | win.MEM_COMMIT,
            win.PAGE_EXECUTE_READWRITE,
        );
        if (ntRes < 0) {
            log.info("TRY 2 VirtAllocSize {x}\n", .{virtAllocSize});
            dll_base_dirty = null;
            ntRes = VirtualAlloc(
                -1,
                &dll_base_dirty,
                0,
                &virtAllocSize,
                win.MEM_RESERVE | win.MEM_COMMIT,
                win.PAGE_EXECUTE_READWRITE,
            );
        }

        log.info("REsulting VirtAllocSize {x}\n", .{virtAllocSize});
        const dll_base = dll_base_dirty.?;
        // get delta between this module's image base and the DLL that was read into memory
        delta_image_base.* = @intFromPtr(dll_base) - nt_headers.OptionalHeader.ImageBase;

        log.info("Size of headers {x}\n", .{nt_headers.OptionalHeader.SizeOfHeaders});
        // copy over DLL image headers to the newly allocated space for the DLL
        std.mem.copyForwards(u8, dll_base[0..nt_headers.OptionalHeader.SizeOfHeaders], dll_bytes[0..nt_headers.OptionalHeader.SizeOfHeaders]);

        // copy over DLL image sections to the newly allocated space for the DLL
        log.info("delta image base {x} dll_base {*} image_base {x} dll_size {x}\n", .{
            delta_image_base,
            dll_base,
            nt_headers.OptionalHeader.ImageBase,
            virtAllocSize,
        });
        section_index = 0;
        section = @ptrFromInt(@intFromPtr(nt_headers) + @sizeOf(winc.IMAGE_NT_HEADERS));

        for (0..nt_headers.FileHeader.NumberOfSections) |_| {
            const cur_section = section[0];
            const section_destination: [*]u8 = @ptrCast(dll_base[cur_section.VirtualAddress..]);
            const section_bytes: [*]u8 = @ptrCast(dll_bytes[cur_section.PointerToRawData..]);
            std.mem.copyForwards(
                u8,
                section_destination[0..cur_section.SizeOfRawData],
                section_bytes[0..cur_section.SizeOfRawData],
            );
            section = section[1..];
            log.info("Copying section to {*} to {*}\n", .{
                dll_base[cur_section.VirtualAddress..],
                dll_base[cur_section.VirtualAddress + cur_section.VirtualAddress ..],
            });
        }
        return dll_base;
    }

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

            for (0..relocations_count) |entry_index| {
                if (relocation_entries[entry_index].Type != 0) {
                    const relocation_rva: usize = relocation_block.PageAddress + relocation_entries[entry_index].Offset;
                    const ptr: *usize = @ptrCast(@alignCast(dll_base[relocation_rva..]));
                    //log.info("Value before rva is {x} changing to {*}\n", .{ ptr.*, ptr });
                    ptr.* = ptr.* + delta_image_base;

                    //address_to_patch += delta_image_base;

                } else {
                    //log.info("Type ABSOLUT offset: {d}\n", .{relocation_entries[entry_index].Offset});
                }
                relocations_processed += @sizeOf(BASE_RELOCATION_ENTRY);
            }
            //log.info("block proc\n", .{});
        }

        log.rollbackContext();
    }

    pub fn ResolveImportTable(
        self: *@This(),
        dll_base: [*]u8,
        nt_headers: *const winc.IMAGE_NT_HEADERS,
        dllPath: *DllPath,
        dll_struct: *Dll,
    ) !void {
        log.setContext(logtags.ImpRes);
        // resolve import address table
        if (nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress > 0) {
            log.info(" Resolving imports\n", .{});
            var import_descriptor: *const winc.IMAGE_IMPORT_DESCRIPTOR = @ptrCast(@alignCast(dll_base[nt_headers.OptionalHeader.DataDirectory[winc.IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress..]));

            while (import_descriptor.Name != 0) : (import_descriptor = @ptrFromInt(@intFromPtr(import_descriptor) + @sizeOf(winc.IMAGE_IMPORT_DESCRIPTOR))) {
                const library_name: [*:0]const u8 = @ptrCast(dll_base[import_descriptor.Name..]);
                if (std.mem.len(library_name) == 0) {
                    break;
                } else {
                    var library_name16_len: usize = 0;

                    //print("Current lib to load: {s}\n", .{library_name});

                    var library_name16: [:0]u16 = @ptrCast(try self.Allocator.alloc(
                        u16,
                        (while (true) : (library_name16_len += 1) {
                            if (!(library_name[library_name16_len] != 0 and library_name16_len < 260)) break library_name16_len;
                        } else 260) + 1,
                    ));
                    library_name16_len += 2;
                    //print("Current lib to load: {s} size in u8 {d} in u16 {d}\n", .{ library_name, (library_name16_len - 2) / 2, library_name16_len });

                    //Do not defer because the name is later used
                    //defer self.Allocator.free(library_name16);

                    clr.u8tou16(library_name, library_name16.ptr, library_name16_len);
                    var library_nameHm: std.StringHashMap(*void) = undefined;
                    var library_ordinalHm: std.AutoHashMap(u16, *void) = undefined;
                    const apiHostName = apiset.ApiSetResolve(library_name16);
                    var libraryNameToLoad16: [:0]u16 = undefined;
                    if (apiHostName) |apiHostNameResolved| {
                        const zeroTerminatedLibraryNameToLoad16 = try self.Allocator.alloc(u16, apiHostNameResolved.len + 1);
                        @memcpy(zeroTerminatedLibraryNameToLoad16[0..apiHostNameResolved.len], apiHostNameResolved[0..apiHostNameResolved.len]);
                        zeroTerminatedLibraryNameToLoad16[apiHostNameResolved.len] = 0;
                        libraryNameToLoad16 = @ptrCast(zeroTerminatedLibraryNameToLoad16);
                        log.info16("Found apiset to load: ", .{}, library_name16);
                        log.info16("apiHost found: ", .{}, libraryNameToLoad16);
                    } else {
                        libraryNameToLoad16 = @ptrCast(library_name16[0 .. library_name16_len - 1]);
                    }
                    var library: ?*Dll = null;
                    var loading_from_itself: bool = false;
                    if (!self.LoadedDlls.contains(libraryNameToLoad16)) {
                        log.info16("reflective loading library: ", .{}, libraryNameToLoad16);
                        if (std.mem.eql(u16, dllPath.shortPath16, libraryNameToLoad16)) {
                            library = dll_struct;
                            loading_from_itself = true;
                        } else {
                            library = try self.ZLoadLibrary(libraryNameToLoad16);
                        }
                    } else {
                        library = self.LoadedDlls.get(libraryNameToLoad16).?;
                    }
                    library_nameHm = library.?.NameExports;
                    library_ordinalHm = library.?.OrdinalExports;

                    var thunk: *winc.IMAGE_THUNK_DATA = @ptrCast(@alignCast(dll_base[import_descriptor.FirstThunk..]));
                    import_cycle: while (thunk.u1.AddressOfData != 0) : (thunk = @ptrFromInt(@intFromPtr(thunk) + @sizeOf(winc.IMAGE_THUNK_DATA))) {
                        if (thunk.u1.AddressOfData & 0xf0000000_00000000 != 0) {
                            //No idea wtf is this, but win32u has this ¯\_(ツ)_/¯
                            continue;
                        }
                        if (winc.IMAGE_SNAP_BY_ORDINAL(thunk.u1.Ordinal)) {
                            //This has never happened yet, delay is to catch this :)
                            win.kernel32.Sleep(5000);
                            const function_ordinal: *u16 = @ptrFromInt(winc.IMAGE_ORDINAL(thunk.u1.Ordinal));
                            if (false) {
                                continue :import_cycle;
                            }
                            thunk.u1.Function = @intFromPtr(library_ordinalHm.get(function_ordinal.*).?);
                        } else {
                            const function_name: *const winc.IMAGE_IMPORT_BY_NAME = @ptrCast(@alignCast(dll_base[thunk.u1.AddressOfData..]));
                            const function_name_realname: [*:0]const u8 = @ptrCast(&function_name.Name);
                            const fname_len = std.mem.len(function_name_realname);

                            thunk.u1.Function = @intFromPtr(library_nameHm.get(function_name_realname[0..fname_len]).?);
                            // log.info("import function {s} - {x}\n", .{ function_name_realname[0..fname_len], thunk.u1.Function });
                        }
                    }
                }
            }
        }

        log.rollbackContext();
    }

    pub fn ZLoadLibrary(self: *@This(), libname16_: [:0]const u16) anyerror!?*Dll {
        // TODO clean stackframe calls to dangerous functions
        //
        // TODO Never have RWX memory, should be RW then RX

        log.setContext(logtags.RefLoad);
        defer log.rollbackContext();

        const kernel32_s = try lstring(self.Allocator, "KERNEL32.DLL");
        defer self.Allocator.free(kernel32_s);
        const kernel32_m = self.LoadedDlls.get(kernel32_s).?;
        const kernel32 = kernel32_m.NameExports;

        const ntdll_s = try lstring(self.Allocator, "ntdll.dll");
        defer self.Allocator.free(ntdll_s);
        const ntdll_m = self.LoadedDlls.get(ntdll_s).?;
        const ntdll = ntdll_m.NameExports;

        const smallKernel32_s = try lstring(self.Allocator, "kernel32.dll");

        if (std.mem.eql(u16, libname16_, smallKernel32_s)) {
            return kernel32_m;
        }
        const mediumKernel32_s = try lstring(self.Allocator, "KERNEL32.dll");

        if (std.mem.eql(u16, libname16_, mediumKernel32_s)) {
            return kernel32_m;
        }

        const smallNtdll_s = try lstring(self.Allocator, "C:\\WINDOWS\\SYSTEM32\\NTDLL.DLL");
        if (std.mem.eql(u16, libname16_, smallNtdll_s)) {
            return ntdll_m;
        }
        //const ntdll_ord = self.LoadedDlls.get(ntdll_s).?.OrdinalExports;

        const GetLastError: *const fn () callconv(.C) c_int = @ptrCast(kernel32.get("GetLastError"));

        // Resolve full dll path and short path
        const dllPath = (try self.getDllPaths(libname16_)) orelse {
            log.crit("Failed to resolve dllPath\n", .{});
            return null;
        };

        log.info16("Starting to load valid dll", .{}, dllPath.shortPath16);
        log.info16("Full path is", .{}, dllPath.path16);

        var dll_struct: *Dll = try self.Allocator.create(Dll);
        dll_struct.Path = dllPath;

        // Load dll into memory from disk
        var dll_size: usize = 0;
        const dll_bytes = try self.LoadDllInMemory(dllPath, &dll_size) orelse {
            log.crit("Failed to load dll in memory error: {d}\n", .{GetLastError()});
            return null;
        };

        // get pointers to in-memory DLL headers
        const nt_headers = ResolveNtHeaders(dll_bytes);

        // Map Sections to virtual memory

        var delta_image_base: usize = 0;
        const dll_base = try self.MapSections(nt_headers, dll_bytes, &delta_image_base);
        dll_struct.BaseAddr = dll_base;

        // perform image base relocations
        try ResolveRVA(dll_base, nt_headers, delta_image_base);

        //resolve exports and put dll into loaded for later use
        try self.ResolveExports(dll_struct);

        // put it in loaded dlls even though it is not, to avoid revursive loading
        try self.LoadedDlls.put(dllPath.shortPath16, dll_struct);

        //Resolve import table
        try self.ResolveImportTable(dll_base, nt_headers, dllPath, dll_struct);

        // execute the loaded DLL
        try self.ResolveImportInconsistencies(dll_struct);

        log.info("fetching ntflush\n", .{});
        // I dont really know why is this being done, however it is advised to do so
        // after adding rx\rwx memory to a process
        // there are opinions that it matters only on some non x86 cpus
        const NtFlush: *const fn (i32, [*]u8, usize) c_int = @ptrCast(ntdll.get("NtFlushInstructionCache").?);
        const flush_res = NtFlush(-1, dll_base, dll_size);
        log.info("Flush result: {}\n", .{flush_res == 0});

        if (nt_headers.OptionalHeader.AddressOfEntryPoint != 0) {
            const dll_entry: ?*const DLLEntry = @ptrCast(dll_base[nt_headers.OptionalHeader.AddressOfEntryPoint..]);
            const dll_base_hinstance: win.HINSTANCE = @ptrCast(dll_base);
            if (dll_entry) |runnable_entry| {
                log.info16("Running the dll  {*}", .{runnable_entry}, dllPath.shortPath16);
                log.info("Addr off the base addr {x}\n", .{
                    nt_headers.OptionalHeader.ImageBase + nt_headers.OptionalHeader.AddressOfEntryPoint,
                });

                _ = runnable_entry(dll_base_hinstance, winc.DLL_PROCESS_ATTACH, null);
            }
        }

        return dll_struct;
    }
};
