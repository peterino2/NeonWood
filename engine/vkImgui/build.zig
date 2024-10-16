const std = @import("std");

// very tiny, not intended to build anything just to run tests linked with libc
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("vkImgui", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .root_source_file = b.path("src/vkImgui.zig"),
    });

    mod.addIncludePath(b.path("cimgui"));
    mod.addIncludePath(b.path("cimplot"));
    mod.addIncludePath(b.path("cimgui/imgui"));
    mod.addIncludePath(b.path("cimgui/imgui/backends"));
    mod.addCSourceFiles(.{
        .root = b.path("cimgui/imgui"),
        .files = &[_][]const u8{
            "cimgui.cpp",
            "cimgui_compat.cpp",
            "imgui.cpp",
            "imgui_demo.cpp",
            "imgui_draw.cpp",
            "imgui_tables.cpp",
            "imgui_widgets.cpp",
            "backends/imgui_impl_vulkan.cpp",
            "backends/imgui_impl_glfw.cpp",
        },
    });

    mod.addCSourceFiles(.{
        .root = b.path("cimplot"),
        .files = &[_][]const u8{
            "cimplot.cpp",
            "implot/implot.cpp",
            "implot/implot_demo.cpp",
            "implot/implot_items.cpp",
        },
    });

    const depList = [_][]const u8{
        "core",
        "graphics",
        "platform",
        "vulkan",
    };

    for (depList) |depName| {
        const dep = b.dependency(depName, .{ .target = target, .optimize = optimize });
        const depMod = dep.module(depName);
        mod.addImport(depName, depMod);
    }

    // I could've made cimgui a seperate lib,
    // I can seperate it out later if needed.
}
