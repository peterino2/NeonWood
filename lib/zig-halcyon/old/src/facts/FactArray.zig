const std = @import("std");
const facts = @import("values.zig");
const utils = @import("factUtils.zig");

// this one is very much still in development
value: struct {},

pub fn init(alloc: std.mem.Allocator) @This() {
    _ = alloc;
    return .{ .value = .{} };
}

pub fn initWithValue(_: []const u8, _: std.mem.Allocator) @This() {
    return .{ .value = .{} };
}

pub fn allocPrint(self: @This(), _: anytype) ![]const u8 {
    _ = self;
    return try std.fmt.allocPrint(utils.printAllocator, "array: {{ }}", .{});
}

pub fn serialize(self: @This(), stream: anytype) void {
    _ = self;
    _ = stream;
}

pub fn prettyPrint(self: @This(), indentLevel: anytype) void {
    _ = self;
    utils.printIndents(indentLevel);
    std.debug.print("array: {{ }}", .{});
}

pub fn deinit(self: *@This(), _: anytype) void {
    _ = self;
}

// functions specific to FactArray
