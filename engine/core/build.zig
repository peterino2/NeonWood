const std = @import("std");

const dependencyList = [_][]const u8{
    "spng",
    "nfd",
    "p2",
    "tracy",
    "zmath",
    "packer",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("core", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/core.zig" },
    });

    for (dependencyList) |depName| {
        const dep = b.dependency(depName, .{ .target = target, .optimize = optimize });
        mod.addImport(depName, dep.module(depName));
    }

    const test_step = b.step("test-core", "run unit tests for core");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "tests/tests.zig" },
    });

    tests.root_module.addImport("core", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
    b.installArtifact(tests);
}
