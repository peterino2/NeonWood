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

    const glfw3_dep = b.dependency("glfw3", .{
        .target = target,
        .optimize = optimize,
    });

    const vulkan_dep = b.dependency("vulkan", .{
        .target = target,
        .optimize = optimize,
    });

    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
    });

    // oh that is interesting. what I can do is have two
    // different modules specified here.
    //
    // one module for each graphics backend
    //
    // todo,
    const mod = b.addModule("platform", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/platform.zig"),
    });
    mod.addImport("glfw3", glfw3_dep.module("glfw3"));
    mod.addImport("vulkan", vulkan_dep.module("vulkan"));
    mod.addImport("core", core_dep.module("core"));

    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("tests/tests.zig"),
    });
    tests.root_module.addImport("glfw3", glfw3_dep.module("glfw3"));
    tests.root_module.addImport("vulkan", vulkan_dep.module("vulkan"));
    tests.root_module.addImport("core", core_dep.module("core"));

    const test_step = b.step("test-platform", "run unit tests for platform");

    tests.root_module.addImport("platform", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
    b.installArtifact(tests);
}
