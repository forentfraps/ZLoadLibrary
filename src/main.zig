const std = @import("std");
const dll = @import("Winutils/dll.zig");
const clr = @import("Winutils/clr.zig");
const W = std.unicode.utf8ToUtf16LeStringLiteral;
const win = std.os.windows;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    {
        const allocator = gpa.allocator();
        dll.init_logger_zload();
        dll.DllLoader.init(allocator) catch unreachable;
        // defer dll.DllLoader.deinit();
        const loader = &dll.GLOBAL_DLL_LOADER;
        var it = loader.LoadedDlls.iterator();
        while (it.next()) |key| {
            dll.log.info16("Loaded dll {d}: ", .{key.key_ptr.*.len}, key.key_ptr.*);
        }
        // try test_x64dbg(allocator);
        // try test_cs2(allocator);
        // try test_firefox(allocator);
        // test_msginteral(allocator) catch unreachable;
        // try test_sxs(allocator);
        // try test_dialog(allocator);
        // try test_urlmon(allocator);
        try test_winhttp(allocator);
        // try test_notepadpp(allocator);
        // try test_msgexternal(allocator);

        std.debug.print("Done.", .{});
    }
    // if (gpa.detectLeaks() != 0) {
    // std.debug.print("Leaking!", .{});
    // }
}

pub fn test_x64dbg(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\Users\\pseud\\Desktop\\release\\x64\\x64dbg.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse unreachable;
    try loader.RunExe(exe);
}
pub fn test_firefox(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\Program Files\\Mozilla Firefox\\updated\\firefox.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse unreachable;
    try loader.RunExe(exe);
}
pub fn test_cs2(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "Q:\\steam\\steamapps\\common\\Counter-Strike Global Offensive\\game\\bin\\win64\\cs2.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse unreachable;
    try loader.RunExe(exe);
}

pub fn test_dialog(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\coding\\win_rofls\\ZLoadLibrary\\src\\Tests\\file_dialog.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse unreachable;
    try loader.RunExe(exe);
}

pub fn test_msginteral(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var user32_name16 = try dll.OwnedZ16.fromU8(allocator, "user32.dll");
    defer user32_name16.deinit();
    const user32 = (try loader.ZLoadLibrary(user32_name16.view())) orelse unreachable;
    const MessageBoxW =
        try user32.getProc(fn (?*anyopaque, [*]const u16, [*]const u16, u32) callconv(.winapi) c_int, "MessageBoxW");
    var text = try dll.OwnedZ16.fromU8(allocator, "Hello from reflective loader!");
    var title = try dll.OwnedZ16.fromU8(allocator, "It works !!");
    defer {
        text.deinit();
        title.deinit();
    }
    _ = MessageBoxW(null, text.raw.ptr, title.raw.ptr, 0);
}

pub fn test_x64gui(allocator: std.mem.Allocator) !void {
    _ = allocator;
    _ = dll.LoadLibraryA_stub("x64gui.dll");
}

pub fn test_msgexternal(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\coding\\win_rofls\\purgatory_packer\\src\\test_bin\\test_msgbox.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse unreachable;
    try loader.RunExe(exe);
}

pub fn test_sxs(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\coding\\win_rofls\\ZLoadLibrary\\src\\Tests\\sxs_minimal.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse unreachable;
    try loader.RunExe(exe);
}
pub fn test_notepadpp(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\Windows\\System32\\notepad.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse unreachable;
    try loader.RunExe(exe);
}

pub fn test_urlmon(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    // var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\coding\\win_rofls\\ZLoadLibrary\\src\\Tests\\urlmon_zones.exe");
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\coding\\win_rofls\\ZLoadLibrary\\src\\Tests\\urlmon_imports.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse unreachable;
    try loader.RunExe(exe);
}

pub fn test_winhttp(allocator: std.mem.Allocator) !void {
    const loader = &dll.GLOBAL_DLL_LOADER;
    var exe_name = try dll.OwnedZ16.fromU8(allocator, "C:\\coding\\win_rofls\\ZLoadLibrary\\src\\Tests\\winhttp_test.exe");
    defer exe_name.deinit();
    const exe = (try loader.ZLoadExe(exe_name.view())) orelse unreachable;
    try loader.RunExe(exe);
}
