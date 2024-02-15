const std = @import("std");

pub fn addLib(b: *std.Build, exe: *std.build.CompileStep, comptime pathPrefix: []const u8, target: anytype) void {
    _ = b;
    exe.addCSourceFile(.{
        .file = .{ .path = pathPrefix ++ "/nfd_common.c" },
        .flags = &.{},
    });

    exe.addIncludePath(.{ .path = pathPrefix ++ "/include" });

    if (target.getOs().tag == .macos) {
        exe.addCSourceFile(.{
            .file = .{ .path = pathPrefix ++ "/nfd_cocoa.m" },
            .flags = &.{},
        });
        exe.linkFramework("AppKit");
    } else if (target.getOs().tag == .windows) {
        exe.addCSourceFile(.{
            .file = .{ .path = pathPrefix ++ "/nfd_win.cpp" },
            .flags = &.{},
        });
        exe.linkSystemLibrary("ole32");
    } else if (target.getOs().tag == .linux) {
        exe.addCSourceFile(.{
            .file = .{ .path = pathPrefix ++ "/nfd_gtk.c" },
            .flags = &.{},
        });
    }
}
