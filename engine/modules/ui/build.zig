const std = @import("std");

pub fn addLib(b: *std.Build, exe: *std.build.LibExeObjStep, comptime packagePath: []const u8, cflags: []const []const u8) void {
    _ = b;
    _ = cflags;
    exe.addIncludePath(.{ .path = packagePath ++ "/papyrus/" });
    exe.addCSourceFile(.{ .file = .{ .path = packagePath ++ "/papyrus/compat.cpp" }, .flags = &.{""} });
}
