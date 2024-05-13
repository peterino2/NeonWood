//!
b: *std.Build,
nw_builder: *std.Build,
target: std.Build.ResolvedTarget,
optimize: std.builtin.Mode,
nw_mod: *std.Build.Module,
spirvReflect: SpirvReflect.SpirvGenerator2,
relativeRoot: []const u8,

const engineDepList = [_][]const u8{
    "assets",
    "audio",
    "core",
    "graphics",
    "papyrus",
    "platform",
    "ui",
};

const BuildSystem = @This();
const std = @import("std");

const SpirvReflect = @import("SpirvReflect");
pub const AddProgramOptions = struct {};

pub fn init(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, relativeRoot: []const u8) BuildSystem {
    const nwdep = b.dependency("NeonWood", .{ .target = target, .optimize = optimize });

    return .{
        .b = b,
        .nw_builder = nwdep.builder,
        .target = target,
        .optimize = optimize,
        .nw_mod = nwdep.module("NeonWood"),
        .relativeRoot = relativeRoot,
        .spirvReflect = SpirvReflect.SpirvGenerator2.init(b, .{}),
    };
}

pub fn addProgram(self: *BuildSystem, comptime name: []const u8, comptime desc: []const u8, opts: AddProgramOptions) *std.Build.Step.Compile {
    const b = self.b;

    const exe = self.nw_builder.addExecutable(.{
        .name = name,
        .target = self.target,
        .optimize = self.optimize,
        .root_source_file = .{ .path = "engine/main.zig" },
    });

    b.installArtifact(exe);
    const runArtifact = b.addRunArtifact(exe);
    const run_exe = b.step("run-" ++ name, desc);
    run_exe.dependOn(&runArtifact.step);

    // main path = name/main.zig
    const mod = b.addModule(name, .{
        .target = self.target,
        .optimize = self.optimize,
        .root_source_file = .{ .path = name ++ "/main.zig" },
    });
    _ = opts;

    exe.root_module.addImport("main", mod);
    exe.root_module.addImport("NeonWood", self.nw_mod);
    mod.addImport("NeonWood", self.nw_mod);

    self.spirvReflect.addShaderInstallRef(exe, b.fmt("{s}/engine/graphics/shaders/triangle_mesh.vert", .{self.relativeRoot}), "triangle_mesh_vert");
    self.spirvReflect.addShaderInstallRef(exe, b.fmt("{s}/engine/graphics/shaders/default_lit.frag", .{self.relativeRoot}), "default_lit");
    self.spirvReflect.addShaderInstallRef(exe, b.fmt("{s}/engine/graphics/shaders/debug.vert", .{self.relativeRoot}), "debug_vert");
    self.spirvReflect.addShaderInstallRef(exe, b.fmt("{s}/engine/graphics/shaders/debug.frag", .{self.relativeRoot}), "debug_frag");

    self.spirvReflect.addShaderInstallRef(exe, b.fmt("{s}/engine/ui/shaders/PapyrusRect.vert", .{self.relativeRoot}), "papyrus_vk_vert");
    self.spirvReflect.addShaderInstallRef(exe, b.fmt("{s}/engine/ui/shaders/PapyrusRect.frag", .{self.relativeRoot}), "papyrus_vk_frag");
    self.spirvReflect.addShaderInstallRef(exe, b.fmt("{s}/engine/ui/shaders/FontSDF.vert", .{self.relativeRoot}), "FontSDF_vert");
    self.spirvReflect.addShaderInstallRef(exe, b.fmt("{s}/engine/ui/shaders/FontSDF.frag", .{self.relativeRoot}), "FontSDF_frag");

    b.getInstallStep().dependOn(self.nw_builder.getInstallStep());

    return exe;
}

// ========= standalone build instance =======
// maybe it should be an engine launcher or something..
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const spirvDep = b.dependency("SpirvReflect", .{ .target = target, .optimize = optimize });
    _ = spirvDep;

    const mod = b.addModule("NeonWood", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = .{ .path = "engine/neonwood.zig" },
    });

    for (engineDepList) |depName| {
        const dep = b.dependency(depName, .{ .target = target, .optimize = optimize });
        mod.addImport(depName, dep.module(depName));
        b.getInstallStep().dependOn(dep.builder.getInstallStep());
    }
}
