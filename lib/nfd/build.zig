const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("nfd", .{
        .target = target,
        .optimize = optimize,
    });

    mod.addCSourceFile(.{
        .file = .{ .path = "src/nfd_common.c" },
        .flags = &.{},
    });

    mod.addIncludePath(.{ .path = "include" });

    if (target.result.os.tag == .macos) {
        mod.addCSourceFile(.{
            .file = .{ .path = "src/nfd_cocoa.m" },
            .flags = &.{},
        });
        mod.linkFramework("AppKit", .{});
    } else if (target.result.os.tag == .windows) {
        mod.addCSourceFile(.{
            .file = .{ .path = "src/nfd_win.cpp" },
            .flags = &.{},
        });
        mod.linkSystemLibrary("ole32", .{});
    } else if (target.result.os.tag == .linux) {
        mod.addCSourceFile(.{
            .file = .{ .path = "src/nfd_gtk.c" },
            .flags = &.{},
        });
        mod.linkSystemLibrary("gdk-3", .{});
        mod.linkSystemLibrary("atk-1.0", .{});
        mod.linkSystemLibrary("gtk-3", .{});
        mod.linkSystemLibrary("glib-2.0", .{});
        mod.linkSystemLibrary("gobject-2.0", .{});
    }

    const test_step = b.step("test-nfd", "");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/nfd.zig" },
        .link_libc = true,
    });
    tests.addIncludePath(.{ .path = "./include" });

    tests.root_module.addImport("nfd", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
