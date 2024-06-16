const std = @import("std");
const SpirvReflect = @import("SpirvReflect");

pub fn addLib(b: *std.Build, exe: *std.Build.Step.Compile, comptime packagePath: []const u8, cflags: []const []const u8) void {
    _ = cflags;
    exe.addIncludePath(b.path(packagePath ++ "/papyrus/"));
    exe.addCSourceFile(.{ .file = b.path(packagePath ++ "/papyrus/compat.cpp"), .flags = &.{""} });
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enable_tracy = b.option(bool, "enable_tracy", "Enables tracy integration") orelse @panic("enable_tracy must be defined for ui module");
    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const assets_dep = b.dependency("assets", .{
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

    const papyrus_dep = b.dependency("papyrus", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const vulkan_dep = b.dependency("vulkan", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("ui", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/ui.zig"),
    });
    mod.addImport("core", core_dep.module("core"));
    mod.addImport("assets", assets_dep.module("assets"));
    mod.addImport("graphics", graphics_dep.module("graphics"));
    mod.addImport("platform", platform_dep.module("platform"));
    mod.addImport("papyrus", papyrus_dep.module("papyrus"));
    mod.addImport("vulkan", vulkan_dep.module("vulkan"));

    const spirvGen = SpirvReflect.SpirvGenerator2.init(b, .{ .optimize = optimize });
    spirvGen.addShader(mod, b.path("shaders/PapyrusRect.vert"), "papyrus_vk_vert");
    spirvGen.addShader(mod, b.path("shaders/PapyrusRect.frag"), "papyrus_vk_frag");

    spirvGen.addShader(mod, b.path("shaders/FontSDF.vert"), "FontSDF_vert");
    spirvGen.addShader(mod, b.path("shaders/FontSDF.frag"), "FontSDF_frag");
}
