const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spng_c = b.addStaticLibrary(
        .{
            .optimize = optimize,
            .target = target,
            .name = "spng_c",
            .link_libc = true,
        },
    );

    spng_c.addCSourceFile(.{ .file = b.path("spng/spng.c") });
    spng_c.addCSourceFile(.{ .file = b.path("miniz.c") });
    spng_c.addIncludePath(b.path("spng"));
    spng_c.addIncludePath(b.path("./"));

    spng_c.defineCMacro("SPNG_USE_MINIZ", "1");

    const mod = b.addModule("spng", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/spng.zig"),
    });

    mod.addIncludePath(b.path("spng"));
    mod.addIncludePath(b.path("./"));

    mod.linkLibrary(spng_c);

    const test_step = b.step("test-spng", "run unit tests for spng");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/spng.zig"),
        .link_libc = true,
    });
    tests.root_module.linkLibrary(spng_c);
    tests.root_module.addIncludePath(b.path("spng"));
    tests.root_module.addIncludePath(b.path("./"));
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
