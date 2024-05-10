const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    b.addStaticLibrary(.{
        .target = target,
        .optimize = optimize,
        .name = "glad",
    });

    b.addCSourceFile(.{ .file = .{ .path = "src/glad.c" } });
    b.addIncludePath(.{ .path = "include" });

    // const spng_c = b.addStaticLibrary(
    //     .{
    //         .optimize = optimize,
    //         .target = target,
    //         .name = "spng_c",
    //         .link_libc = true,
    //     },
    // );

    // spng_c.addCSourceFile(.{ .file = .{ .path = "spng/spng.c" } });
    // spng_c.addCSourceFile(.{ .file = .{ .path = "miniz.c" } });
    // spng_c.addIncludePath(.{ .path = "spng" });
    // spng_c.addIncludePath(.{ .path = "./" });

    // spng_c.defineCMacro("SPNG_USE_MINIZ", "1");

    // const mod = b.addModule("spng", .{
    //     .target = target,
    //     .optimize = optimize,
    //     .root_source_file = .{ .path = "src/spng.zig" },
    // });

    // mod.addIncludePath(.{ .path = "spng" });
    // mod.addIncludePath(.{ .path = "./" });

    // mod.linkLibrary(spng_c);
}
