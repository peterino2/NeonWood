const std = @import("std");
const values = @import("values.zig");
const utils = @import("factUtils.zig");
const facts = @import("facts.zig");

const ArrayList = std.ArrayList;
const BuiltinFactTypes = utils.BuiltinFactTypes;
const FactValue = values.FactValue;

const t_allocator = std.testing.allocator;
pub fn stringTest(string: anytype, expected: []const u8) !void {
    // float to string
    var x = string.asString(t_allocator).?;
    defer x.deinit();
    std.debug.print("{s} vs {s}\n", .{ x.items, expected });
    try std.testing.expect(std.mem.eql(u8, expected, x.items));
}

pub fn stringConversionTestLtFloat(istr: anytype, expected: anytype) !void {
    var string = FactValue{ .string = .{ .value = try t_allocator.create(ArrayList(u8)) } };
    string.string.value.* = ArrayList(u8).init(t_allocator);
    defer string.deinit(t_allocator);
    try string.string.value.appendSlice(istr);

    try std.testing.expect(string.asFloat().? < expected);
}

pub fn stringConversionTestLtInt(istr: anytype, expected: anytype) !void {
    var string = FactValue{ .string = .{ .value = try t_allocator.create(ArrayList(u8)) } };
    string.string.value.* = ArrayList(u8).init(t_allocator);
    defer string.deinit(t_allocator);
    try string.string.value.appendSlice(istr);

    try std.testing.expect(string.asInteger().? < expected);
}

test "015-conversions-string" {
    // probably the most complicated one
    var int1 = FactValue{ .integer = .{ .value = 420 } };
    var float1 = FactValue{ .float = .{ .value = 420.0 } };

    try stringConversionTestLtFloat("420", 421);
    try stringConversionTestLtFloat("421", 422);
    try stringConversionTestLtFloat("420.3", 421);
    try stringConversionTestLtFloat("420.0", 420.6);
    try stringConversionTestLtFloat("0x420", 0x421);

    try stringConversionTestLtInt("420", 421);
    try stringConversionTestLtInt("421", 422);
    try stringConversionTestLtInt("0x420", 0x421);

    var trueBool = FactValue{ .boolean = .{ .value = true } };
    try stringTest(int1, "420");
    try stringTest(float1, "420");
    try stringTest(trueBool, "true");
}

test "014-conversions-integer" {
    // float to boolean
    var int1 = FactValue{ .integer = .{ .value = 420 } };
    var int2 = FactValue{ .integer = .{ .value = 0 } };
    var int3 = FactValue{ .integer = .{ .value = -12 } };

    var float1 = FactValue{ .float = .{ .value = 420.69 } };
    var float2 = FactValue{ .float = .{ .value = 0.0 } };
    var float3 = FactValue{ .float = .{ .value = -12.0 } };

    var trueBool = FactValue{ .boolean = .{ .value = true } };
    var falseBool = FactValue{ .boolean = .{ .value = false } };

    try std.testing.expect(trueBool.compareEq(int1, std.testing.allocator));
    try std.testing.expect(trueBool.compareEq(int3, std.testing.allocator));
    try std.testing.expect(trueBool.compareNe(int2, std.testing.allocator));
    try std.testing.expect(falseBool.compareEq(int2, std.testing.allocator));

    try std.testing.expect(int1.compareGe(int2, std.testing.allocator));
    try std.testing.expect(int1.compareGt(int3, std.testing.allocator));

    try std.testing.expect(int2.compareGe(int2, std.testing.allocator));
    try std.testing.expect(int2.compareGe(int3, std.testing.allocator));
    try std.testing.expect(int2.compareGt(int3, std.testing.allocator));

    try std.testing.expect(int3.compareLe(int1, std.testing.allocator));
    try std.testing.expect(int3.compareLe(int2, std.testing.allocator));
    try std.testing.expect(int3.compareLe(int3, std.testing.allocator));

    try std.testing.expect(trueBool.compareEq(float1, std.testing.allocator));
    try std.testing.expect(trueBool.compareEq(float3, std.testing.allocator));
    try std.testing.expect(trueBool.compareNe(float2, std.testing.allocator));
    try std.testing.expect(falseBool.compareEq(float2, std.testing.allocator));

    try std.testing.expect(int1.compareGe(float2, std.testing.allocator));
    try std.testing.expect(int1.compareGt(float3, std.testing.allocator));

    try std.testing.expect(int2.compareGe(float2, std.testing.allocator));
    try std.testing.expect(int2.compareGe(float3, std.testing.allocator));
    try std.testing.expect(int2.compareGt(float3, std.testing.allocator));

    try std.testing.expect(int3.compareLe(float1, std.testing.allocator));
    try std.testing.expect(int3.compareLe(float2, std.testing.allocator));
    try std.testing.expect(int3.compareLe(float3, std.testing.allocator));

    // float to integer
    try std.testing.expect(float1.float.value >= int1.asFloat().?);
    try std.testing.expect(float2.float.value == int2.asFloat().?);
    try std.testing.expect(float3.float.value == int3.asFloat().?);

    try stringTest(float1, "420.69");
    try stringTest(float2, "0");
    try stringTest(float3, "-12");
}

