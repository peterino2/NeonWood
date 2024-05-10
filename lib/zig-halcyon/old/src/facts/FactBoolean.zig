const std = @import("std");
const Self = @This();

// all types must implement a value member,
// and all the functions in this interface

value: bool,

// required functions
pub fn prettyPrint(self: @This(), _: anytype) void {
    std.debug.print("{}", .{self.value});
}

pub fn init(_: std.mem.Allocator) @This() {
    return .{ .value = false };
}

pub fn deinit(_: @This(), _: anytype) void {}

pub fn compareEq(self: Self, args: anytype) bool {
    const right = args[0];
    if (@hasDecl(@TypeOf(right), "asBoolean")) {
        return self.value == right.asBoolean() orelse return false;
    } else {
        return false;
    }
}

pub fn compareNe(self: Self, args: anytype) bool {
    const right = args[0];
    return if (@hasDecl(@TypeOf(right), "asBoolean"))
        return self.value != right.asBoolean() orelse return false
    else
        false;
}

pub fn compareLt(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asBoolean")) return false;
    const right_value = right.asBoolean() orelse return false;
    if (right_value == true and self.value == false) return true;
    return false;
}

pub fn compareGt(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asBoolean")) return false;
    const right_value = right.asBoolean() orelse return false;
    if (right_value == false and self.value == true) return true;
    return false;
}

pub fn compareLe(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asBoolean")) return false;
    const right_value = right.asBoolean() orelse return false;
    if (right_value == true and self.value == false) return true;
    return self.value == right_value;
}

pub fn compareGe(self: Self, args: anytype) bool {
    const right = args[0];
    if (!@hasDecl(@TypeOf(right), "asBoolean")) return false;
    const right_value = right.asBoolean() orelse return false;
    if (right_value == false and self.value == true) return true;
    return self.value == right_value;
}

// optional functions
// conversion functions
pub fn asString(self: @This(), alloc: anytype) std.ArrayList(u8) {
    var rv = std.ArrayList(u8).init(alloc);
    if (self.value) {
        rv.appendSlice("true") catch return rv;
    } else {
        rv.appendSlice("false") catch return rv;
    }
    return rv;
}

pub const trueString: []const u8 = "true";
pub const falseString: []const u8 = "false";

pub fn asString_static(self: @This(), _: anytype) ?[]const u8 {
    if (self.value) {
        return trueString;
    } else {
        return falseString;
    }
}

pub fn asInteger(self: @This(), _: anytype) ?i64 {
    return if (self.value) return 1 else return 0;
}

pub fn asBoolean(self: @This(), _: anytype) ?bool {
    return self.value;
}

pub fn asFloat(self: @This(), _: anytype) ?f64 {
    return if (self.value) return 1.0 else return 0.0;
}
