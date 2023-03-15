const std = @import("std");

// very tiny, not intended to build anything just to run tests linked with libc
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Creates a step for unit testing.
    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "papyrus.zig" },
        .target = target,
        .optimize = optimize,
    });
    main_tests.linkLibC();
    main_tests.addCSourceFile("compat.cpp", &.{""});
    main_tests.addIncludePath("./");
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
