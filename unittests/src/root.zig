const std = @import("std");
pub const cgltf = @import("cgltf");
pub const spng = @import("spng");
pub const miniaudio = @import("miniaudio");
pub const glfw3 = @import("glfw3");
pub const nfd = @import("nfd");
pub const objLoader = @import("objLoader");
pub const p2 = @import("p2");
pub const vulkan = @import("vulkan");
pub const tracy = @import("tracy");
pub const vma = @import("vma");
pub const gl = @import("gl");
pub const zmath = @import("zmath");

pub const core = @import("core");

test "000-helloWorld" {
    @setEvalBranchQuota(1000000);
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(p2);

    const allocator = std.testing.allocator;
    const TestStructField = struct {
        x: u32,
    };

    const TestStruct = struct {
        field1: usize,
        structField: TestStructField,
    };

    var testSet = p2.SparseMultiSet(TestStruct).init(allocator);
    defer testSet.deinit();
    const sparseHandle = try testSet.createObject(.{ .field1 = 1, .structField = .{ .x = 12 } });
    const sparseHandle1 = try testSet.createObject(.{ .field1 = 2, .structField = .{ .x = 34 } });
    const sparseHandle2 = try testSet.createObject(.{ .field1 = 3, .structField = .{ .x = 56 } });
    std.debug.print("handle: {any}\n", .{testSet.get(sparseHandle, .field1).?.*});
    std.debug.print("handle1: {any}\n", .{testSet.get(sparseHandle1, .field1).?.*});
    std.debug.print("handle2: {any}\n", .{testSet.get(sparseHandle2, .field1).?.*});
    _ = testSet.destroyObject(sparseHandle);
    std.debug.print("handle1: {any}\n", .{testSet.get(sparseHandle1, .field1).?.*});
    std.debug.print("handle2: {any}\n", .{testSet.get(sparseHandle2, .field1).?.*});
}
