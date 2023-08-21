const std = @import("std");
pub const spirvReflect = @import("lib/spirv-reflect-zig/build.zig");

pub fn addLib(b: *std.Build, exe: *std.build.LibExeObjStep, comptime pathPrefix: []const u8, cflags: []const []const u8) void {
    _ = cflags;
    _ = b;
    exe.addIncludePath(.{ .path = pathPrefix ++ "/lib/vulkan_inc" });
    exe.addIncludePath(.{ .path = pathPrefix ++ "/lib" });
    exe.addIncludePath(.{ .path = pathPrefix });

    exe.addLibraryPath(.{ .path = pathPrefix ++ "/lib" });
}
