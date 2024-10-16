const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("zmath", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("zmath.zig"),
    });

    const test_step = b.step("test-zmath", "runs tests for zmath");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("zmath.zig"),
        .link_libc = true,
    });

    tests.root_module.addImport("zmath", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
