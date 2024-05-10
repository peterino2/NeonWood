const std = @import("std");
const values = @import("values.zig");
const utils = @import("factUtils.zig");
const fact_db = @import("fact_db.zig");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

const Initializer = values.Initializer;
const FactValue = values.FactValue;
const FactTypeInfo = values.FactTypeInfo;

const BuiltinFactTypes = utils.BuiltinFactTypes;
const MakeLabel = utils.MakeLabel;
const Label = utils.Label;
const TypeRef = utils.TypeRef;

// next thing to work on:
// type db and type info
//
// what kind of stuff do i want to be able to do with
// type info?
// - instantiate defaults - for pod types - done
// - is builtin or not - done
// - add initializers - done
// - rich name information - done
//
// type database operations:
// - add types - done
// - add customTypes
// - create value of type
// - create a reference to type
// - inspect and view all subtypes
// - is same as another type
//
// stuff I want from factValues with typeDatabase
// - get typeOf from a FactValue
// - deepCopy

const Self = @This();

types: ArrayList(FactTypeInfo),
typesByLabel: AutoHashMap(u32, TypeRef),
allocator: std.mem.Allocator,

pub fn init(alloc: std.mem.Allocator) !Self {
    var rv = Self{
        .types = ArrayList(FactTypeInfo).init(alloc),
        .typesByLabel = AutoHashMap(u32, TypeRef).init(alloc),
        .allocator = alloc,
    };

    std.debug.print("\n", .{});
    inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
        if (@intToEnum(BuiltinFactTypes, field.value) == BuiltinFactTypes.userStruct or
            @intToEnum(BuiltinFactTypes, field.value) == BuiltinFactTypes.userEnum)
        {
            continue;
        }

        var typeInfo = try FactTypeInfo.createDefaultTypeInfo(
            @intToEnum(BuiltinFactTypes, field.value),
            alloc,
        );
        // typeInfo.prettyPrint(0);
        try rv.addType(typeInfo);
        // std.debug.print("\n", .{});
    }

    return rv;
}

pub fn addType(self: *Self, typeInfo: FactTypeInfo) !void {
    const label = typeInfo.getLabel();

    if (self.typesByLabel.contains(label.hash)) {
        std.debug.print("[Error]: trying to add type of hash {s}", .{label.utf8});
        return;
    }

    var typeRef = TypeRef{ .id = self.types.items.len };

    try self.typesByLabel.put(label.hash, typeRef);
    try self.types.append(typeInfo);
    try std.testing.expect(self.typesByLabel.count() == self.types.items.len);
}

pub fn getTypeByLabelAsPointer(self: *Self, label: Label) ?*FactTypeInfo {
    if (self.typesByLabel.contains(label.hash)) {
        var ref = self.typesByLabel.getEntry(label.hash).?.value_ptr;
        return &self.types.items[ref.id];
    }
    return null;
}

pub fn getTypeByLabelAsRef(self: Self, label: Label) TypeRef {
    if (self.typesByLabel.contains(label.hash)) {
        var ref = self.typesByLabel.getEntry(label.hash).?.value_ptr;
        return ref.*;
    }
    return .{ .id = 0 };
}

pub fn deinit(self: *Self) void {
    var i: usize = 0;
    while (i < self.types.items.len) {
        self.types.items[i].deinit(.{self.allocator});
        i += 1;
    }
    self.types.deinit();
    self.typesByLabel.deinit();
}

test "030-TypeDatabase" {
    //var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    //defer arena.deinit();
    //var allocator = arena.allocator();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var db = try Self.init(allocator);
    defer db.deinit();

    try std.testing.expect(db.getTypeByLabelAsPointer(comptime MakeLabel("boolean")) != null);
    try std.testing.expect(db.getTypeByLabelAsRef(comptime MakeLabel("boolean")).id == @enumToInt(BuiltinFactTypes.boolean));
}
