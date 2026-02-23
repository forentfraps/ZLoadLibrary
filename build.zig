const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = std.builtin.OptimizeMode.Debug;

    const syscall_dep = b.dependency("syscall_manager", .{ .target = target, .optimize = optimize });
    const syscall_module = syscall_dep.module("syscall_manager");

    const sys_logger_dep = b.dependency("sys_logger", .{ .target = target, .optimize = optimize });
    const sys_logger_module = sys_logger_dep.module("sys_logger");

    const nasm = b.addSystemCommand(&.{ "nasm", "-f", "win64" });
    nasm.addFileArg(b.path("src/Winutils/utils.asm"));
    nasm.addArg("-o");
    const utils_obj = nasm.addOutputFileArg("utils.o");
    nasm.expectExitCode(0);
    _ = nasm.captureStdOut(.{});

    const asm_step = b.step("asm", "Assemble Winutils utils.asm with nasm");
    asm_step.dependOn(&nasm.step);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("syscall_manager", syscall_module);
    exe_mod.addImport("sys_logger", sys_logger_module);
    exe_mod.addObjectFile(utils_obj);

    const exe = b.addExecutable(.{
        .name = "ZLoaderLibrary",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
