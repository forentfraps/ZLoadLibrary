const std = @import("std");
const dll = @import("Winutils/dll.zig");
const clr = @import("Winutils/clr.zig");
const logger = @import("sys_logger");

const W = std.unicode.utf8ToUtf16LeStringLiteral;
const win = std.os.windows;

const pref_list = [_][]const u8{"MAIN"};
const colour = logger.SysLoggerColour;
const colour_list = [_]colour{colour.green};

// Uppercase lookup helper to match NameExports keys

pub fn main() !void {

    // log.enabled = false;
    // _ = win.kernel32.LoadLibraryW(W("win32u.dll"));
    // std.debug.print("Starting reflective load test...\n", .{});

    // Debug allocator makes it easy to catch leaks / double frees while iterating
    var gpa = std.heap.DebugAllocator(.{}){};
    {
        var log = logger.SysLogger.init(colour_list.len, pref_list, colour_list);
        log.enabled = true;
        const allocator = gpa.allocator();

        dll.init_logger_zload();
        try dll.DllLoader.init(allocator);
        // defer dll.DllLoader.deinit();
        const loader = &dll.GLOBAL_DLL_LOADER;

        var it = loader.LoadedDlls.iterator();
        while (it.next()) |key| {
            log.info16("Loaded dll {d}: ", .{key.key_ptr.*.len}, key.key_ptr.*);
        }
        // try test_x64dbg(allocator);

        try test_sxs(allocator);
        // try test_msgexternal(allocator);

        std.debug.print("Done.\n", .{});
    }
    // if (gpa.detectLeaks() != 0) {
    // std.debug.print("Leaking!\n", .{});
    // }
}
pub fn test_x64dbg(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\Users\\pseud\\Desktop\\release\\x64\\x64dbg.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse @panic("Failed to map EXE");
    try loader.RunExe(exe);
}

pub fn test_dialog(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\coding\\win_rofls\\ZLoadLibrary\\src\\Tests\\file_dialog.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse @panic("Failed to map EXE");
    try loader.RunExe(exe);
}
pub fn test_msginteral(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var user32_name16 = try dll.OwnedZ16.fromU8(allocator, "user32.dll");
    defer user32_name16.deinit();
    const user32 = (try loader.ZLoadLibrary(user32_name16.view())) orelse @panic("Failed to load");
    // std.debug.print("user32 loaded!\n", .{});

    // Grab MessageBoxW from the (uppercased-key) export map
    const MessageBoxW =
        try user32.getProc(fn (?*anyopaque, [*]const u16, [*]const u16, u32) callconv(.winapi) c_int, "MessageBoxW");

    var text = try dll.OwnedZ16.fromU8(allocator, "Hello from reflective loader!");
    var title = try dll.OwnedZ16.fromU8(allocator, "It works !!");
    defer {
        text.deinit();
        title.deinit();
    }

    // HWND null, OK button
    _ = MessageBoxW(null, text.raw.ptr, title.raw.ptr, 0);
}
pub fn test_msgexternal(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\coding\\win_rofls\\purgatory_packer\\src\\test_bin\\test_msgbox.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse @panic("Failed to map EXE");
    try loader.RunExe(exe);
}

pub fn test_sxs(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\coding\\win_rofls\\ZLoadLibrary\\src\\Tests\\sxs_minimal.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse @panic("Failed to map EXE");
    try loader.RunExe(exe);
}
