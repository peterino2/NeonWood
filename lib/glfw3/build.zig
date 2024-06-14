const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("glfw3", .{ .target = target, .optimize = optimize, .root_source_file = b.path("src/glfw3.zig") });

    mod.addIncludePath(b.path("./include"));

    if (target.result.os.tag == .windows) {
        mod.addLibraryPath(b.path("."));
        mod.linkSystemLibrary("glfw3dll", .{});
    } else {
        mod.linkSystemLibrary("glfw", .{});
        mod.linkSystemLibrary("dl", .{});
        mod.linkSystemLibrary("pthread", .{});
    }

    if (target.result.os.tag == .macos) {
        mod.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib/" });
    }

    // ======== tests ============
    const test_step = b.step("test-glfw3", "");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/glfw3.zig"),
        .link_libc = true,
    });
    tests.addIncludePath(b.path("./include"));

    tests.root_module.addImport("glfw3", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
