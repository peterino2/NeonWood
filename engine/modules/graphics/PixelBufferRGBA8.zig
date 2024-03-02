pixels: []u8,
extent: core.Vector2i,

const std = @import("std");
const core = @import("../core.zig");

pub fn init(allocator: std.mem.Allocator, extent: core.Vector2i) !@This() {
    return .{
        .pixels = try allocator.alignedAlloc(u8, 8, @intCast(extent.x * extent.y * 4)),
        .extent = extent,
    };
}

pub fn clear(self: *@This(), clearColor: core.Color) void {
    var as32: []u32 = undefined;
    as32.len = self.pixels.len / 4;
    as32.ptr = @alignCast(@ptrCast(self.pixels.ptr));

    @memset(as32, @as(u32, @bitCast(clearColor)));
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    allocator.free(self.pixels);
}

pub inline fn getPixel(self: *@This(), position: core.Vector2i) *core.Color {
    var offset = position.x * position.y * 4;
    var r: *u8 = &self.pixels[@intCast(offset)];

    return @as(*core.Color, @alignCast(@ptrCast(r)));
}