test "013-conversions-float" {
    // float to boolean
    var float1 = FactValue{ .float = .{ .value = 420.69 } };
    var float2 = FactValue{ .float = .{ .value = 0.0 } };
    var float3 = FactValue{ .float = .{ .value = -12.0 } };

    var int1 = FactValue{ .integer = .{ .value = 420 } };
    var int2 = FactValue{ .integer = .{ .value = 0 } };
    var int3 = FactValue{ .integer = .{ .value = -12 } };

    var trueBool = FactValue{ .boolean = .{ .value = true } };
    var falseBool = FactValue{ .boolean = .{ .value = false } };

    try std.testing.expect(trueBool.compareEq(float1, std.testing.allocator));
    try std.testing.expect(trueBool.compareEq(float3, std.testing.allocator));
    try std.testing.expect(falseBool.compareEq(float2, std.testing.allocator));
    try std.testing.expect(trueBool.compareNe(falseBool, std.testing.allocator));

    try std.testing.expect(float1.compareGe(float2, std.testing.allocator));
    try std.testing.expect(float1.compareGt(float2, std.testing.allocator));

    try std.testing.expect(float2.compareGe(float3, std.testing.allocator));
    try std.testing.expect(float2.compareGt(float3, std.testing.allocator));

    try std.testing.expect(float3.compareLe(float2, std.testing.allocator));
    try std.testing.expect(float3.compareLe(float3, std.testing.allocator));

    try std.testing.expect(int1.integer.value == float1.asInteger().?);
    try std.testing.expect(int2.integer.value == float2.asInteger().?);
    try std.testing.expect(int3.integer.value == float3.asInteger().?);

    try stringTest(float1, "420.69");
    try stringTest(float2, "0");
    try stringTest(float3, "-12");
}

test "012-conversions-boolean" {
    var bool1 = FactValue.makeDefault(BuiltinFactTypes.boolean, std.testing.allocator);
    var bool2 = FactValue.makeDefault(BuiltinFactTypes.boolean, std.testing.allocator);

    var trueString = FactValue.makeDefault(BuiltinFactTypes.string, std.testing.allocator);
    try trueString.string.value.appendSlice("true");
    var falseString = FactValue.makeDefault(BuiltinFactTypes.string, std.testing.allocator);
    try falseString.string.value.appendSlice("false");

    defer trueString.deinit(std.testing.allocator);
    defer falseString.deinit(std.testing.allocator);

    bool1.boolean.value = true;
    // boolean to float
    try std.testing.expect(1.0 == bool1.asFloat().?);
    try std.testing.expect(0.0 == bool2.asFloat().?);
    // boolean to int
    try std.testing.expect(1 == bool1.asInteger().?);
    try std.testing.expect(0 == bool2.asInteger().?);
    // boolean to string

    // don't ever use it like this
    var testString = FactValue{ .string = .{ .value = &bool1.asString(std.testing.allocator).? } };
    defer testString.string.value.deinit();
    try std.testing.expect(trueString.compareEq(testString, std.testing.allocator));

    var testString2 = FactValue{ .string = .{ .value = &bool2.asString(std.testing.allocator).? } };
    defer testString2.string.value.deinit();
    try std.testing.expect(falseString.compareEq(testString2, std.testing.allocator));
}

test "011-validate-all-interfaces" {
    inline for (@typeInfo(BuiltinFactTypes).Enum.fields) |field| {
        var testFact = FactValue.makeDefault(@intToEnum(BuiltinFactTypes, field.value), std.testing.allocator);
        defer testFact.deinit(t_allocator);
        std.debug.print("\n", .{});
        testFact.prettyPrint(0);
        _ = testFact;
    }
    std.debug.print("\n", .{});
}

test "010-testing-new-facts" {
    std.debug.print("\n", .{});
    var x = FactValue{ .boolean = .{ .value = true } };

    var y = try FactValue.fromUtf8("testing", std.testing.allocator);
    defer y.deinit(t_allocator);
    var y2 = try FactValue.fromUtf8("testing", std.testing.allocator);
    defer y2.deinit(t_allocator);

    x.prettyPrint(0);
    std.debug.print("\n", .{});
    y.prettyPrint(0);
    std.debug.print("\n", .{});
    std.debug.print("testing: {}\n", .{y.compareEq(y2, std.testing.allocator)});
}
