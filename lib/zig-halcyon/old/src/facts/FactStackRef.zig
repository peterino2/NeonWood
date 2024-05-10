const std = @import("std");
const utils = @import("factUtils.zig");

value: usize,

// required functions
pub fn prettyPrint(self: @This(), _: anytype) void {
    std.debug.print("{}", .{self.value});
}

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = 0 };
}

pub fn deinit(_: *@This(), _: anytype) void {}
