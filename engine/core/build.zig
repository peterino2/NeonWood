const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spng_dep = b.dependency("spng", .{
        .target = target,
        .optimize = optimize,
    });

    const nfd_dep = b.dependency("nfd", .{
        .target = target,
        .optimize = optimize,
    });

    const p2_dep = b.dependency("p2", .{
        .target = target,
        .optimize = optimize,
    });

    const tracy_dep = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = b.option(bool, "enable_tracy", "Enables tracy integration") orelse @panic("enable_tracy must be defined for core module"),
    });

    const zmath_dep = b.dependency("zmath", .{
        .target = target,
        .optimize = optimize,
    });

    const packer_dep = b.dependency("packer", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("core", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/core.zig"),
    });
    mod.addImport("spng", spng_dep.module("spng"));
    mod.addImport("nfd", nfd_dep.module("nfd"));
    mod.addImport("p2", p2_dep.module("p2"));
    mod.addImport("tracy", tracy_dep.module("tracy"));
    mod.addImport("zmath", zmath_dep.module("zmath"));
    mod.addImport("packer", packer_dep.module("packer"));

    const test_step = b.step("test-core", "run unit tests for core");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("tests/tests.zig"),
    });

    tests.root_module.addImport("core", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
    b.installArtifact(tests);
}
