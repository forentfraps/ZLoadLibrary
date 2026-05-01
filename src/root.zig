const std = @import("std");
const dll = @import("Winutils/dll.zig");

export fn DllMain(hInstance: *anyopaque, fdReason: c_int, reserved: *anyopaque) callconv(.winapi) c_long {
    _ = reserved;
    _ = fdReason;
    _ = hInstance;
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    dll.init_logger_zload();
    dll.DllLoader.init(allocator) catch unreachable;
    return 1;
}
