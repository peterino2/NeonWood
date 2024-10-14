const std = @import("std");
const NeonWood = @import("NeonWood");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var nwbuild = NeonWood.init(b, .{
        .target = target,
        .optimize = optimize,
    });

    _ = nwbuild.addProgram(.{
        .name = "demo",
        .desc = "simple 3d world flythrough demo",
        .root_source_file = b.path("demo/main.zig"),
    });

    _ = nwbuild.addProgram(.{
        .name = "empty",
        .desc = "simple 3d world flythrough demo implemented through lua",
        .root_source_file = b.path("empty/main.zig"),
    });

    _ = nwbuild.addProgram(.{
        .name = "uiSample",
        .desc = "ui sample program for papyrus",
        .root_source_file = b.path("uiSample/main.zig"),
    });

    _ = nwbuild.addProgram(.{
        .name = "imguiSample",
        .desc = "ui sample program for imgui",
        .root_source_file = b.path("imguiSample/main.zig"),
    });

    _ = nwbuild.addProgram(.{
        .name = "headless",
        .desc = "a headless program only runnning the core systems",
        .root_source_file = b.path("headless/main.zig"),
    });

    _ = nwbuild.addProgram(.{
        .name = "demo_lua",
        .desc = "demo project with lua scripting",
        .root_source_file = b.path("demo_lua/main.zig"),
    });

    _ = nwbuild.addProgram(.{
        .name = "allocList",
        .desc = "misc tool for viewing memory allocations in a list",
        .root_source_file = b.path("misc/allocList.zig"),
    });
}
