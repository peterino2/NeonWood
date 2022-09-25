const std = @import("std");

pub fn dupeString(allocator: std.mem.Allocator, string: []const u8) ![]const u8 {
    var dupe = try allocator.alloc(u8, string.len);

    std.mem.copy(u8, dupe, string);

    return dupe;
}
