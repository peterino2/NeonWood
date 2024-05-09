const std = @import("std");

pub fn addLib(b: *std.Build, exe: *std.Build.Step.Compile, comptime packagePath: []const u8, cflags: []const []const u8) void {
    _ = b;
    _ = cflags;

    exe.addIncludePath(.{ .path = packagePath ++ "/lib" });
    exe.addLibraryPath(.{ .path = packagePath ++ "/lib" });
}
