const std = @import("std");
const SpirvReflect = @import("SpirvReflect");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enable_tracy = b.option(bool, "enable_tracy", "Enables tracy integration") orelse @panic("enable_tracy must be defined for graphics module");
    const vulkan_dep = b.dependency("vulkan", .{
        .target = target,
        .optimize = optimize,
    });

    const vma_dep = b.dependency("vma", .{
        .target = target,
        .optimize = optimize,
    });

    const glfw3_dep = b.dependency("glfw3", .{
        .target = target,
        .optimize = optimize,
    });

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

    const platform_dep = b.dependency("platform", .{
        .target = target,
        .optimize = optimize,
    });

    const obj_loader_dep = b.dependency("objLoader", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("graphics", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .root_source_file = b.path("src/graphics.zig"),
    });
    mod.addImport("vulkan", vulkan_dep.module("vulkan"));
    mod.addImport("vma", vma_dep.module("vma"));
    mod.addImport("glfw3", glfw3_dep.module("glfw3"));
    mod.addImport("core", core_dep.module("core"));
    mod.addImport("assets", assets_dep.module("assets"));
    mod.addImport("platform", platform_dep.module("platform"));
    mod.addImport("objLoader", obj_loader_dep.module("objLoader"));

    mod.addAnonymousImport("texture_sample.png", .{ .root_source_file = b.path("defaults/texture_sample.png") });

    const options = b.addOptions();
    options.addOption(bool, "force_mailbox", b.option(bool, "force_mailbox", "forces mailbox mode for present mode. unlocks framerate to irresponsible levels") orelse false);

    mod.addOptions("game_build_opts", options);

    const spirvGen = SpirvReflect.SpirvGenerator2.init(b, .{ .optimize = optimize });
    spirvGen.addShader(mod, b.path("shaders/triangle_mesh.vert"), "triangle_mesh_vert");
    spirvGen.addShader(mod, b.path("shaders/default_lit.frag"), "default_lit");

    spirvGen.addShader(mod, b.path("shaders/debug.vert"), "debug_vert");
    spirvGen.addShader(mod, b.path("shaders/debug.frag"), "debug_frag");

    // === simple little integration test ===
    //
    // this doesn't really do anything other than call a few functions
    // to make sure that we properly linked everything
    const test_step = b.step("test-graphics", "");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("tests/tests.zig"),
        .link_libc = true,
    });

    tests.root_module.addImport("graphics", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
