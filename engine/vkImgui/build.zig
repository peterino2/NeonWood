const std = @import("std");

// very tiny, not intended to build anything just to run tests linked with libc
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("vkImgui", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .root_source_file = .{ .path = "src/vkImgui.zig" },
    });

    mod.addIncludePath(.{ .path = "cimgui" });
    mod.addIncludePath(.{ .path = "cimgui/imgui" });
    mod.addIncludePath(.{ .path = "cimgui/imgui/backends" });
    mod.addCSourceFiles(.{
        .root = .{ .path = "cimgui/imgui" },
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
