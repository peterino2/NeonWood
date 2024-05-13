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

    spng_c.addCSourceFile(.{ .file = .{ .path = "spng/spng.c" } });
    spng_c.addCSourceFile(.{ .file = .{ .path = "miniz.c" } });
    spng_c.addIncludePath(.{ .path = "spng" });
    spng_c.addIncludePath(.{ .path = "./" });

    spng_c.defineCMacro("SPNG_USE_MINIZ", "1");

    const mod = b.addModule("spng", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/spng.zig" },
    });

    mod.addIncludePath(.{ .path = "spng" });
    mod.addIncludePath(.{ .path = "./" });

    mod.linkLibrary(spng_c);

    const test_step = b.step("test-spng", "run unit tests for spng");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/spng.zig" },
        .link_libc = true,
    });
    tests.root_module.linkLibrary(spng_c);
    tests.root_module.addIncludePath(.{ .path = "spng" });
    tests.root_module.addIncludePath(.{ .path = "./" });
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
