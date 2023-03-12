const std = @import("std");
const glm = @cImport({
    @cDefine("GLM_FORCE_RADIANS", "");
    @cDefine("GLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("glm/vec4.hpp");
    @cInclude("glm/mat4x4.hpp");
});

const vulkan = @cImport({
    @cInclude("vulkan/vulkan.h");
});

/// Shows of what type of window the window is.
pub const WindowType = enum {
    /// This window is a full screen window which covers the entire usable application(except bars).
    /// This WindowType closes all window types except SideBarLeft, SideBarRight, TopBar, BottomBar, Popup, InlineHint or Dialog
    Full,

    /// This window covers the right half of the screen (except bars).
    RightHalf,

    /// This window covers the left half of the screen (except bars).
    LeftHalf,

    /// This window is a side bar at the right side of the screen.
    SideBarRight,

    /// This window is a side bar at the left side of the screen.
    SideBarLeft,

    /// This window is a bar at the top of the screen.
    TopBar,

    /// This window is a bar at the bottom of the screen.
    BottomBar,

    /// This window is a popup which means it is shown at the bottom right corner of the screen.
    Popup,

    /// This window is a hint (like a lsp dialog) which is layered above the other screen.
    InlineHint,

    /// This window is a dialog which means it is shown in the middle of the screen.
    Dialog,

    /// A custom type of window which was created.
    Custom,
};

/// Represents a window in this application.
pub const Window = struct {
    /// What type of window this window is.
    window_type: WindowType,

    /// The height of this window. This value is ignored as long as the WindowType is not Custom.
    height: u16,

    /// The width of this window. This value is ignored as long as the WindowType is not Custom.
    width: u16,
};

pub fn create() !void {
    _ = glfw.glfwInit();
    _ = glfw.glfwWindowHint(glfw.GLFW_CLIENT_API, glfw.GLFW_NO_API);
    const window = glfw.glfwCreateWindow(800, 600, "Vulkan window", null, null);
    var extensionCount: u32 = 0;
    _ = vulkan.vkEnumerateInstanceExtensionProperties(null, @ptrCast([*c]u32, &extensionCount), null);
    std.debug.print("{} extensions supported\n", .{extensionCount});

    while (glfw.glfwWindowShouldClose(window) != -1) {
        glfw.glfwPollEvents();
    }

    glfw.glfwDestroyWindow(window);
    glfw.glfwTerminate();
}
