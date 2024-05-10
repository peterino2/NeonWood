const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const miniaudio_c = b.addStaticLibrary(.{
        .name = "miniaudio_c",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    miniaudio_c.addCSourceFile(.{ .file = .{ .path = "src/miniaudio.cpp" }, .flags = &.{"-fno-sanitize=all"} });
    miniaudio_c.addIncludePath(.{ .path = "include" });

    const mod = b.addModule("miniaudio", .{ .target = target, .optimize = optimize, .root_source_file = .{ .path = "src/miniaudio.zig" } });

    mod.linkLibrary(miniaudio_c);
    mod.addIncludePath(.{ .path = "./include" });

    const test_step = b.step("test-miniaudio", "");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/miniaudio.zig" },
        .link_libc = true,
    });
    tests.addIncludePath(.{ .path = "./include" });

    tests.root_module.addImport("miniaudio", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
