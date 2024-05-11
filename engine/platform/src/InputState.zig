const std = @import("std");
const core = @import("core");

mousePos: core.Vector2 = .{},
keydown: [256]bool = std.mem.zeroes([256]bool),
