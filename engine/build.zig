const std = @import("std");
const nwbuild = @import("nwbuild/nwbuild.zig");
const utils = @import("projects/utils/build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // if set to true, will override all other debug flags to false
    const options = b.addOptions();
    options.addOption(bool, "release_build", false);

    var system = nwbuild.NwBuildSystem.init(b, target, optimize, .{});
    // _ = system.addGame("demo", "simple flyover demo");
    _ = system.addGame("uiSample", "sample UI program");

    // _ = system.addTest("jobTest");
    // _ = system.addTest("sparse_set_perf");

    utils.buildUtilities(b, .{
        .target = target,
        .optimize = optimize,
    });
}
