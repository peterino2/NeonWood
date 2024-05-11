const std = @import("std");
const nw = @import("nw");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var nwbuild = nw.init(b, target, optimize);
    nwbuild.addProgram("demo", "simple 3d world flythrough demo");
}
