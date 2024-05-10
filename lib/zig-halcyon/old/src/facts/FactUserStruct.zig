const std = @import("std");

value: struct {},

// required functions
pub fn prettyPrint(self: @This(), _: anytype) void {
    std.debug.print("{}", .{self.value});
}

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = .{} };
}

pub fn deinit(_: *@This(), _: anytype) void {}
