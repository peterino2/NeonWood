const std = @import("std");

value: f64,

const Self = @This();
// required functions
pub fn prettyPrint(self: @This(), _: anytype) void {
    std.debug.print("{}", .{self.value});
}

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = 0.0 };
}

// conversion functions
pub fn asString(self: @This(), alloc: anytype) ?std.ArrayList(u8) {
    var rv = std.ArrayList(u8).init(alloc);
    std.fmt.format(rv.writer(), "{d}", .{self.value}) catch {
        rv.clearAndFree();
        rv.appendSlice("0") catch unreachable;
    };
    return rv;
}

pub fn asInteger(self: @This(), _: anytype) ?i64 {
    return @floatToInt(i64, self.value);
}

pub fn asBoolean(self: @This(), _: anytype) ?bool {
    return if (self.value != 0.0) return true else return false;
}

pub fn asFloat(self: @This(), _: anytype) ?f64 {
    return self.value;
}

// comparisons
pub fn compareEq(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asFloat")) return false;
    return self.value == right.asFloat() orelse return false;
}
pub fn compareNe(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asFloat")) return false;
    return self.value != right.asFloat() orelse return false;
}
pub fn compareLt(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asFloat")) return false;
    return self.value < right.asFloat() orelse return false;
}
pub fn compareGt(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asFloat")) return false;
    return self.value > right.asFloat() orelse return false;
}
pub fn compareLe(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asFloat")) return false;
    return self.value <= right.asFloat() orelse return false;
}
pub fn compareGe(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asFloat")) return false;
    return self.value >= right.asFloat() orelse return false;
}

pub fn deinit(_: *@This(), _: anytype) void {}
