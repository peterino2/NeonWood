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

    const p2mod = p2dep.module("p2");
    mod.addImport("p2", p2mod);

    const test_exe = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "tests/test.zig" },
        .link_libc = true,
    });
    test_exe.root_module.addImport("packer", mod);
    test_exe.root_module.addImport("p2", p2mod);

    const test_step = b.step("test-packer", "runs sample unit tests for packer");
    test_step.dependOn(&b.addRunArtifact(test_exe).step);
}
