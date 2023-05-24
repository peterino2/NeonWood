const std = @import("std");
const nwbuild = @import("nwbuild/nwbuild.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // if set to true, will override all other debug flags to false
    const options = b.addOptions();
    options.addOption(bool, "release_build", false);

    var system = nwbuild.NwBuildSystem.init(b, target, optimize, .{});
    var demo = system.addProgram("demo", "demo.zig", "simple flyover demo");
    _ = demo;
}
