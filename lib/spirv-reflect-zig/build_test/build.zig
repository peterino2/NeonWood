const std = @import("std");

const SpirvReflect = @import("SpirvReflect");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spirvGen = SpirvReflect.SpirvGenerator2.init(b, .{});
    b.installArtifact(spirvGen.reflect);

    const test_vk = spirvGen.createShader(.{ .path = "../shaders/test_vk.vert" }, "test_vk");

    const exe = b.addExecutable(.{
        .name = "example",
        .root_source_file = .{ .path = "main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("test_vk", test_vk);
    spirvGen.addShader(&exe.root_module, "../shaders/test_vk.vert", "test_vk2");

    b.installArtifact(exe);
}
