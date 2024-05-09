const std = @import("std");

pub fn addLib(b: *std.Build, exe: *std.Build.Step.Compile, comptime pathPrefix: []const u8, target: anytype) void {
    _ = b;
    exe.addCSourceFile(.{
        .file = .{ .path = pathPrefix ++ "/nfd_common.c" },
        .flags = &.{},
    });

    exe.addIncludePath(.{ .path = pathPrefix ++ "/include" });

    if (target.result.os.tag == .macos) {
        exe.addCSourceFile(.{
            .file = .{ .path = pathPrefix ++ "/nfd_cocoa.m" },
            .flags = &.{},
        });
        exe.linkFramework("AppKit");
    } else if (target.result.os.tag == .windows) {
        exe.addCSourceFile(.{
            .file = .{ .path = pathPrefix ++ "/nfd_win.cpp" },
            .flags = &.{},
        });
        exe.linkSystemLibrary("ole32");
    } else if (target.result.os.tag == .linux) {
        exe.addCSourceFile(.{
            .file = .{ .path = pathPrefix ++ "/nfd_gtk.c" },
            .flags = &.{},
        });
        exe.linkSystemLibrary("gdk-3");
        exe.linkSystemLibrary("atk-1.0");
        exe.linkSystemLibrary("gtk-3");
        exe.linkSystemLibrary("glib-2.0");
        exe.linkSystemLibrary("gobject-2.0");
    }
}
