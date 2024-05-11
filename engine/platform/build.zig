const std = @import("std");

// pub fn addLib(b: *std.Build, exe: *std.Build.Step.Compile, comptime packagePath: []const u8, cflags: []const []const u8) void {
//     _ = b;
//     _ = cflags;
//
//     exe.addIncludePath(.{ .path = packagePath ++ "/lib" });
//     exe.addLibraryPath(.{ .path = packagePath ++ "/lib" });
// }

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("platform", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/platform.zig" },
    });

    const glfw3_dep = b.dependency("glfw3", .{ .target = target, .optimize = optimize });
    mod.addImport("glfw3", glfw3_dep.module("glfw3"));

    const vulkan_dep = b.dependency("vulkan", .{ .target = target, .optimize = optimize });
    mod.addImport("vulkan", vulkan_dep.module("vulkan"));
}
