const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("assets", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/assets.zig"),
    });

    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = b.option(bool, "enable_tracy", "Enables tracy integration") orelse @panic("enable_tracy must be defined for assets module"),
    });
    mod.addImport("core", core_dep.module("core"));

    const packer_dep = b.dependency(
        "packer",
        .{ .target = target, .optimize = optimize },
    );

    mod.addImport("packer", packer_dep.module("packer"));
}
