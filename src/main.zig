const std = @import("std");
const dll = @import("Winutils/dll.zig");
const clr = @import("Winutils/clr.zig");
const sneaky_memory = @import("Winutils/memory.zig");
const logger = @import("Logger/logger.zig");
const winc = @import("Winutils/Windows.h.zig");
const apiset = @import("Winutils/apiset.zig");

const win = std.os.windows;
const lstring = clr.lstring;

const dllLoggerInterface = struct {
    pref_list: [][]const u8 = .{ "RefLoad", "ExpTable", "ImpFix", "ImpRes", "RVAres" },

    pub fn get(ind: usize) []const u8 {
        return dllLoggerInterface.pref_list[ind];
    }
};

const pref_list = [_][]const u8{"MAIN"};
const colour = logger.LoggerColour;
const colour_list = [_]colour{colour.green};
var log = logger.Logger.init(colour_list.len, pref_list, colour_list);
pub fn main() !void {
    std.debug.print("Starting to ref load dll\n", .{});

<<<<<<< HEAD
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    var DllLoader = dll.DllLoader.init(allocator);
    //try dll.ZLoadLibrary(try lstring(sa, "C:\\Windows\\System32\\user32.dll"));
    try DllLoader.getLoadedDlls();

=======
        std.debug.print("space used: {d}% leaving scope\n", .{100 * fba.end_index / (4096000)});
    }
    var kernel32_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "KERNEL32.DLL")).?;
    var kernelbase_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "KERNELBASE.dll")).?;
    var ntdll_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "ntdll.dll")).?;
    var kernel32 = kernel32_m.NameExports;
    var ntdll = ntdll_m.NameExports;
    const pHeapCreate = ntdll.get("RtlCreateHeap") orelse return dll.DllError.FuncResolutionFailed;
    const pHeapAlloc = ntdll.get("RtlAllocateHeap") orelse return dll.DllError.FuncResolutionFailed;
    const pHeapRealloc = ntdll.get("RtlReAllocateHeap") orelse return dll.DllError.FuncResolutionFailed;
    const pHeapFree = ntdll.get("RtlFreeHeap") orelse return dll.DllError.FuncResolutionFailed;
    const pHeapDestroy = ntdll.get("RtlDestroyHeap") orelse return dll.DllError.FuncResolutionFailed;
    var HeapAllocator = sneaky_memory.HeapAllocator.init(pHeapCreate, pHeapAlloc, pHeapRealloc, pHeapFree, pHeapDestroy);
    const newallocator = HeapAllocator.allocator();
>>>>>>> c510450c1963d417f849d22000ac22802073f29d
    var it = DllLoader.LoadedDlls.keyIterator();
    while (it.next()) |key| {
        log.info16("dll loaded name: ", .{}, key.*);
    }
    const kernel32_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "kernel32.dll")).?;
    const kernelbase_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "kernelbase.dll")).?;
    try DllLoader.ResolveImportInconsistencies(kernelbase_m);
    try DllLoader.ResolveImportInconsistencies(kernel32_m);

    dll.GLOBAL_DLL_LOADER = &DllLoader;

    const user32_s = try lstring(DllLoader.Allocator, "user32.dll");
    _ = try DllLoader.ZLoadLibrary(@as([:0]const u16, @ptrCast(user32_s)));
    std.debug.print("user32 looaded!\n", .{});
    const user32 = DllLoader.LoadedDlls.get(user32_s).?.NameExports;

    const MessageBoxW: *const fn (?*void, [*]const u16, [*]const u16, u64) c_int = @ptrCast(user32.get("MessageBoxW") orelse return dll.DllError.FuncResolutionFailed);
    _ = MessageBoxW(null, (try clr.lstring(DllLoader.Allocator, "Text")).ptr, (try clr.lstring(DllLoader.Allocator, "Text2")).ptr, 0);

    std.debug.print("Scope left fin!\n", .{});
}

