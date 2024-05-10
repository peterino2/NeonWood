const std = @import("std");
const utils = @import("factUtils.zig");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const StringHashMap = std.StringHashMap;

const BuiltinFactTypes = utils.BuiltinFactTypes;
const TypeRef = utils.TypeRef;
const Label = utils.Label;
const MakeLabel = utils.MakeLabel;

pub const Fact_BADTYPE = @import("Fact_BADTYPE.zig");

pub const FactBoolean = @import("FactBoolean.zig");
pub const FactInteger = @import("FactInteger.zig");
pub const FactFloat = @import("FactFloat.zig");
pub const FactTypeRef = TypeRef;
pub const FactRef = @import("FactRef.zig");
pub const FactNull = @import("FactNull.zig");

pub const FactArray = @import("FactArray.zig");
pub const FactString = @import("FactString.zig");

pub const FactTypeInfo = @import("FactTypeInfo.zig");
pub const FactUserEnum = @import("FactUserEnum.zig");
pub const FactUserStruct = @import("FactUserStruct.zig");
pub const FactStackRef = @import("FactStackRef.zig");

pub const Initializer = struct {
    label: Label,
    value: FactValue,
};

pub const FactValue = union(BuiltinFactTypes) {
    // bad type
    _BADTYPE: Fact_BADTYPE,

    // pod types
    boolean: FactBoolean,
    integer: FactInteger,
    float: FactFloat,
    typeRef: FactTypeRef,
    ref: FactRef,
    nullType: FactNull,

    // array types
    array: FactArray,
    string: FactString,

    // user type system
    typeInfo: FactTypeInfo,
    userEnum: FactUserEnum,
    userStruct: FactUserStruct,

    // compiler/vm only types
    stackRef: FactStackRef,

    // helper functions.
    pub fn fromUtf8(value: []const u8, alloc: std.mem.Allocator) !@This() {
        var f = FactValue{ .string = .{ .value = undefined } };
        f.string.value = try alloc.create(ArrayList(u8));
        f.string.value.* = ArrayList(u8).init(alloc);
        try f.string.value.*.appendSlice(value);
        return f;
    }

    // Required functions
    pub fn prettyPrint(self: @This(), indentLevel: usize) void {
        var i = indentLevel;
        while (i > 0) {
            std.debug.print("  ", .{});
            i -= 1;
        }
        if (indentLevel > 6) {
            std.debug.print("... ", .{});
            return;
        }
        _ = utils.implement_func_for_tagged_union(self, "prettyPrint", void, indentLevel);
    }
    pub fn compareEq(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareEq", bool, .{ other, alloc }) orelse false;
    }
    pub fn compareNe(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareNe", bool, .{ other, alloc }) orelse false;
    }
    pub fn compareLt(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareLt", bool, .{ other, alloc }) orelse false;
    }
    pub fn compareGt(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareGt", bool, .{ other, alloc }) orelse false;
    }
    pub fn compareLe(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareLe", bool, .{ other, alloc }) orelse false;
    }
    pub fn compareGe(self: @This(), other: @This(), alloc: std.mem.Allocator) bool {
        return utils.implement_func_for_tagged_union(self, "compareGe", bool, .{ other, alloc }) orelse false;
    }

    pub fn makeDefault(tag: BuiltinFactTypes, alloc: std.mem.Allocator) @This() {
        inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
            if (@intToEnum(BuiltinFactTypes, field.value) == tag) {
                var x: @This() = undefined;
                _ = x;
                var f = @unionInit(@This(), field.name, @field(@TypeOf(@field(x, field.name)), "init")(alloc));
                return f;
            }
        }

        std.debug.print("ERROR: missing init implementation for {}\n", .{tag});

        unreachable;
    }

    // optional interface functions
    pub fn asString(self: @This(), alloc: std.mem.Allocator) ?ArrayList(u8) {
        return utils.implement_func_for_tagged_union(self, "asString", ArrayList(u8), alloc);
    }

    pub fn asString_static(self: @This()) ?[]const u8 {
        return utils.implement_func_for_tagged_union(self, "asString_static", []const u8, .{});
    }

    pub fn asFloat(self: @This()) ?f64 {
        return utils.implement_func_for_tagged_union(self, "asFloat", f64, .{});
    }

    pub fn asInteger(self: @This()) ?i64 {
        return utils.implement_func_for_tagged_union(self, "asInteger", i64, .{});
    }

    pub fn asBoolean(self: @This()) ?bool {
        return utils.implement_func_for_tagged_union(self, "asBoolean", bool, .{});
    }

    pub fn doesUnionHave_asString_static(self: @This()) bool {
        inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
            if (@intToEnum(BuiltinFactTypes, field.value) == self) {
                if (@hasDecl(@TypeOf(@field(self, field.name)), "asString_static")) {
                    return true;
                }
            }
        }
        return false;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        // _ = self;
        return utils.implement_nonconst_func_for_tagged_union(self, "deinit", void, .{allocator});
    }
};
