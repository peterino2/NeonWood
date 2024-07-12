const std = @import("std");
const SpirvReflect = @import("SpirvReflect");

const dependencyList = [_][]const u8{
    "vulkan",
    "vma",
    "glfw3",
    "core",
    "assets",
    "platform",
    "objLoader",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("graphics", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .root_source_file = b.path("src/graphics.zig"),
    });

    mod.addAnonymousImport("texture_sample.png", .{ .root_source_file = b.path("defaults/texture_sample.png") });

    const options = b.addOptions();
    options.addOption(bool, "force_mailbox", b.option(bool, "force_mailbox", "forces mailbox mode for present mode. unlocks framerate to irresponsible levels") orelse false);

    mod.addOptions("game_build_opts", options);

    for (dependencyList) |depName| {
        const dep = b.dependency(depName, .{ .target = target, .optimize = optimize });
        mod.addImport(depName, dep.module(depName));
    }

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

    for (dependencyList) |depName| {
        const dep = b.dependency(depName, .{ .target = target, .optimize = optimize });
        tests.root_module.addImport(depName, dep.module(depName));
    }
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
