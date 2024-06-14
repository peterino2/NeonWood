const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("objLoader", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/obj_loader.zig"),
    });

    const test_step = b.step("test-objLoader", "");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/obj_loader.zig"),
        .link_libc = true,
    });

    tests.root_module.addImport("objLoader", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
