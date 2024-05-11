const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("gl", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/glad.zig" },
    });

    mod.addCSourceFile(.{ .file = .{ .path = "src/glad.c" } });
    mod.addIncludePath(.{ .path = "include" });

    const test_step = b.step("test-gl", "runs tests for gl");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "test_glad.zig" },
        .link_libc = true,
    });

    tests.root_module.addImport("gl", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
