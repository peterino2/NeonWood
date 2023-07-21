const std = @import("std");
pub const spirvReflect = @import("lib/spirv-reflect-zig/build.zig");

pub fn addLib(b: *std.Build, exe: *std.build.LibExeObjStep, comptime pathPrefix: []const u8, cflags: []const []const u8) void {
    _ = cflags;
    _ = b;
    exe.addIncludePath(pathPrefix ++ "/lib/vulkan_inc");
    exe.addIncludePath(pathPrefix ++ "/lib");
    exe.addIncludePath(pathPrefix);

    exe.addLibraryPath(pathPrefix ++ "/lib");
}

pub fn generateVulkan() void {}

pub fn addShader() void {}
