const std = @import("std");

const spng = @import("lib/zig-spng/build.zig");
const zigTracy = @import("lib/zig_tracy/build_tracy.zig");
const nfdBuild = @import("lib/nfd/build.zig");

pub fn addLib(b: *std.Build, exe: *std.Build.Step.Compile, comptime packagePath: []const u8, cflags: []const []const u8, enableTracy: bool, target: anytype) void {
    _ = cflags;
    exe.addIncludePath(.{ .path = packagePath ++ "/lib" });
    spng.addLib(b, exe, packagePath ++ "/lib/zig-spng");

    nfdBuild.addLib(b, exe, packagePath ++ "/lib/nfd", target);

    if (enableTracy) {
        zigTracy.link(b, exe, packagePath ++ "/lib/zig_tracy/tracy-0.7.8/");
    } else {
        zigTracy.link(b, exe, null);
    }
}
