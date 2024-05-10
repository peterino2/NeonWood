const std = @import("std");
const ArrayList = std.ArrayList;

value: i64,

const Self = @This();
// required functions
pub fn prettyPrint(self: @This(), _: anytype) void {
    std.debug.print("{}", .{self.value});
}

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = 0.0 };
}

pub fn asInteger(self: @This(), _: anytype) ?i64 {
    return self.value;
}

pub fn asFloat(self: @This(), _: anytype) ?f64 {
    return @intToFloat(f64, self.value);
}

pub fn asBoolean(self: @This(), _: anytype) ?bool {
    return if (self.value != 0) return true else return false;
}

pub fn compareEq(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asInteger")) return false;
    return self.value == right.asInteger() orelse return false;
}
pub fn compareNe(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asInteger")) return false;
    return self.value != right.asInteger() orelse return false;
}
pub fn compareLt(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asInteger")) return false;
    return self.value < right.asInteger() orelse return false;
}
pub fn compareGt(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asInteger")) return false;
    return self.value > right.asInteger() orelse return false;
}
pub fn compareLe(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asInteger")) return false;
    return self.value <= right.asInteger() orelse return false;
}
pub fn compareGe(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asInteger")) return false;
    return self.value >= right.asInteger() orelse return false;
}

pub fn asString(self: @This(), alloc: std.mem.Allocator) ?ArrayList(u8) {
    var rv = ArrayList(u8).init(alloc);
    std.fmt.format(rv.writer(), "{d}", .{self.value}) catch {
        rv.clearAndFree();
        rv.appendSlice("0") catch unreachable;
    };
    return rv;
}

pub fn deinit(_: *@This(), _: anytype) void {}
