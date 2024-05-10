const std = @import("std");
const values = @import("values.zig");
const utils = @import("factUtils.zig");

const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Initializer = values.Initializer;
const FactValue = values.FactValue;
const BuiltinFactTypes = utils.BuiltinFactTypes;
const MakeLabel = utils.MakeLabel;
const Self = @This();

const TypeInfoInner = struct {
    allocator: std.mem.Allocator,
    name: ArrayList(u8), // string value
    defaultValues: ArrayList(Initializer),
    typeTag: BuiltinFactTypes,
};

value: *TypeInfoInner,

pub fn getLabel(self: Self) utils.Label {
    return MakeLabel(self.value.*.name.items);
}

// required functions
pub fn prettyPrint(self: Self, indentLevel: anytype) void {
    if (self.value.*.name.items.len == 0) {
        std.debug.print("<type> BAD_TYPE", .{});
        return;
    } else {
        utils.printIndents(indentLevel);
        std.debug.print("<type> {s} ", .{self.value.*.name.items});
    }

    if (self.isBuiltin()) std.debug.print("(builtin)", .{});
    std.debug.print("{{\n", .{});

    var i: usize = 0;
    while (i < self.value.*.defaultValues.items.len) {
        const initializer = self.value.*.defaultValues.items[i];
        utils.printIndents(indentLevel + 1);
        std.debug.print("{s}:\n", .{initializer.label.utf8});
        initializer.value.prettyPrint(indentLevel + 2);
        std.debug.print(",\n", .{});
        i += 1;
    }
    utils.printIndents(indentLevel);
    std.debug.print("}}", .{});
}

pub fn init(alloc: std.mem.Allocator) Self {
    var rv = Self{ .value = undefined };

    rv.value = alloc.create(TypeInfoInner) catch unreachable;
    rv.value.* = .{
        .allocator = alloc,
        .name = ArrayList(u8).init(alloc),
        .defaultValues = ArrayList(Initializer).init(alloc),
        .typeTag = BuiltinFactTypes._BADTYPE,
    };

    return rv;
}

pub fn deinit(self: *Self, args: anytype) void {
    var allocator = self.value.*.allocator;

    self.value.*.name.deinit();
    var i: usize = 0;
    while (i < self.value.*.defaultValues.items.len) {
        self.value.*.defaultValues.items[i].value.deinit(args[0]);
        i += 1;
    }
    self.value.*.defaultValues.deinit();
    _ = allocator;
    allocator.destroy(self.value);
}

pub fn makeFromTag(tag: BuiltinFactTypes, alloc: std.mem.Allocator) !Self {
    var self = Self{ .value = try alloc.create(TypeInfoInner) };

    self.value.* = .{
        .name = ArrayList(u8).init(alloc),
        .defaultValues = ArrayList(Initializer).init(alloc),
        .typeTag = tag,
        .allocator = alloc,
    };

    try self.value.*.name.appendSlice(@tagName(tag));
    return self;
}

pub fn createDefaultTypeInfo(tag: BuiltinFactTypes, alloc: std.mem.Allocator) !Self {
    var typeInfo = try makeFromTag(tag, alloc);

    var i = Initializer{
        .label = MakeLabel(@tagName(tag)),
        .value = FactValue.makeDefault(tag, alloc),
    };

    try typeInfo.value.*.defaultValues.append(i);
    return typeInfo;
}

pub fn isBuiltin(self: Self) bool {
    return @enumToInt(self.value.typeTag) < @enumToInt(BuiltinFactTypes.userEnum);
}
// as string... could just be implemented with pretty print

test "020-typeInfo-init" {
    // create list of all builtin types
    {
        std.debug.print("\n", .{});
        inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
            var x = try createDefaultTypeInfo(@intToEnum(BuiltinFactTypes, field.value), std.testing.allocator);
            defer x.deinit(.{std.testing.allocator});
            x.prettyPrint(0);
            std.debug.print("\n", .{});
        }
    }
}
