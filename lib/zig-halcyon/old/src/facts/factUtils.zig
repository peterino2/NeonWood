// shared utilities for all fact types.

const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;
const showDebug = false;

pub var printAllocator: std.mem.Allocator = std.heap.c_allocator;

pub fn printIndents(indentLevel: usize) void {
    var i = indentLevel;
    while (i > 0) : (i -= 1) {
        std.debug.print("  ", .{});
    }
}

pub fn implement_nonconst_func_for_tagged_union(
    self: anytype,
    comptime funcName: []const u8,
    comptime returnType: type,
    args: anytype,
) returnType {
    const Self = @TypeOf(self.*);
    inline for (@typeInfo(std.meta.Tag(Self)).Enum.fields) |field| {
        if (@intToEnum(std.meta.Tag(Self), field.value) == self.*) {
            if (@hasDecl(@TypeOf(@field(self, field.name)), funcName)) {
                return @field(@field(self, field.name), funcName)(args);
            }
        }
    }
    unreachable;
}

pub fn implement_func_for_tagged_union_nonull(
    self: anytype,
    comptime funcName: []const u8,
    comptime returnType: type,
    args: anytype,
) returnType {
    const Self = @TypeOf(self);
    inline for (@typeInfo(std.meta.Tag(Self)).Enum.fields) |field| {
        if (@intToEnum(std.meta.Tag(Self), field.value) == self) {
            if (showDebug) std.debug.print("Executing func {s} for tag {s}\n", .{ funcName, field.name });
            if (@hasDecl(@TypeOf(@field(self, field.name)), funcName)) {
                return @field(@field(self, field.name), funcName)(args);
            }
        }
    }

    if (showDebug) std.debug.print("missing implementation of `{s}` for {any}\n", .{ funcName, @as(BuiltinFactTypes, self) });
    unreachable;
}

pub fn implement_func_for_tagged_union(
    self: anytype,
    comptime funcName: []const u8,
    comptime returnType: type,
    args: anytype,
) ?returnType {
    const Self = @TypeOf(self);
    inline for (@typeInfo(std.meta.Tag(Self)).Enum.fields) |field| {
        if (@intToEnum(std.meta.Tag(Self), field.value) == self) {
            if (showDebug) std.debug.print("Executing func {s} for tag {s}\n", .{ funcName, field.name });
            if (@hasDecl(@TypeOf(@field(self, field.name)), funcName)) {
                return @field(@field(self, field.name), funcName)(args);
            }
        }
    }

    if (showDebug) std.debug.print("missing implementation of `{s}` for {any}\n", .{ funcName, @as(BuiltinFactTypes, self) });
    return null;
}

pub const BuiltinFactTypes = enum(u8) {
    _BADTYPE, // invalid type, used to mark issues with serdes

    // ordinal types
    boolean,
    integer,
    float,
    typeRef, // use with a TypeDatabase to get type information
    ref, // use with a FactsDatabase to get values.
    nullType, // represents a nulltype

    // allocated types
    array, // array type, contains a typeRef and an array of Facts of that type
    string, // string type,

    // user facing type system
    typeInfo, // this is an entry in the type database, contains description and prototype of what a type is.
    userEnum, // user defined enum type. It's backed by an integer type
    userStruct, // this is a struct type, contains a hashmap of fields

    // instruction only types
    stackRef, // like a factRef, but for the stack
};

pub const Label = struct {
    utf8: []const u8,
    hash: u32,

    pub fn fromUtf8(source: []const u8) Label {
        const hashFunc = std.hash.CityHash32.hash;

        var self = .{
            .utf8 = source,
            .hash = hashFunc(source),
        };
        return self;
    }
};

pub fn MakeLabel(utf8: []const u8) Label {
    return Label.fromUtf8(utf8);
}

pub const TypeRef = struct {
    id: usize,

    pub fn init(_: std.mem.Allocator) @This() {
        return .{ .id = 0 };
    }
    pub fn deinit(_: @This(), _: anytype) void {}
    pub fn prettyPrint(self: @This(), _: anytype) void {
        std.debug.print("<type: {d}>", .{self.id});
    }
};

pub const FactsError = error{
    CompareAgainstBadRef,
    InvalidTypeComparison,
    InvalidType,
};
