const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cgltf = b.addModule("cgltf", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/cgltf.zig" },
    });

    const test_step = b.step("test-cgltf", "run unit tests for cgltf");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/cgltf.zig" },
        .link_libc = true,
    });

    tests.root_module.addImport("cgltf", cgltf);
    tests.root_module.addIncludePath(.{ .path = "src" });
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
