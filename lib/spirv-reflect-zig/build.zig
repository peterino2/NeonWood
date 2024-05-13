// Copyright (c) peterino2@github.com

const std = @import("std");

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
    b: *std.Build,
    spirv_build: *std.Build,
    glslTypes: *std.Build.Module,

    reflect: *std.Build.Step.Compile,

    const BuildOptions = struct {
        importName: []const u8 = "SpirvReflect",
        optimize: std.builtin.OptimizeMode = .Debug,
    };

    fn initFromBuilder(b: *std.Build, spirv_build: *std.Build, opts: BuildOptions) SpirvGenerator2 {
        const reflect = spirv_build.addExecutable(.{
            .name = "spirv-reflect-zig",
            .root_source_file = .{ .path = "src/main.zig" },
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

    pub fn init(b: *std.Build, opts: BuildOptions) SpirvGenerator2 {
        const dep = b.dependency(opts.importName, .{});
        return initFromBuilder(b, dep.builder, opts);
    }

    pub fn createShader(
        self: SpirvGenerator2,
        shaderPath: std.Build.LazyPath,
        shaderName: []const u8,
    ) struct { mod: *std.Build.Module, spvArtifactInstall: *std.Build.Step } {
        const finalSpv = self.b.fmt("shaders/{s}.spv", .{shaderName});
        const finalJson = self.b.fmt("shaders/{s}.json", .{shaderName});
        const finalZig = self.b.fmt("reflectedTypes/{s}.zig", .{shaderName});

        const shaderCompile = self.b.addSystemCommand(&[_][]const u8{"glslc"});
        shaderCompile.addFileArg(shaderPath);
        shaderCompile.addArg("--target-env=vulkan1.2");
        shaderCompile.addArg("-o");
        const spvOutputFile = shaderCompile.addOutputFileArg(finalSpv);

        const spvOutputArtifact = self.b.addInstallFile(spvOutputFile, finalSpv);
        spvOutputArtifact.step.dependOn(&shaderCompile.step);

        const jsonReflectStep = self.spirv_build.addSystemCommand(&[_][]const u8{"spirv-cross"});
        jsonReflectStep.addFileArg(spvOutputFile);
        jsonReflectStep.addArg("--reflect");
        jsonReflectStep.addArg("--output");
        const outputJson = jsonReflectStep.addOutputFileArg(finalJson);

        jsonReflectStep.step.dependOn(&spvOutputArtifact.step);

        const jsonReflectOutput = self.b.addInstallFile(outputJson, finalJson);
        jsonReflectOutput.step.dependOn(&jsonReflectStep.step);

        const run_cmd = self.b.addRunArtifact(self.reflect);
        run_cmd.step.dependOn(&jsonReflectOutput.step);
        run_cmd.addFileArg(outputJson);
        run_cmd.addArg("-o");
        const outputZigFile = run_cmd.addOutputFileArg(finalZig);

        const module = self.spirv_build.createModule(.{
            .root_source_file = outputZigFile,
        });

        module.addImport("glslTypes", self.glslTypes);

        return .{ .mod = module, .spvArtifactInstall = &spvOutputArtifact.step };
    }

    // creates a shader and immediately adds it to the executable
    pub fn addShader(
        self: SpirvGenerator2,
        module: *std.Build.Module,
        shaderPath: []const u8,
        shaderName: []const u8,
    ) void {
        const results = self.createShader(.{ .path = shaderPath }, shaderName);
        module.addImport(shaderName, results.mod);
    }

    pub fn addShaderInstallRef(self: *SpirvGenerator2, exe: *std.Build.Step.Compile, shaderPath: []const u8, shaderName: []const u8) void {
        const results = self.createShader(.{ .path = shaderPath }, shaderName);
        exe.step.dependOn(results.spvArtifactInstall);
    }
};

pub const SpirvGenerator = struct {
    steps: std.ArrayList(*std.Build.Step),
    exe: *std.Build.Step.Compile,
    b: *std.Build,
    step: *std.Build.Step,
    repoPath: []const u8,
    installed: std.StringHashMap(bool),
    glslTypes: *std.Build.Module,

    pub fn init(
        b: *std.Build,
        opts: struct {
            target: std.Build.ResolvedTarget,
            optimize: std.builtin.Mode,
            repoPath: []const u8 = ".",
            addInstallStep: bool = true,
        },
    ) @This() {
        const mainPath = b.fmt("{s}/main.zig", .{opts.repoPath});
        const glslTypesPath = b.fmt("{s}/glslTypes.zig", .{opts.repoPath});

        const exe = b.addExecutable(.{
            .name = "spirv-reflect-zig",
            .root_source_file = .{ .path = mainPath },
            .target = opts.target,
            .optimize = opts.optimize,
        });

        var self = @This(){
            .b = b,
            .steps = std.ArrayList(*std.Build.Step).init(b.allocator),
            .exe = exe,
            .step = b.step("spirv", "compiles all glsl files into spirv binaries and generates .zig types"),
            .repoPath = opts.repoPath,
            .glslTypes = b.addModule("glslTypes", .{
                .root_source_file = .{ .path = glslTypesPath },
            }),
            .installed = std.StringHashMap(bool).init(b.allocator),
        };

        self.step.dependOn(&exe.step);

        if (opts.addInstallStep) {
            b.installArtifact(exe);
        }

        return self;
    }

    fn compileAndReflectGlsl(
        self: *@This(),
        b: *std.Build,
        options: struct {
            source_file: std.Build.LazyPath,
            output_name: []const u8,
            shaderCompilerCommand: []const []const u8, // default this is glslc --target-env=vulkan1.2
            shaderCompilerOutputFlag: []const u8, // in default, this is -o
        },
    ) struct {
        spv_out: std.Build.LazyPath,
        json_out: std.Build.LazyPath,
        step: *std.Build.Step,
        glslcCompileStep: *std.Build.Step,
        installGlslc: *std.Build.Step,
    } {
        const finalSpv = b.fmt("shaders/{s}.spv", .{options.output_name});
        const finalJson = b.fmt("shaders/{s}.json", .{options.output_name});

        //const compileStep = b.addSystemCommand(&[_][]const u8{ "glslc", "--target-env=vulkan1.2" });
        const compileStep = b.addSystemCommand(options.shaderCompilerCommand);
        compileStep.addFileArg(options.source_file);
        compileStep.addArg(options.shaderCompilerOutputFlag);

        const spvOutputFile = compileStep.addOutputFileArg(finalSpv);

        const jsonReflectStep = b.addSystemCommand(&[_][]const u8{"spirv-cross"});
        jsonReflectStep.addFileArg(spvOutputFile);
        jsonReflectStep.addArg("--reflect");
        jsonReflectStep.addArg("--output");
        const outputJson = jsonReflectStep.addOutputFileArg(finalJson);

        var reflect = b.allocator.create(std.Build.Step) catch unreachable;

        // reflect.* = std.Build.Step.init(.{ .id = .custom, .name = options.output_name, .owner = b, .makeFn = make });
        // reflect.dependOn(&b.addInstallFile(spvOutputFile, finalSpv).step);
        // reflect.dependOn(&b.addInstallFile(outputJson, finalJson).step);

        reflect.dependOn(&jsonReflectStep.step);

        if (self.installed.get(finalSpv)) |exists| {
            _ = exists;
        } else {
            b.getInstallStep().dependOn(&b.addInstallFile(spvOutputFile, finalSpv).step);
            self.installed.put(finalSpv, true) catch unreachable;
        }

        return .{
            .json_out = outputJson,
            .spv_out = spvOutputFile,
            .step = reflect,
            .glslcCompileStep = &compileStep.step,
            .installGlslc = &b.addInstallFile(spvOutputFile, finalSpv).step,
        };
    }

    pub fn addShader(
        self: *@This(),
        options: struct {
            exe: *std.Build.Step.Compile,
            sourceFile: std.Build.LazyPath,
            shaderName: []const u8,
            shaderCompilerCommand: []const []const u8,
            shaderCompilerOutputFlag: []const u8,
            embedFile: bool = false,
        },
    ) void {
        const results = self.compileAndReflectGlsl(self.b, .{
            .source_file = options.sourceFile,
            .output_name = options.shaderName,
            .shaderCompilerCommand = options.shaderCompilerCommand,
            .shaderCompilerOutputFlag = options.shaderCompilerOutputFlag,
        });
        var b = self.b;

        const outputFile = b.fmt("reflectedTypes/{s}.zig", .{options.shaderName});
        const run_cmd = b.addRunArtifact(self.exe);

        run_cmd.addFileArg(results.json_out);
        run_cmd.addArg("-o");
        const outputZigFile = run_cmd.addOutputFileArg(outputFile);

        if (options.embedFile) {
            const spvFile = b.fmt("{s}.spv", .{options.shaderName});
            run_cmd.addArg("-e");
            run_cmd.addArg(spvFile);
        }

        run_cmd.step.dependOn(&self.exe.step);
        self.step.dependOn(&run_cmd.step);
        self.step.dependOn(results.step);
        self.step.dependOn(&b.addInstallFile(outputZigFile, outputFile).step);

        const generatedFileRef = b.allocator.create(std.Build.GeneratedFile) catch unreachable;
        generatedFileRef.* = .{
            .step = self.step,
            .path = b.fmt("zig-out/{s}", .{outputFile}),
        };

        var imports = self.b.allocator.alloc(std.Build.Module.Import, 1) catch unreachable;
        imports[0] = .{ .name = "glslTypes", .module = self.glslTypes };

        const module = b.addModule(options.shaderName, .{
            .root_source_file = outputZigFile,
            .imports = imports,
        });

        options.exe.root_module.addImport(options.shaderName, module);
        options.exe.step.dependOn(&run_cmd.step);
        options.exe.step.dependOn(results.step);
        options.exe.step.dependOn(results.installGlslc);
    }

    pub fn shader(
        self: *@This(),
        exe: *std.Build.Step.Compile,
        source: []const u8,
        shaderName: []const u8,
        opts: struct {
            shaderCompilerCommand: []const []const u8 = &.{ "glslc", "--target-env=vulkan1.2" },
            shaderCompilerOutputFlag: []const u8 = "-o",
            embedFile: bool = false,
        },
    ) void {
        self.addShader(.{
            .exe = exe,
            .sourceFile = .{ .path = source },
            .shaderName = shaderName,
            .shaderCompilerCommand = opts.shaderCompilerCommand,
            .shaderCompilerOutputFlag = opts.shaderCompilerOutputFlag,
            .embedFile = opts.embedFile,
        });
    }
};

// Example build function.
//
// Run zig build run to run the example
//
// zig build install to generate the CLI tool.

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = target;
    _ = optimize;

    const spirvGen = SpirvGenerator2.initFromBuilder(b, b, .{});
    b.installArtifact(spirvGen.reflect);

    // ==== create the spirv compiler and generate both .spv files and .zig files ====
    // var spirvCompile = SpirvGenerator.init(b, .{
    //     .target = target,
    //     .optimize = optimize,
    //     .repoPath = "src",
    // });

    // // This returns a module which contains the reflected.zig file which correct
    // // data layout
    // const test_vk = spirvCompile.shader("shaders/test_vk.vert", "test_vk", .{ .embedFile = true });
    // // ===============================================================================

    // // Create your executables as you normally would
    // const exe = b.addExecutable(.{
    //     .name = "example",
    //     .root_source_file = .{ .path = "example.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // exe.addModule("test_vk", test_vk);
    // b.installArtifact(exe);

    // var run_step = b.step("run", "runs my program");
    // const run_cmd = b.addRunArtifact(exe);
    // run_cmd.step.dependOn(b.getInstallStep());
    // run_step.dependOn(&run_cmd.step);

}
