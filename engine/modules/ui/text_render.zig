const std = @import("std");

pub const TextRender = struct {
    allocator: std.mem.Allocator,
    text: []u8,
};
