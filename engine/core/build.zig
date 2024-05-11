const std = @import("std");

const dependencyList = [_][]const u8{
    "spng",
    "nfd",
    "p2",
    "tracy",
    "zmath",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("core", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/core.zig" },
    });

    const opts = b.addOptions();

    // build options for core.zig
    opts.addOption(
        bool,
        "mutex_job_queue",
        b.option(bool, "mutex_job_queue", "temporary test, reverts to old mutex based queue behaviour in jobs.zig:JobManager") orelse false,
    );
    opts.addOption(
        bool,
        "zero_logging",
        b.option(bool, "zero_logging", "disables all logging, only intended for use on job dispatch testing") orelse false,
    );
    opts.addOption(
        bool,
        "slow_logging",
        b.option(bool, "slow_logging", "Disables buffered logging, takes a hit to performance but gain timing information on logging") orelse false,
    );
    opts.addOption(
        bool,
        "force_mailbox",
        b.option(bool, "force_mailbox", "forces mailbox mode for present mode. unlocks framerate to irresponsible levels") orelse false,
    );

    mod.addOptions("game_build_opts", opts);

    for (dependencyList) |depName| {
        const dep = b.dependency(depName, .{ .target = target, .optimize = optimize });
        mod.addImport(depName, dep.module(depName));
    }

    const test_step = b.step("test-core", "run unit tests for core");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "tests/tests.zig" },
    });

    tests.root_module.addImport("core", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
    b.installArtifact(tests);
}
