const std = @import("std");

const spng = @import("lib/zig-spng/build.zig");
const zigTracy = @import("lib/zig_tracy/build_tracy.zig");

pub fn addLib(b: std.Build, exe: std.build.LibExeObjStep, comptime packagePath: []const u8, cflags: []const []const u8, enableTracy: bool) void {
    exe.addIncludePath(packagePath ++ "/lib");
    spng.linkSpng(b, exe, packagePath ++ "/lib/zig-spng", cflags);

    if (enableTracy) {
        std.debug.print("\n\nenabling tracy\n\n", .{});
        zigTracy.link(b, exe, packagePath ++ "/lib/Zig-Tracy/tracy-0.7.8/");
    } else {
        std.debug.print("\n\nno tracy\n\n", .{});
        zigTracy.link(b, exe, null);
    }
}
