const std = @import("std");
const plugins = @import("plugins.zig");

/// This function executes the startUp function of each plugin.
/// It provides the current ApplicationState and an allocator.
pub fn pluginStart(state: ApplicationState, allocator: std.mem.Allocator) !void {
    inline for (plugins.PluginList) |plugin| {
        plugin.onStartup(state, allocator) catch |err| {
            std.log.err("Plugin {s} failed with error {}", .{ @typeName(plugin), err });
        };
    }
}
