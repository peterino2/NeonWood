const std = @import("std");
const SpirvReflect = @import("SpirvReflect");

// pub fn addLib(b: *std.Build, exe: *std.Build.Step.Compile, comptime pathPrefix: []const u8, cflags: []const []const u8, graphicsBackend: anytype) void {
//     _ = cflags;
//     _ = b;
//
//     if (graphicsBackend == .Vulkan) {
//         exe.addIncludePath(.{ .path = pathPrefix ++ "/lib/vulkan_inc" });
//     }
//
//     if (graphicsBackend == .OpenGlES_UIOnly) {
//         exe.addIncludePath(.{ .path = pathPrefix ++ "/lib/gl/gles-2.0/include" });
//     }
//
//     exe.addIncludePath(.{ .path = pathPrefix ++ "/lib" });
//     exe.addIncludePath(.{ .path = pathPrefix });
//
//     exe.addLibraryPath(.{ .path = pathPrefix ++ "/lib" });
// }

const dependencyList = [_][]const u8{
    "vulkan",
    "vma",
    "glfw3",
    "core",
    "assets",
    "platform",
};

pub fn build(b: std.Build) void {
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

    const spirvGen = SpirvReflect.SpirvGenerator.init(b, .{});
    spirvGen.addShader(mod, "shaders/triangle_mesh.vert", "triangle_mesh_vert");
    spirvGen.addShader(mod, "shaders/default_lit.frag", "default_lit");

    spirvGen.addShader(mod, "shaders/debug.vert", "debug_vert");
    spirvGen.addShader(mod, "shaders/debug.frag", "debug_vert");
}
