const std = @import("std");
const papyrusBuild = @import("../../modules/ui/papyrus/build.zig");

const projectPath = "projects/utils";

const SharedOpts = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
};

pub fn buildUtilities(b: *std.Build, opts: SharedOpts) void {
    const fontExtractor = new_utility(b, "fontExtractor", opts);
    fontExtractor.linkLibC();
    fontExtractor.linkLibCpp();
    fontExtractor.addCSourceFile(.{ .file = .{ .path = "modules/ui/papyrus/compat.cpp" }, .flags = &.{""} });
    fontExtractor.addIncludePath(.{ .path = "modules/ui/papyrus/" });
}

pub fn new_utility(b: *std.Build, comptime utilName: []const u8, opts: SharedOpts) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = utilName,
        .root_source_file = .{ .path = projectPath ++ "/" ++ utilName ++ ".zig" },
        .target = opts.target,
        .optimize = opts.optimize,
    });

    _ = b.addInstallArtifact(exe, .{});

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step(utilName, "Run the " ++ utilName ++ " utility");

    run_step.dependOn(&run_cmd.step);

    return exe;
}
