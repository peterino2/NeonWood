const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const p2dep = b.dependency("p2", .{ .target = target, .optimize = optimize });

    const mod = b.addModule("packer", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/packer.zig" },
    });

    mod.addImport("p2", p2dep.module("p2"));

    const test_exe = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "tests/test.zig" },
    });
    test_exe.root_module.addImport("packer", mod);

    const test_step = b.step("test", "runs sample unit tests for packer");
    test_step.dependOn(&b.addRunArtifact(test_exe).step);
}
