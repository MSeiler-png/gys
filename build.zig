const std = @import("std");
const plugin_build = @import("plugin_build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = std.builtin.Mode.ReleaseSafe;

    const lib = b.addStaticLibrary("gyslib", "lib/gyslib.zig");
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.linkSystemLibraryName("glfw");
    lib.linkSystemLibraryName("vulkan");
    lib.linkSystemLibraryName("dl");
    lib.linkLibC();
    lib.install();

    const exe = b.addExecutable("gys", "exe/gys.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("gyslib", "lib/gyslib.zig");
    exe.linkSystemLibraryName("glfw");
    exe.linkSystemLibraryName("vulkan");
    exe.linkSystemLibraryName("dl");
    exe.linkLibC();
    plugin_build.generatePluginEntryPoint(exe, b.allocator);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
