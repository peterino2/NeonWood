const std = @import("std");

// very tiny, not intended to build anything just to run tests linked with libc
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Creates a step for unit testing.
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "testing.zig" },
        .target = target,
        .optimize = optimize,
    });

    main_tests.linkLibC();
    main_tests.linkLibCpp();
    main_tests.addCSourceFile(.{ .file = .{ .path = "compat.cpp" }, .flags = &.{""} });
    main_tests.addIncludePath(.{ .path = "./" });
    const run_tests = b.addRunArtifact(main_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_tests.step);
}
