const std = @import("std");
const SpirvReflect = @import("SpirvReflect");

const dependencyList = [_][]const u8{
    "vulkan",
    "vma",
    "glfw3",
    "core",
    "assets",
    "platform",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("graphics", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .root_source_file = .{ .path = "src/graphics.zig" },
    });

    for (dependencyList) |depName| {
        const dep = b.dependency(depName, .{ .target = target, .optimize = optimize });
        mod.addImport(depName, dep.module(depName));
    }
    // self.addShader(exe, "triangle_mesh_vert", build_root ++ "/modules/graphics/shaders/triangle_mesh.vert");
    // self.addShader(exe, "default_lit", build_root ++ "/modules/graphics/shaders/default_lit.frag");

    // self.addShader(exe, "debug_vert", build_root ++ "/modules/graphics/shaders/debug.vert");
    // self.addShader(exe, "debug_frag", build_root ++ "/modules/graphics/shaders/debug.frag");

    const spirvGen = SpirvReflect.SpirvGenerator2.init(b, .{ .optimize = optimize });
    spirvGen.addShader(mod, "shaders/triangle_mesh.vert", "triangle_mesh_vert");
    spirvGen.addShader(mod, "shaders/default_lit.frag", "default_lit");

    spirvGen.addShader(mod, "shaders/debug.vert", "debug_vert");
    spirvGen.addShader(mod, "shaders/debug.frag", "debug_vert");

    // === simple little integration test ===
    //
    // this doesn't really do anything other than call a few functions
    // to make sure that we properly linked everything
    const test_step = b.step("test-graphics", "");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "tests/tests.zig" },
        .link_libc = true,
    });

    tests.root_module.addImport("graphics", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
