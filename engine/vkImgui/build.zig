const std = @import("std");

// very tiny, not intended to build anything just to run tests linked with libc
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enable_tracy = b.option(bool, "enable_tracy", "Enables tracy integration") orelse @panic("enable_tracy must be defined for vkImgui module");
    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const graphics_dep = b.dependency("graphics", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const platform_dep = b.dependency("platform", .{
        .target = target,
        .optimize = optimize,
    });

    const vulkan_dep = b.dependency("vulkan", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("vkImgui", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .root_source_file = b.path("src/vkImgui.zig"),
    });
    mod.addImport("core", core_dep.module("core"));
    mod.addImport("graphics", graphics_dep.module("graphics"));
    mod.addImport("platform", platform_dep.module("platform"));
    mod.addImport("vulkan", vulkan_dep.module("vulkan"));

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

    // I could've made cimgui a seperate lib,
    // I can seperate it out later if needed.
}
