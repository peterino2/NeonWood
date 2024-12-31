const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("assets", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/assets.zig"),
    });

    const core_dep = b.dependency(
        "core",
        .{ .target = target, .optimize = optimize },
    );
    mod.addImport("core", core_dep.module("core"));

    const packer_dep = b.dependency(
        "packer",
        .{ .target = target, .optimize = optimize },
    );

    mod.addImport("packer", packer_dep.module("packer"));

    const test_step = b.step("test", "run unit tests for assets");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("tests/test.zig"),
    });

    tests.root_module.addImport("assets", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
    b.installArtifact(tests);
}
