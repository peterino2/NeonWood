const std = @import("std");

pub fn addLib(b: *std.Build, exe: *std.Build.Step.Compile, comptime packagePath: []const u8, cflags: []const []const u8) void {
    _ = cflags;
    _ = b;

    exe.addCSourceFile(.{ .file = .{ .path = packagePath ++ "/miniaudio.cpp" }, .flags = &.{"-fno-sanitize=all"} });
    exe.addIncludePath(.{ .path = packagePath ++ "/lib" });
}
