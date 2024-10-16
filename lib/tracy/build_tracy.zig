const std = @import("std");

const tracy_path = "tracy-0.7.8/";

pub fn build(b: std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("tracy", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "tracy.zig" },
        .link_libc = true,
        .link_libcpp = true,
    });

    mod.addCSourceFile(.{
        .file = .{ .path = tracy_path ++ "TracyClient.cpp" },
        .flags = &[_][]const u8{
            "-DTRACY_ENABLE",
            // MinGW doesn't have all the newfangled windows features,
            // so we need to pretend to have an older windows version.
            "-D_WIN32_WINNT=0x601",
            "-fno-sanitize=undefined",
        },
    });

    if (target.result.os.tag == .windows) {
        mod.linkSystemLibrary("Advapi32", .{});
        mod.linkSystemLibrary("User32", .{});
        mod.linkSystemLibrary("Ws2_32", .{});
        mod.linkSystemLibrary("DbgHelp", .{});
    }

    const opts = b.addOptions();
    mod.addOptions("build_options", opts);
    opts.addOption(bool, "tracy_enabled", b.option(bool, "tracy", "Enables tracy integration"));

    const test_step = b.step("test-tracy", "run unit tests for tracy");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "tracy_test.zig" },
    });
    tests.root_module.addImport("tracy", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
