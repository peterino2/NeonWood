const std = @import("std");
const vkgen = @import("generator/index.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const macos_vulkan_sdk = b.graph.env_map.hash_map.get("VULKAN_SDK");

    const gen = vkgen.VkGenerateStep.init(b, "vk.xml", "vk.zig");

    const mod = gen.package;

    if (target.result.os.tag == .windows) {
        mod.addObjectFile(.{ .path = "objs/vulkan-1.lib" });
    } else if (target.result.os.tag == .macos) {
        mod.addLibraryPath(.{ .path = "/opt/homebrew/lib/" });
        mod.addLibraryPath(.{
            .path = b.fmt("{s}/1.3.250.1/macOS/lib/", .{macos_vulkan_sdk.?}),
        });
    } else {
        mod.linkSystemLibrary("vulkan", .{});
    }

    const test_step = b.step("test-vulkan-integration", "");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "test_integration.zig" },
        .link_libc = true,
    });

    tests.root_module.addImport("vulkan", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
