// Copyright (c) peterino2@github.com

const std = @import("std");
const Build = std.Build;
const LazyPath = Build.LazyPath;

// 1. for each vertex/fragment shader file invoke
//  glslc --target-env=vulkan1.2 <input file> -o <input file>.spv
//
// 2. for each generated .spv file i want to invoke
//  spirv-cross --reflect <input file>.spv --output <input file>.json
//
// 3. compile the reflect program, and invoke it on the json file.
//  spirv-reflect-zig <input file>.json
//
//  <input file>.zig

pub const SpirvGenerator2 = struct {
    b: *Build,
    spirv_build: *Build,
    glslTypes: *Build.Module,

    reflect: *Build.Step.Compile,

    const BuildOptions = struct {
        importName: []const u8 = "SpirvReflect",
        optimize: std.builtin.OptimizeMode = .Debug,
    };

    fn initFromBuilder(b: *Build, spirv_build: *Build, opts: BuildOptions) SpirvGenerator2 {
        const reflect = spirv_build.addExecutable(.{
            .name = "spirv-reflect-zig",
            .root_source_file = spirv_build.path("src/main.zig"),
            .target = spirv_build.host,
            .optimize = opts.optimize,
        });

        const dep = spirv_build.dependency("glslTypes", .{
            .target = spirv_build.host,
            .optimize = opts.optimize,
        });

        return .{
            .b = b,
            .spirv_build = spirv_build,
            .reflect = reflect,
            .glslTypes = dep.module("glslTypes"),
            //spirv_build.addModule("glslTypes", .{
            //.root_source_file = .{ .path = "src/glslTypes.zig" },
            //}),
        };
    }

    pub fn init(b: *Build, opts: BuildOptions) SpirvGenerator2 {
        const dep = b.dependency(opts.importName, .{});
        return initFromBuilder(b, dep.builder, opts);
    }

    pub fn createShader(
        self: SpirvGenerator2,
        shaderPath: Build.LazyPath,
        shaderName: []const u8,
    ) struct { mod: *Build.Module, spvArtifactInstall: *Build.Step } {
        const importSpv = self.b.fmt("{s}.spv", .{shaderName});
        const finalSpv = self.b.fmt("shaders/{s}.spv", .{shaderName});
        const finalJson = self.b.fmt("shaders/{s}.json", .{shaderName});
        const finalZig = self.b.fmt("reflectedTypes/{s}.zig", .{shaderName});

        const shaderCompile = self.b.addSystemCommand(&[_][]const u8{"glslc"});
        shaderCompile.addFileArg(shaderPath);
        shaderCompile.addArg("--target-env=vulkan1.2");
        shaderCompile.addArg("-o");
        const spvOutputFile = shaderCompile.addOutputFileArg(finalSpv);

        const spvOutputArtifact = self.b.addInstallFile(spvOutputFile, finalSpv);

        const jsonReflectStep = self.spirv_build.addSystemCommand(&[_][]const u8{"spirv-cross"});
        jsonReflectStep.addFileArg(spvOutputFile);
        jsonReflectStep.addArg("--reflect");
        jsonReflectStep.addArg("--output");
        const outputJson = jsonReflectStep.addOutputFileArg(finalJson);

        const run_cmd = self.b.addRunArtifact(self.reflect);
        run_cmd.addFileArg(outputJson);
        run_cmd.addArg("-e");
        run_cmd.addArg(importSpv);
        run_cmd.addArg("-o");
        const outputZigFile = run_cmd.addOutputFileArg(finalZig);

        const module = self.spirv_build.createModule(.{
            .root_source_file = outputZigFile,
        });

        module.addAnonymousImport(importSpv, .{
            .root_source_file = spvOutputFile,
        });

        module.addImport("glslTypes", self.glslTypes);

        return .{ .mod = module, .spvArtifactInstall = &spvOutputArtifact.step };
    }

    // creates a shader and immediately adds it to the executable
    pub fn addShader(
        self: SpirvGenerator2,
        module: *Build.Module,
        shaderPath: LazyPath,
        shaderName: []const u8,
    ) void {
        const results = self.createShader(shaderPath, shaderName);
        module.addImport(shaderName, results.mod);
    }

    pub fn addShaderInstallRef(self: *SpirvGenerator2, exe: *Build.Step.Compile, shader_path: LazyPath, shader_name: []const u8) void {
        const results = self.createShader(shader_path, shader_name);
        exe.step.dependOn(results.spvArtifactInstall);
    }
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    _ = optimize;
    _ = target;
}
