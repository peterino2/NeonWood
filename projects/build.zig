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
        .name = "uiSample",
        .desc = "ui sample program for papyrus",
        .root_source_file = b.path("uiSample/main.zig"),
    });
    _ = nwbuild.addProgram(.{
        .name = "imguiSample",
        .desc = "ui sample program for imgui",
        .root_source_file = b.path("imguiSample/main.zig"),
    });
}
