const std = @import("std");

// pub fn addLib(b: *std.Build, exe: *std.Build.Step.Compile, comptime packagePath: []const u8, cflags: []const []const u8, enableTracy: bool, target: anytype) void {
//     _ = cflags;
//     exe.addIncludePath(.{ .path = packagePath ++ "/lib" });
//     spng.addLib(b, exe, packagePath ++ "/lib/zig-spng");
//
//     nfdBuild.addLib(b, exe, packagePath ++ "/lib/nfd", target);
//
//     if (enableTracy) {
//         zigTracy.link(b, exe, packagePath ++ "/lib/zig_tracy/tracy-0.7.8/");
//     } else {
//         zigTracy.link(b, exe, null);
//     }
// }

const dependencyList: [][]const u8 = &.{
    "spng",
    "cgltf",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spng_dep = b.dependency("spng", .{ .target = target, .optimize = optimize });

    const module = b.addModule("core", .{ .root_source_file = .{ .path = "src/root.zig" } });
    module.addImport("spng", spng_dep.module("spng"));
}