// pub fn old_main() !void {
//     std.debug.print("Starting to ref load dll\n", .{});
//     var DllLoader: dll.DllLoader = undefined;
//     {
//         var tmp_buf: [4096000]u8 = undefined;
//         var fba = std.heap.FixedBufferAllocator.init(&tmp_buf);
//         const sa = fba.allocator();
//         DllLoader = dll.DllLoader.init(sa);
//         //try dll.ZLoadLibrary(try lstring(sa, "C:\\Windows\\System32\\user32.dll"));
//         try DllLoader.getLoadedDlls();
//         //try DllLoader.switchAllocator();
//
//         std.debug.print("space used: {d}% leaving scope\n", .{100 * fba.end_index / (4096000)});
//     }
//     var kernel32_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "KERNEL32.DLL")).?;
//     var kernelbase_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "KERNELBASE.dll")).?;
//     var ntdll_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "ntdll.dll")).?;
//     var kernel32 = kernel32_m.NameExports;
//     var ntdll = ntdll_m.NameExports;
//     const pHeapCreate = kernel32.get("HeapCreate") orelse return dll.DllError.FuncResolutionFailed;
//     const pHeapAlloc = ntdll.get("RtlAllocateHeap") orelse return dll.DllError.FuncResolutionFailed;
//     const pHeapRealloc = ntdll.get("RtlReAllocateHeap") orelse return dll.DllError.FuncResolutionFailed;
//     const pHeapFree = ntdll.get("RtlFreeHeap") orelse return dll.DllError.FuncResolutionFailed;
//     const pHeapDestroy = ntdll.get("RtlDestroyHeap") orelse return dll.DllError.FuncResolutionFailed;
//     var HeapAllocator = sneaky_memory.HeapAllocator.init(pHeapCreate, pHeapAlloc, pHeapRealloc, pHeapFree, pHeapDestroy);
//     const newallocator = HeapAllocator.allocator();
//     var it = DllLoader.LoadedDlls.keyIterator();
//     var newLoadedDlls: dll.u16HashMapType = dll.u16HashMapType.init(newallocator);
//
//     while (true) {
//         if (it.next()) |key| {
//             const dll_entry = DllLoader.LoadedDlls.get(key.*).?;
//
//             var dllPath: *dll.DllPath = try newallocator.create(dll.DllPath);
//
//             const newpathShort: [:0]u16 = @ptrCast((try newallocator.alloc(u16, dll_entry.Path.shortPath16.len)));
//             std.mem.copyForwards(u16, newpathShort, dll_entry.Path.shortPath16);
//             const newpath: [:0]u16 = @ptrCast((try newallocator.alloc(u16, dll_entry.Path.path16.len)));
//             std.mem.copyForwards(u16, newpath, dll_entry.Path.path16);
//             dllPath.shortPath16 = clr.getShortName(newpath);
//             dllPath.path16 = newpath;
//             dllPath.normalize();
//
//             var newdll = try newallocator.create(dll.Dll);
//             newdll.NameExports = try dll_entry.NameExports.cloneWithAllocator(newallocator);
//             newdll.OrdinalExports = try dll_entry.OrdinalExports.cloneWithAllocator(newallocator);
//             newdll.Path = dllPath;
//             newdll.BaseAddr = dll_entry.BaseAddr;
//             clr.print16(dllPath.shortPath16);
//             std.debug.print("\n", .{});
//
//             try newLoadedDlls.put(dllPath.shortPath16, newdll);
//         } else {
//             break;
//         }
//     }
//     DllLoader.LoadedDlls = newLoadedDlls;
//     DllLoader.Allocator = newallocator;
//     DllLoader.HeapAllocator = HeapAllocator;
//     dll.GLOBAL_DLL_LOADER = &DllLoader;
//     kernel32_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "kernel32.dll")).?;
//     kernelbase_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "kernelbase.dll")).?;
//     ntdll_m = DllLoader.LoadedDlls.get(try lstring(DllLoader.Allocator, "ntdll.dll")).?;
//
//     kernel32 = kernel32_m.NameExports;
//     ntdll = ntdll_m.NameExports;
//
//     try DllLoader.ResolveImportInconsistencies(kernelbase_m);
//     try DllLoader.ResolveImportInconsistencies(kernel32_m);
//
//     // if (true) return;
//
//     // const msvcrt_s = try lstring(DllLoader.Allocator, "msvcrt.dll");
//     //
//     // _ = try DllLoader.ZLoadLibrary(@as([:0]const u16, @ptrCast(msvcrt_s)));
//
//     // const ws2_32_s = try lstring(DllLoader.Allocator, "ws2_32.dll");
//     // _ = try DllLoader.ZLoadLibrary(@as([:0]const u16, @ptrCast(ws2_32_s)));
//     // //
//     // const ws2_32 = DllLoader.LoadedDlls.get(ws2_32_s).?.NameExports;
//     // const WSAStartup: *const fn (winc.WORD, *winc.WSADATA) c_int = @ptrCast(ws2_32.get("WSAStartup") orelse return dll.DllError.FuncResolutionFailed);
//     // var wsaData: winc.WSADATA = undefined;
//     // std.debug.print("WSAStartup value: {d}\n", .{WSAStartup(winc.MAKEWORD(2, 2), &wsaData)});
//     //
//     // const wininet_s = try lstring(DllLoader.Allocator, "winhttp.dll");
//     // _ = try DllLoader.ZLoadLibrary(@as([:0]const u16, @ptrCast(wininet_s)));
//
//     // const ucrtbase_s = try lstring(DllLoader.Allocator, "ucrtbase.dll");
//     // _ = try DllLoader.ZLoadLibrary(@as([:0]const u16, @ptrCast(ucrtbase_s)));
//     //
//     // const gdi32full_s = try lstring(DllLoader.Allocator, "gdi32full.dll");
//     // _ = try DllLoader.ZLoadLibrary(@as([:0]const u16, @ptrCast(gdi32full_s)));
//     //
//     //
//     kernel32 = kernel32_m.NameExports;
//     ntdll = ntdll_m.NameExports;
//
//     const user32_s = try lstring(DllLoader.Allocator, "user32.dll");
//     _ = try DllLoader.ZLoadLibrary(@as([:0]const u16, @ptrCast(user32_s)));
//     std.debug.print("user32 looaded!\n", .{});
//     const user32 = DllLoader.LoadedDlls.get(user32_s).?.NameExports;
//
//     const MessageBoxW: *const fn (?*void, [*]const u16, [*]const u16, u64) c_int = @ptrCast(user32.get("MessageBoxW") orelse return dll.DllError.FuncResolutionFailed);
//     _ = MessageBoxW(null, (try clr.lstring(DllLoader.Allocator, "Text")).ptr, (try clr.lstring(DllLoader.Allocator, "Text2")).ptr, 0);
//
//     std.debug.print("Scope left fin!\n", .{});
// }
