const std = @import("std");

value: struct {},

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = .{} };
}

pub fn initWithValue(_: struct {}, _: std.mem.Allocator) @This() {
    return .{ .value = .{} };
}

pub fn prettyPrint(_: @This(), indentLevel: anytype) void {
    _ = indentLevel;
    return std.debug.print("BAD_TYPE", .{});
}

pub fn compareEq(_: @This(), right: anytype) bool {
    _ = right;
    return false;
}

pub fn compareNe(_: @This(), right: anytype) bool {
    _ = right;
    return true;
}

pub fn deinit(_: *@This(), _: anytype) void {}

pub fn allocPrint(self: @This(), allocator: std.mem.Allocator) ![]const u8 {
    _ = self;
    _ = allocator;
    return "";
}
