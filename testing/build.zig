const std = @import("std");
const NeonWood = @import("NeonWood");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var nwbuild = NeonWood.init(b, .{
        .target = target,
        .optimize = optimize,
    });

    _ = nwbuild.addProgram(.{
        .name = "tests",
        .desc = "a test runner that runs every single module test",
        .root_source_file = b.path("test-all.zig"),
    });
}
