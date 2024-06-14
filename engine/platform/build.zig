const std = @import("std");

// pub fn addLib(b: *std.Build, exe: *std.Build.Step.Compile, comptime packagePath: []const u8, cflags: []const []const u8) void {
//     _ = b;
//     _ = cflags;
//
//     exe.addIncludePath(.{ .path = packagePath ++ "/lib" });
//     exe.addLibraryPath(.{ .path = packagePath ++ "/lib" });
// }

const dependencyList = [_][]const u8{
    "glfw3",
    "vulkan",
    "core",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

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

    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("tests/tests.zig"),
    });

    for (dependencyList) |depName| {
        const dep = b.dependency(depName, .{ .target = target, .optimize = optimize });
        const dep_mod = dep.module(depName);
        mod.addImport(depName, dep_mod);
        tests.root_module.addImport(depName, dep_mod);
    }

    const test_step = b.step("test-platform", "run unit tests for platform");

    tests.root_module.addImport("platform", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
    b.installArtifact(tests);
}
