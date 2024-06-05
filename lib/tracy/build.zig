const std = @import("std");

const tracy_path = "tracy-0.7.8/";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    //const tracy_enabled = b.option(bool, "tracy", "Enables tracy integration") orelse false;

    const tracy_enabled = if (b.graph.env_map.hash_map.get("WITH_TRACY") != null) true else false;
    std.debug.print("tracy enabled {s}\n", .{if (tracy_enabled) "true" else "false"});

    const mod = b.addModule("tracy", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "tracy.zig" },
        .link_libc = true,
        .link_libcpp = true,
    });

    if (tracy_enabled) {
        mod.addIncludePath(.{ .path = tracy_path });
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
    }

    const opts = b.addOptions();
    opts.addOption(bool, "tracy_enabled", tracy_enabled);
    mod.addOptions("build_options", opts);

    // ========== tests =============
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
