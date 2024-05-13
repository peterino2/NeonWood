const std = @import("std");
const NeonWood = @import("NeonWood");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var nwbuild = NeonWood.init(b, target, optimize, "../");
    _ = nwbuild.addProgram("demo", "simple 3d world flythrough demo", .{});
}
