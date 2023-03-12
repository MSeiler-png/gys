const std = @import("std");
const Window = @import("gyslib.zig").Window;

/// This struct provides the information needed for understanding and extending the application
pub const ApplicationState = struct { windows: []Window };
