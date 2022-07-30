const std = @import("std");
const vma_build = @import("vma_build.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // make step for tests
    const tests = b.addTest("test/test.zig");
    tests.setBuildMode(mode);
    tests.setTarget(target);

    // link vk
    tests.addPackagePath("vk", "test/vulkan_core.zig");
    if (target.getOs().tag == .windows) {
        tests.addObjectFile("test/vulkan-1.lib");
    } else {
        tests.linkSystemLibrary("vulkan");
    }

    // link vma
    vma_build.link(tests, "test/vulkan_core.zig", mode, target);

    const test_step = b.step("test", "run tests");
    test_step.dependOn(&tests.step);
}
