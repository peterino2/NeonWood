const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("p2", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/p2.zig"),
    });

    const test_step = b.step("test-p2", "");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/p2.zig"),
        .link_libc = true,
    });

    tests.root_module.addImport("p2", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
