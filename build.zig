//!
b: *std.Build,
nw_builder: *std.Build,
target: std.Build.ResolvedTarget,
optimize: std.builtin.Mode,
nw_mod: *std.Build.Module,
spirvReflect: SpirvReflect.SpirvGenerator2,

const engineDepList = [_][]const u8{ "assets", "audio", "core", "graphics", "papyrus", "platform", "ui", "vkImgui" };

const BuildSystem = @This();
const std = @import("std");
const Build = std.Build;
const LazyPath = Build.LazyPath;

const SpirvReflect = @import("SpirvReflect");

pub const InitOptions = struct {
    import_name: []const u8 = "NeonWood",
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

pub fn init(b: *std.Build, opts: InitOptions) BuildSystem {
    const nwdep = b.dependency(opts.import_name, .{
        .target = opts.target,
        .optimize = opts.optimize,
        .slow_logging = b.option(bool, "slow_logging", "Disables buffered logging, takes a performance hit but timing information across threads is preserved") orelse false,
    });

    return .{
        .b = b,
        .nw_builder = nwdep.builder,
        .target = opts.target,
        .optimize = opts.optimize,
        .nw_mod = nwdep.module("NeonWood"),
        .spirvReflect = SpirvReflect.SpirvGenerator2.init(b, .{}),
    };
}

pub const AddProgramOptions = struct {
    name: []const u8,
    desc: []const u8,
    root_source_file: LazyPath,
};

pub fn addProgram(self: *BuildSystem, opts: AddProgramOptions) *std.Build.Step.Compile {
    const b = self.b;

    const exe = self.nw_builder.addExecutable(.{
        .name = opts.name,
        .target = self.target,
        .optimize = self.optimize,
        .root_source_file = self.nw_builder.path("engine/main.zig"),
    });

    b.installArtifact(exe);
    const runArtifact = b.addRunArtifact(exe);
    const run_exe = b.step(self.b.fmt("run-{s}", .{opts.name}), opts.desc);
    run_exe.dependOn(&runArtifact.step);

    // main path = name/main.zig
    const mod = b.addModule(opts.name, .{
        .target = self.target,
        .optimize = self.optimize,
        .root_source_file = opts.root_source_file,
    });

    exe.root_module.addImport("main", mod);
    exe.root_module.addImport("NeonWood", self.nw_mod);
    mod.addImport("NeonWood", self.nw_mod);

    self.spirvReflect.addShaderInstallRef(exe, self.nw_builder.path("engine/graphics/shaders/triangle_mesh.vert"), "triangle_mesh_vert");
    self.spirvReflect.addShaderInstallRef(exe, self.nw_builder.path("engine/graphics/shaders/default_lit.frag"), "default_lit");
    self.spirvReflect.addShaderInstallRef(exe, self.nw_builder.path("engine/graphics/shaders/debug.vert"), "debug_vert");
    self.spirvReflect.addShaderInstallRef(exe, self.nw_builder.path("engine/graphics/shaders/debug.frag"), "debug_frag");

    self.spirvReflect.addShaderInstallRef(exe, self.nw_builder.path("engine/ui/shaders/PapyrusRect.vert"), "papyrus_vk_vert");
    self.spirvReflect.addShaderInstallRef(exe, self.nw_builder.path("engine/ui/shaders/PapyrusRect.frag"), "papyrus_vk_frag");
    self.spirvReflect.addShaderInstallRef(exe, self.nw_builder.path("engine/ui/shaders/FontSDF.vert"), "FontSDF_vert");
    self.spirvReflect.addShaderInstallRef(exe, self.nw_builder.path("engine/ui/shaders/FontSDF.frag"), "FontSDF_frag");

    b.getInstallStep().dependOn(self.nw_builder.getInstallStep());

    return exe;
}

// pub fn createGameOptions(b: *std.Build) *std.Build.Step.Options {
//     const opts = b.addOptions();
//
//     // build options for core.zig
//     opts.addOption(
//         bool,
//         "mutex_job_queue",
//         b.option(bool, "mutex_job_queue", "temporary test, reverts to old mutex based queue behaviour in jobs.zig:JobManager") orelse false,
//     );
//     opts.addOption(
//         bool,
//         "zero_logging",
//         b.option(bool, "zero_logging", "disables all logging, only intended for use on job dispatch testing") orelse false,
//     );
//     opts.addOption(
//         bool,
//         "slow_logging",
//         b.option(bool, "slow_logging", "Disables buffered logging, takes a hit to performance but gain timing information on logging") orelse false,
//     );
//     opts.addOption(
//         bool,
//         "force_mailbox",
//         b.option(bool, "force_mailbox", "forces mailbox mode for present mode. unlocks framerate to irresponsible levels") orelse false,
//     );
//
//     return opts;
// }

// ========= standalone build instance =======
// maybe it should be an engine launcher or something..
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spirvDep = b.dependency("SpirvReflect", .{
        .target = target,
        .optimize = optimize,
    });
    _ = spirvDep;

    const mod = b.addModule("NeonWood", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "engine/neonwood.zig" },
    });
    const slow_logging = b.option(bool, "slow_logging", "Disables buffered logging, takes a performance hit but timing information across threads is preserved") orelse false;
    _ = slow_logging;

    for (engineDepList) |depName| {
        const dep = b.dependency(
            depName,
            .{
                .target = target,
                .optimize = optimize,
            },
        );
        mod.addImport(depName, dep.module(depName));
        b.getInstallStep().dependOn(dep.builder.getInstallStep());
    }
}
