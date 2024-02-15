const std = @import("std");

pub fn dupeZ(comptime T: type, allocator: std.mem.Allocator, source: []const T) ![]T {
    var buff: []T = try allocator.alloc(T, source.len + 1);
    for (source, 0..source.len) |s, i| {
        buff[i] = s;
    }
    buff[source.len] = 0;
    return buff;
}

pub fn dupe(comptime T: type, allocator: std.mem.Allocator, source: []const T) ![]T {
    var buff: []T = try allocator.alloc(T, source.len);
    for (source, 0..) |s, i| {
        buff[i] = s;
    }
    return buff;
}
