const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{ .os_tag = .windows });
    // const optimize = std.builtin.OptimizeMode.Debug;
    const optimize = b.standardOptimizeOption(.{});

    const syscall_dep = b.dependency("syscall_manager", .{});
    const syscall_module = syscall_dep.module("syscall_manager");
    const sys_logger_dep = b.dependency("sys_logger", .{});
    const sys_logger_module = sys_logger_dep.module("sys_logger");
    const zigwin32 = b.dependency("zigwin32", .{});
    const zigwin32_module = zigwin32.module("win32");

    syscall_module.optimize = optimize;
    sys_logger_module.optimize = optimize;
    zigwin32_module.optimize = optimize;

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.red_zone = true;
    // exe_mod.link_libc = true;
    exe_mod.addIncludePath(b.path("src/Winutils/sig_headers"));
    exe_mod.strip = false;
    exe_mod.error_tracing = true;
    exe_mod.addImport("zigwin32", zigwin32_module);
    exe_mod.addImport("syscall_manager", syscall_module);
    exe_mod.addImport("sys_logger", sys_logger_module);

    const exe = b.addExecutable(.{
        .name = "ZLoaderLibrary",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const dllmain_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    dllmain_mod.addIncludePath(b.path("src/Winutils/sig_headers"));
    dllmain_mod.strip = false;
    dllmain_mod.error_tracing = true;
    dllmain_mod.addImport("zigwin32", zigwin32_module);
    dllmain_mod.addImport("syscall_manager", syscall_module);
    dllmain_mod.addImport("sys_logger", sys_logger_module);

    const dllmain_lib = b.addLibrary(.{
        .name = "ZLoadLibrary",
        .linkage = .dynamic,
        .root_module = dllmain_mod,
    });
    b.installArtifact(dllmain_lib);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const check_step = b.step("check", "Run the app");
    check_step.dependOn(&exe.step);
}
