const std = @import("std");

// I think I will do a convention of one dependency per module
const dependencyList = [_][]const u8{
    "spng",
    "cgltf",
    "miniaudio",
    "glfw3",
    "nfd",
    "objLoader",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_step = b.step("testAll", "run unit tests");

    const allTests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/root.zig" },
    });

    for (dependencyList) |dependencyName| {
        const dep = b.dependency(dependencyName, .{
            .target = target,
            .optimize = optimize,
        });

        allTests.root_module.addImport(dependencyName, dep.module(dependencyName));

        var iter = dep.builder.top_level_steps.iterator();
        while (iter.next()) |entry| {
            if (std.mem.startsWith(u8, entry.key_ptr.*, "test")) {
                test_step.dependOn(&entry.value_ptr.*.step);
            }
        }
    }

    const runArtifact = b.addRunArtifact(allTests);
    test_step.dependOn(&runArtifact.step);
}
