const std = @import("std");

pub fn dupeString(allocator: std.mem.Allocator, string: []const u8) ![]u8 {
    const dupe = try allocator.alloc(u8, string.len);

    std.mem.copyForwards(u8, dupe, string);

    return dupe;
}
