//!
b: *std.Build,
target: std.Build.ResolvedTarget,
optimize: std.builtin.Mode,
opts: BuildSystemOpts,

const BuildSystem = @This();
const std = @import("std");

const SpirvReflect = @import("SpirvReflect");

pub const AddProgramOptions = struct {
    root_source_file: std.Build.LazyPath,
};

pub const BuildSystemOpts = struct {
    vulkan_sdk: ?[]const u8, // usually not set for windows.
    enableTracy: bool = false,
};

pub fn init(b: *std.Build) BuildSystem {
    _ = b;
}

pub fn addProgram(self: *BuildSystem, opts: AddProgramOptions) void {
    _ = self;
    _ = opts;
}
