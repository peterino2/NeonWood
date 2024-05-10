const std = @import("std");
const values = @import("values.zig");
const utils = @import("factUtils.zig");
const TypeDatabase = @import("TypeDatabase.zig");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

const Initializer = values.Initializer;
const FactValue = values.FactValue;
const FactRef = values.FactRef;
const FactTypeInfo = values.FactTypeInfo;

const BuiltinFactTypes = utils.BuiltinFactTypes;
const MakeLabel = utils.MakeLabel;
const Label = utils.Label;
const TypeRef = utils.TypeRef;

pub const FactDatabase = struct {
    types: TypeDatabase,

    names: ArrayList(Label),
    data: ArrayList(FactValue), // we will typically only ever access these guys through pointers
    factsByLabel: AutoHashMap(u32, usize),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        var self: Self = .{
            .types = try TypeDatabase.init(allocator),
            .data = ArrayList(FactValue).init(allocator),
            .names = ArrayList(Label).init(allocator),
            .factsByLabel = AutoHashMap(u32, usize).init(allocator),
            .allocator = allocator,
        };

        return self;
    }

    pub fn getFactFromRef(self: *Self, ref: FactRef) ?*FactValue {
        return &self.data.items[ref.value];
    }

    pub fn getFactAsRefByLabel(self: Self, label: Label) ?FactRef {
        var index = self.factsByLabel.get(label.hash);

        if (index != null) {
            return FactRef{ .value = index.? };
        }

        return null;
    }

    pub fn getOrAddFactInner(self: *Self, label: Label) !*FactValue {
        if (self.factsByLabel.contains(label.hash)) {
            var index = self.factsByLabel.getEntry(label.hash).?.value_ptr.*;
            return &self.data.items[index];
        }

        var index = self.data.items.len;
        try self.factsByLabel.put(label.hash, index);
        try self.names.append(label);

        return try self.data.addOne();
    }

    pub fn newFact(self: *Self, label: Label, typeTag: BuiltinFactTypes) !*FactValue {
        var x = try self.getOrAddFactInner(label);
        x.* = FactValue.makeDefault(typeTag, self.allocator);
        return x;
    }

    pub fn getFactByLabel(self: Self, label: Label) ?*FactValue {
        if (!self.factsByLabel.contains(label.hash)) {
            return null;
        }
        return &self.data.items[(self.factsByLabel.getPtr(label.hash)).?.*];
    }

    pub fn compare(self: Self, comptime innerFuncName: []const u8, left: Label, right: Label) !bool {
        const BadVal = FactValue.makeDefault(BuiltinFactTypes._BADTYPE, self.allocator);

        var l: *const FactValue = &BadVal;
        var r: *const FactValue = &BadVal;

        if (self.factsByLabel.contains(left.hash)) {
            l = self.getFactByLabel(left).?;
        }
        if (self.factsByLabel.contains(right.hash)) {
            r = self.getFactByLabel(right).?;
        }

        //return l.compareEq(r.*, self.allocator);

        return @field(l.*, innerFuncName)(r.*, self.allocator);
    }

    pub fn compareEq(self: Self, left: Label, right: Label) !bool {
        return try self.compare("compareEq", left, right);
    }

    pub fn compareNe(self: Self, left: Label, right: Label) !bool {
        return try self.compare("compareNe", left, right);
    }

    pub fn compareGe(self: Self, left: Label, right: Label) !bool {
        return try self.compare("compareGe", left, right);
    }

    pub fn compareGt(self: Self, left: Label, right: Label) !bool {
        return try self.compare("compareGt", left, right);
    }

    pub fn compareLt(self: Self, left: Label, right: Label) !bool {
        return try self.compare("compareLt", left, right);
    }

    pub fn compareLe(self: Self, left: Label, right: Label) !bool {
        return try self.compare("compareLe", left, right);
    }

    pub fn deinit(self: *Self) void {
        self.factsByLabel.deinit();

        var i: usize = 0;
        while (i < self.data.items.len) : (i += 1) {
            self.data.items[i].deinit(self.allocator);
        }

        self.data.deinit();
        self.names.deinit();
        self.types.deinit();
    }

    pub fn prettyDumpStringAlloc(self: Self, allocator: std.mem.Allocator) ![]const u8 {
        var ostr = ArrayList(u8).init(allocator);
        defer ostr.deinit();
        {
            var s = try std.fmt.allocPrint(allocator, "database itemCount: {d}", .{self.data.items.len});
            defer allocator.free(s);
            try ostr.appendSlice(s);
        }

        for (self.names.items, 0..) |name, i| {
            var s = try std.fmt.allocPrint(allocator, "\n {d}: name={s}", .{ i, name.utf8 });
            defer allocator.free(s);
            try ostr.appendSlice(s);
        }

        for (self.data.items, 0..) |item, i| {
            std.debug.print("\n {d}: ", .{i});
            item.prettyPrint(0);
        }

        var rv = try allocator.alloc(u8, ostr.items.len);
        @memcpy(rv.ptr, ostr.items.ptr, ostr.items.len);

        return rv;
    }

    pub fn prettyPrint(self: Self) void {
        var x = self.prettyDumpStringAlloc(self.allocator) catch unreachable;
        defer self.allocator.free(x);

        std.debug.print("\n{s}\n", .{x});
    }
};

