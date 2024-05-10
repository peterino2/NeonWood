const std = @import("std");
const ArrayList = std.ArrayList;
const Self = @This();

value: *ArrayList(u8),

// required functions

pub fn prettyPrint(self: Self, _: anytype) void {
    std.debug.print("string: \"{s}\"", .{self.value.*.items});
}

// arg 0 is the payload object
// arg 1 is the the allocator
pub fn compareEq(self: Self, args: anytype) bool {
    if (@hasDecl(@TypeOf(args[0]), "doesUnionHave_asString_static")) {
        if (args[0].doesUnionHave_asString_static()) {
            return std.mem.eql(u8, self.value.*.items, args[0].asString_static() orelse return false);
        }
    }
    if (@hasDecl(@TypeOf(args[0]), "asString")) {
        var rhs = args[0].asString(args[1]) orelse return false;
        defer rhs.deinit();
        return std.mem.eql(u8, self.value.*.items, rhs.items);
    }
    return false;
}

pub fn compareNe(self: Self, args: anytype) bool {
    return !self.compareEq(args);
}

pub fn compareLt(self: Self, args: anytype) bool {
    if (!@hasDecl(@TypeOf(args), "asString")) return false;
    return self.value.*.items.len < (args[0].asString(args[1]) orelse return false).value.len;
}

pub fn compareGt(self: Self, args: anytype) bool {
    if (!@hasDecl(@TypeOf(args), "asString")) return false;
    return self.value.*.items.len > (args[0].asString(args[1]) orelse return false).value.len;
}

pub fn compareLe(self: Self, args: anytype) bool {
    if (!@hasDecl(@TypeOf(args), "asString")) return false;
    return self.value.*.items.len <= (args[0].asString(args[1]) orelse return false).value.len;
}

pub fn compareGe(self: Self, args: anytype) bool {
    if (!@hasDecl(@TypeOf(args), "asString")) return false;
    return self.value.*.items.len >= (args[0].asString(args[1]) orelse return false).value.len;
}

pub fn asString_static(self: @This(), _: anytype) ?[]const u8 {
    return self.value.*.items;
}

pub fn asString(self: @This(), alloc: anytype) ?ArrayList(u8) {
    var rv = ArrayList(u8).init(alloc);
    rv.appendSlice(self.value.*.items) catch return rv;
    return rv;
}

pub fn init(allocator: std.mem.Allocator) @This() {
    var rv = .{
        .value = allocator.create(ArrayList(u8)) catch unreachable,
    };

    rv.value.* = ArrayList(u8).init(allocator);
    return rv;
}

pub fn deinit(self: Self, args: anytype) void {
    self.value.*.deinit();
    args[0].destroy(self.value);
}

// optional functions
pub fn asInteger(self: @This(), _: anytype) ?i64 {
    return std.fmt.parseInt(i64, self.value.*.items, 0) catch return null;
}

pub fn asFloat(self: @This(), _: anytype) ?f64 {
    return std.fmt.parseFloat(f64, self.value.*.items) catch return null;
}

pub fn asBoolean(self: @This(), _: anytype) ?bool {
    _ = self;
    return false;
}
