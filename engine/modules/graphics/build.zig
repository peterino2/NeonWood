const std = @import("std");
pub const spirvReflect = @import("lib/spirv-reflect-zig/build.zig");

pub fn addLib(b: std.Build, exe: std.build.LibExeObjStep, comptime pathPrefix: []const u8, cflags: []const []const u8) void {
    _ = b;
    exe.addCSourceFile(pathPrefix ++ "/lib/imgui/imgui.cpp", cflags);
    exe.addCSourceFile(pathPrefix ++ "/lib/imgui/imgui_demo.cpp", cflags);
    exe.addCSourceFile(pathPrefix ++ "/lib/imgui/imgui_draw.cpp", cflags);
    exe.addCSourceFile(pathPrefix ++ "/lib/imgui/imgui_tables.cpp", cflags);
    exe.addCSourceFile(pathPrefix ++ "/lib/imgui/backends/imgui_impl_vulkan.cpp", cflags);
    exe.addCSourceFile(pathPrefix ++ "/lib/imgui/backends/imgui_impl_glfw.cpp", cflags);
    exe.addCSourceFile(pathPrefix ++ "/lib/imgui/imgui_widgets.cpp", cflags);
    exe.addCSourceFile(pathPrefix ++ "/lib/cimgui/cimgui.cpp", cflags);
    exe.addCSourceFile(pathPrefix ++ "/cimgui_compat.cpp", cflags);

    exe.addIncludePath(pathPrefix ++ "/lib/vulkan_inc");
    exe.addIncludePath(pathPrefix ++ "/lib/cimgui");
    exe.addIncludePath(pathPrefix ++ "/lib/imgui");
    exe.addIncludePath(pathPrefix ++ "/lib/imgui/backends");
    exe.addIncludePath(pathPrefix ++ "/lib");
    exe.addIncludePath(pathPrefix);

    exe.addLibraryPath(pathPrefix ++ "/lib");
}

pub fn generateVulkan() void {}

pub fn addShader() void {}
