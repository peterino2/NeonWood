const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const c_test = b.addExecutable("c_test", null);
    c_test.addCSourceFile("src/c_api/test.cpp", &.{});
    c_test.addIncludeDir("src/c_api/inc");
    c_test.linkLibC();
    c_test.linkLibCpp();
    const c_test_run = c_test.run();

    if (true) {
        const halcShared = b.addSharedLibrary(
            "Halcyon",
            "src/c_api.zig",
            b.version(0, 0, 1),
        );
        halcShared.setTarget(target);
        halcShared.setBuildMode(mode);
        halcShared.addIncludeDir("src/c_api/inc");
        //halcShared.setLibCFile(std.build.FileSource{ .path = "libc.txt" });
        halcShared.bundle_compiler_rt = true;
        halcShared.install();

        c_test.linkLibrary(halcShared);
    } else {
        const halcShared = b.addStaticLibrary(
            "Halcyon",
            "src/c_api.zig",
        );
        halcShared.setTarget(target);
        halcShared.setBuildMode(mode);
        halcShared.addIncludeDir("src/c_api/inc");
        halcShared.linkLibC();
        halcShared.install();
        c_test.linkLibrary(halcShared);
    }

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
    test_step.dependOn(&c_test_run.step);
}
