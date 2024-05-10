const std = @import("std");

// I think I will do a convention of one dependency per module
const dependencyList = [_][]const u8{
    "spng",
    "cgltf",
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

        if (dep.builder.top_level_steps.get("test")) |t| {
            test_step.dependOn(&t.step);
        }
    }

    const runArtifact = b.addRunArtifact(allTests);
    test_step.dependOn(&runArtifact.step);
}
