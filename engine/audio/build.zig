const std = @import("std");

const depList = [_][]const u8{
    "miniaudio",
    "core",
    "assets",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("audio", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/audio.zig"),
    });

    for (depList) |depName| {
        const dep = b.dependency(depName, .{ .target = target, .optimize = optimize });

        mod.addImport(depName, dep.module(depName));
    }

    const test_step = b.step("test", "run unit tests for audio");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("tests/tests.zig"),
    });

    tests.root_module.addImport("audio", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
    b.installArtifact(tests);
}
