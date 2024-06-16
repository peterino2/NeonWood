//!
b: *std.Build,
nw_builder: *std.Build,
target: std.Build.ResolvedTarget,
optimize: std.builtin.Mode,
nw_mod: *std.Build.Module,
spirvReflect: SpirvReflect.SpirvGenerator2,
options: *std.Build.Step.Options,

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
    });

    return .{
        .b = b,
        .nw_builder = nwdep.builder,
        .target = opts.target,
        .optimize = opts.optimize,
        .nw_mod = nwdep.module("NeonWood"),
        .spirvReflect = SpirvReflect.SpirvGenerator2.init(nwdep.builder, .{}),
        .options = createGameOptions(b),
    };
}

pub const AddProgramOptions = struct {
    name: []const u8,
    desc: []const u8,
    root_source_file: LazyPath,
    imports: []const Build.Module.Import = &.{},
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
    if (b.args) |args| {
        runArtifact.addArgs(args);
    }
    const run_exe = b.step(self.b.fmt("run-{s}", .{opts.name}), opts.desc);
    run_exe.dependOn(&runArtifact.step);

    // main path = name/main.zig
    const mod = b.addModule(opts.name, .{
        .target = self.target,
        .optimize = self.optimize,
        .root_source_file = opts.root_source_file,
        .imports = opts.imports,
    });

    exe.root_module.addImport("main", mod);
    exe.root_module.addImport("NeonWood", self.nw_mod);
    mod.addImport("NeonWood", self.nw_mod);
    exe.root_module.addOptions("NeonWoodOptions", self.options);

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

pub fn createGameOptions(b: *std.Build) *std.Build.Step.Options {
    const opts = b.addOptions();

    // build options for core.zig
    opts.addOption(
        bool,
        "mutex_job_queue",
        b.option(bool, "mutex_job_queue", "temporary test, reverts to old mutex based queue behaviour in jobs.zig:JobManager") orelse false,
    );
    opts.addOption(
        bool,
        "zero_logging",
        b.option(bool, "zero_logging", "disables all logging, only intended for use on job dispatch testing") orelse false,
    );
    opts.addOption(
        bool,
        "slow_logging",
        b.option(bool, "slow_logging", "Disables buffered logging, takes a hit to performance but gain timing information on logging") orelse false,
    );
    opts.addOption(
        bool,
        "force_mailbox",
        b.option(bool, "force_mailbox", "forces mailbox mode for present mode. unlocks framerate to irresponsible levels") orelse false,
    );
    opts.addOption(
        bool,
        "use_renderthread",
        b.option(bool, "use_renderthread", "enables the use of renderthread") orelse false,
    );
    return opts;
}

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

    const enable_tracy = b.option(bool, "enable_tracy", "Enables tracy integration") orelse false;
    const assets_dep = b.dependency("assets", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const audio_dep = b.dependency("audio", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const core_dep = b.dependency("core", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const graphics_dep = b.dependency("graphics", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const papyrus_dep = b.dependency("papyrus", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const platform_dep = b.dependency("platform", .{
        .target = target,
        .optimize = optimize,
    });

    const ui_dep = b.dependency("ui", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const vk_imgui_dep = b.dependency("vkImgui", .{
        .target = target,
        .optimize = optimize,
        .enable_tracy = enable_tracy,
    });

    const mod = b.addModule("NeonWood", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("engine/neonwood.zig"),
    });
    mod.addImport("assets", assets_dep.module("assets"));
    mod.addImport("audio", audio_dep.module("audio"));
    mod.addImport("core", core_dep.module("core"));
    mod.addImport("graphics", graphics_dep.module("graphics"));
    mod.addImport("papyrus", papyrus_dep.module("papyrus"));
    mod.addImport("platform", platform_dep.module("platform"));
    mod.addImport("ui", ui_dep.module("ui"));
    mod.addImport("vkImgui", vk_imgui_dep.module("vkImgui"));
}
