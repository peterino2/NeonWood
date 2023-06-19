const std = @import("std");

pub const TextRender = struct {
    allocator: std.mem.Allocator,
    atlas: *FontAtlas,
    text: []u8,
    
};
