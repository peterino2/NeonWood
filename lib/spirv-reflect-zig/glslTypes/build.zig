const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("glslTypes", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "glslTypes.zig" },
    });

    _ = mod;
}
