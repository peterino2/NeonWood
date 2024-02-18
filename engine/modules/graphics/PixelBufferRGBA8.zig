pixels: []u8,
extent: core.Vector2u,

const std = @import("std");
const core = @import("../core.zig");

pub fn init(allocator: std.mem.Allocator, extent: core.Vector2u) !@This() {
    return .{
        .pixels = try allocator.alloc(u8, extent.x * extent.y * 4),
        .extent = extent,
    };
}

pub fn clear(self: *@This(), clearColor: core.Color) void {
    _ = clearColor;
    _ = self;
}
