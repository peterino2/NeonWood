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
}
