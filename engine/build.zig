const std = @import("std");
const nwbuild = @import("nwbuild/nwbuild.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions();
    _ = target;
    const optimize = b.standardOptimizeOption();
    _ = optimize;

    // if set to true, will override all other debug flags to false
    const options = b.addOptions();
    options.addOption(bool, "release_build", false);
}
