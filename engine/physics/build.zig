const std = @import("std");

// very tiny, not intended to build anything just to run tests linked with libc
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("physics", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .root_source_file = b.path("src/physics.zig"),
    });

    const core_dep = b.dependency("core", .{ .target = target, .optimize = optimize });
    const zphysics_dep = b.dependency("zphysics", .{ .target = target, .optimize = optimize });

    mod.addImport("core", core_dep.module("core"));
    mod.addImport("zphysics", zphysics_dep.module("root"));

    const test_step = b.step("test-physics", "run unit tests for core");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("tests/tests.zig"),
    });

    tests.root_module.addImport("physics", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
    b.installArtifact(tests);
}