test "FactsDatabase" {
    const expect = std.testing.expect;
    var factDb = try FactDatabase.init(std.testing.allocator);
    defer factDb.deinit();

    var variable = try factDb.getOrAddFactInner(MakeLabel("variable"));
    variable.* = FactValue.makeDefault(BuiltinFactTypes.boolean, factDb.allocator);
    variable.*.boolean.value = true;

    var variable2 = try factDb.newFact(MakeLabel("variable2"), BuiltinFactTypes.boolean);
    variable2.*.boolean.value = true;

    var variable3 = try factDb.newFact(MakeLabel("variable3"), BuiltinFactTypes.boolean);
    variable3.*.boolean.value = false;

    try expect(factDb.data.items.len == 3);
    // try std.testing.expect(factDb.data.items[0].compareEq(factDb.data.items[1], factDb.allocator));
    try expect(variable.compareEq(variable2.*, factDb.allocator));
    try expect(try factDb.compareEq(MakeLabel("variable"), MakeLabel("variable2")));
    try expect(try factDb.compareNe(MakeLabel("variable3"), MakeLabel("variable2")));
    try expect(try factDb.compareLe(MakeLabel("variable3"), MakeLabel("variable2")));
    try expect(try factDb.compareLt(MakeLabel("variable3"), MakeLabel("variable2")));
    try expect(try factDb.compareGt(MakeLabel("variable2"), MakeLabel("variable3")));
    try expect(try factDb.compareGe(MakeLabel("variable2"), MakeLabel("variable3")));
    try expect(try factDb.compareGe(MakeLabel("variable2"), MakeLabel("variable2")));

    var integer0 = try factDb.newFact(MakeLabel("variable3"), BuiltinFactTypes.integer);
    integer0.deinit(factDb.allocator);
    integer0.*.integer.value = 420;

    var integer1 = try factDb.newFact(MakeLabel("variable2"), BuiltinFactTypes.integer);
    integer1.deinit(factDb.allocator);
    integer1.*.integer.value = 421;

    var string0 = try factDb.newFact(MakeLabel("variable4"), BuiltinFactTypes.string);
    string0.deinit(factDb.allocator);
    string0.* = try FactValue.fromUtf8("420", factDb.allocator);

    try expect(factDb.data.items.len == 4);

    try expect(try factDb.compareGe(MakeLabel("variable2"), MakeLabel("variable3")));
    try expect(try factDb.compareEq(MakeLabel("variable4"), MakeLabel("variable3")));

    try expect(try factDb.compareNe(MakeLabel("badRef"), MakeLabel("variable2")));
}
