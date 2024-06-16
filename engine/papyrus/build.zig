const std = @import("std");

// very tiny, not intended to build anything just to run tests linked with libc
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("papyrus", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .root_source_file = b.path("src/papyrus.zig"),
    });
    mod.addIncludePath(b.path("src/"));
    mod.addCSourceFile(.{ .file = b.path("src/compat.cpp") });

    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = b.option(bool, "enable_tracy", "Enables tracy integration") orelse @panic("enable_tracy must be defined for papyrus module"),
    });

    mod.addImport("core", core_dep.module("core"));

    // Creates a step for unit testing.
    const main_tests = b.addTest(.{
        .root_source_file = b.path("tests/testing.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    main_tests.root_module.addImport("core", core_dep.module("core"));
    main_tests.root_module.addImport("papyrus", mod);
    main_tests.root_module.addIncludePath(b.path("src/"));

    main_tests.linkLibC();
    main_tests.linkLibCpp();
    const run_tests = b.addRunArtifact(main_tests);
    const test_step = b.step("test-papyrus", "Run library tests");
    test_step.dependOn(&run_tests.step);
}
