const std = @import("std");
const plugin_build = @import("plugin_build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = std.builtin.Mode.ReleaseSafe;
    const exe = b.addExecutable("gys", "src/gys.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    plugin_build.generatePluginEntryPoint(exe, b.allocator);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/gys.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
