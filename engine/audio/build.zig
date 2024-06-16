const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const miniaudio_dep = b.dependency("miniaudio", .{
        .target = target,
        .optimize = optimize,
    });

    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
    });

    const assets_dep = b.dependency("assets", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("audio", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/audio.zig"),
    });
    mod.addImport("miniaudio", miniaudio_dep.module("miniaudio"));
    mod.addImport("core", core_dep.module("core"));
    mod.addImport("assets", assets_dep.module("assets"));
}
