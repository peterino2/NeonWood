const std = @import("std");
const SpirvReflect = @import("SpirvReflect");

pub fn addLib(b: *std.Build, exe: *std.Build.Step.Compile, comptime packagePath: []const u8, cflags: []const []const u8) void {
    _ = b;
    _ = cflags;
    exe.addIncludePath(.{ .path = packagePath ++ "/papyrus/" });
    exe.addCSourceFile(.{ .file = .{ .path = packagePath ++ "/papyrus/compat.cpp" }, .flags = &.{""} });
}

const depList = [_][]const u8{
    "core",
    "assets",
    "graphics",
    "platform",
    "papyrus",
    "vulkan",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("ui", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/ui.zig" },
    });

    for (depList) |depName| {
        const dep = b.dependency(depName, .{ .target = target, .optimize = optimize });
        mod.addImport(depName, dep.module(depName));
    }

    const spirvGen = SpirvReflect.SpirvGenerator2.init(b, .{ .optimize = optimize });
    spirvGen.addShader(mod, "shaders/PapyrusRect.vert", "papyrus_vk_vert");
    spirvGen.addShader(mod, "shaders/PapyrusRect.frag", "papyrus_vk_frag");

    spirvGen.addShader(mod, "shaders/FontSDF.vert", "FontSDF_vert");
    spirvGen.addShader(mod, "shaders/FontSDF.frag", "FontSDF_frag");
}
