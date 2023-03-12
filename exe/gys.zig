const std = @import("std");
const gyslib = @import("gyslib");
const Window = gyslib.Window;
/// This is the main entry point of the application.
/// This code is only available to the core application and handels the execution of the plugins.
pub fn main() !void {
    try Window.create();
}
