//!
b: *std.Build,
target: std.Build.ResolvedTarget,
optimize: std.builtin.Mode,

const BuildSystem = @This();
const std = @import("std");

const SpirvReflect = @import("SpirvReflect");

pub const AddProgramOptions = struct {};

pub fn init(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) BuildSystem {
    return .{
        .b = b,
        .target = target,
        .optimize = optimize,
    };
}

pub fn addProgram(self: *BuildSystem, comptime name: []const u8, comptime desc: []const u8, opts: AddProgramOptions) void {
    _ = desc;

    const b = self.b;

    const exe = b.addExecutable(.{
        .name = name,
        .target = self.target,
        .optimize = self.optimize,
    });

    _ = exe;
    _ = opts;
}

pub fn build(b: std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    b.addModule("nw", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "engine/neonwood.zig" },
    });
}
