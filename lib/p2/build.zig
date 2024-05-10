const std = @import("std");
pub fn initModule(b: *std.Build, comptime libRoot: []const u8) void {
    var opts = std.Build.CreateModuleOptions{};
    var path = std.build.LazyPath{};
    path.path = libRoot ++ "algorithm.zig";

    opts.source_file = path;

    b.addModule("p2", opts);
}

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("p2", "structures/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const exe_tests = b.addTest("structures/perf-tests.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);
    exe_tests.linkLibC();

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
