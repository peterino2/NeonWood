// build library for resources, modules, and codegen

const std = @import("std");

const assets = @import("../modules/assets/build.zig");
const graphics = @import("../modules/graphics/build.zig");
const core = @import("../modules/core/build.zig");
const audio = @import("../modules/audio/build.zig");
const game = @import("../modules/game/build.zig");
const platform = @import("../modules/platform/build.zig");
const ui = @import("../modules/ui/build.zig");

const SpirvGenerator = graphics.spirvReflect.SpirvGenerator;

const vkgen = @import("../modules/graphics/lib/vulkan-zig/generator/index.zig");
const vma_build = @import("../modules/graphics/lib/zig-vma/vma_build.zig");

pub fn loadFileAlloc(allocator: std.mem.Allocator, filename: []const u8) []const u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    const filesize = (try file.stat()).size;
    var buffer: []u8 = try allocator.alignedAlloc(u8, 8, filesize);
    try file.reader().readNoEof(buffer);
    return buffer;
}

const BuildSystemOpts = struct {
    useTracy: bool = false,
};

pub const NwBuildSystem = struct {
    b: *std.build.Builder,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
    cflags: std.ArrayList([]const u8),
    enginePath: []const u8,
    opts: BuildSystemOpts,
    spirvGen: SpirvGenerator,
    options: *std.build.OptionsStep,
    enableTracy: bool,

    pub fn init(
        b: *std.build.Builder,
        target: anytype,
        optimize: anytype,
        opts: BuildSystemOpts,
    ) *@This() {
        var self = b.allocator.create(@This()) catch unreachable;

        var enginePathBuffer = std.mem.zeroes([std.fs.MAX_PATH_BYTES]u8);
        var enginePath = std.fs.realpath(b.build_root.path.?, &enginePathBuffer) catch unreachable;

        const options = b.addOptions();
        options.addOption(bool, "validation_layers", b.option(bool, "vulkan_validation", "Enables vulkan validation layers") orelse false);
        options.addOption(bool, "slow_logging", b.option(bool, "slow_logging", "Disables buffered logging, takes a hit to performance but gain timing information on logging") orelse false);
        options.addOption(bool, "release_build", false); // set to true to override all other debug flags.
        //
        const enableTracy = b.option(bool, "tracy", "Enables integration with tracy profiler") orelse false;

        self.* = @This(){
            .b = b,
            .target = target,
            .optimize = optimize,
            .cflags = std.ArrayList([]const u8).init(b.allocator),
            .enginePath = b.fmt("{s}", .{enginePath}),
            .opts = opts,
            .spirvGen = SpirvGenerator.init(b, .{
                .target = target,
                .optimize = optimize,
                .repoPath = "modules/graphics/lib/spirv-reflect-zig/src",
            }),
            .enableTracy = enableTracy,
            .options = options,
        };

        return self;
    }

    fn addCFlags(self: *@This()) !void {
        var b = self.b;

        try self.cflags.append(b.fmt("-I{s}/modules/core/lib/stb/", .{self.enginePath}));

        if (self.opts.useTracy) {
            try self.cflags.append(try b.fmt("-DTRACY_ENABLE=1", .{}));
            try self.cflags.append(try b.fmt("-DTRACY_HAS_CALLSTACK=0", .{}));
            try self.cflags.append(try b.fmt("-D_Win32_WINNT=0x601", .{}));
        }

        try self.cflags.append(try b.fmt("-fno-sanitize=all", .{}));
    }

    pub fn addTest(self: *@This(), comptime name: []const u8) *std.build.LibExeObjStep {
        return self.addProgram(name, "projects/tests/" ++ name ++ ".zig", "a test");
    }

    pub fn addGame(self: *@This(), comptime name: []const u8, comptime description: []const u8) *std.build.LibExeObjStep {
        return self.addProgram(name, "projects/" ++ name ++ "/main.zig", description);
    }

    pub fn addProgram(
        self: *@This(),
        comptime name: []const u8,
        comptime mainFile: []const u8,
        comptime description: []const u8,
    ) *std.build.LibExeObjStep {
        const exe = self.b.addExecutable(.{
            .name = name,
            .root_source_file = .{ .path = "root.zig" },
            .target = self.target,
            .optimize = self.optimize,
        });

        const mainModule = self.b.addModule(
            name,
            .{ .source_file = .{ .path = mainFile } },
        );
        exe.addModule("main", mainModule);

        self.b.installArtifact(exe);
        exe.linkLibC();
        exe.linkLibCpp();

        exe.addOptions("game_build_opts", self.options);

        if (self.target.getOs().tag == .windows) {
            exe.linkSystemLibrary("glfw3dll");
        } else {
            exe.linkSystemLibrary("glfw");
            exe.linkSystemLibrary("dl");
            exe.linkSystemLibrary("pthread");
        }
        exe.linkSystemLibrary("m");
        self.generateVulkan(exe);

        assets.addLib(self.b, exe, "modules/assets", self.cflags.items);
        audio.addLib(self.b, exe, "modules/audio", self.cflags.items);
        core.addLib(self.b, exe, "modules/core", self.cflags.items, self.enableTracy);
        game.addLib(self.b, exe, "modules/game", self.cflags.items);
        graphics.addLib(self.b, exe, "modules/graphics", self.cflags.items);
        platform.addLib(self.b, exe, "modules/platform", self.cflags.items);
        ui.addLib(self.b, exe, "modules/ui", self.cflags.items);

        const runCmd = self.b.addRunArtifact(exe);
        runCmd.step.dependOn(self.b.getInstallStep());
        if (self.b.args) |args| {
            runCmd.addArgs(args);
        }

        const buildStep = self.b.step(name, description);
        buildStep.dependOn(&exe.step);

        const runStep = self.b.step(self.b.fmt("run-{s}", .{name}), description);
        runStep.dependOn(&runCmd.step);

        self.addShader(exe, "triangle_mesh_vert", "modules/graphics/shaders/triangle_mesh.vert");
        self.addShader(exe, "default_lit", "modules/graphics/shaders/default_lit.frag");

        self.addShader(exe, "debug_vert", "modules/graphics/shaders/debug.vert");
        self.addShader(exe, "debug_frag", "modules/graphics/shaders/debug.frag");

        self.addShader(exe, "papyrus_vk_vert", "modules/ui/papyrus/shaders/papyrus_vk.vert");
        self.addShader(exe, "papyrus_vk_frag", "modules/ui/papyrus/shaders/papyrus_vk.frag");

        self.addShader(exe, "FontSDF_vert", "modules/ui/papyrus/shaders/FontSDF.vert");
        self.addShader(exe, "FontSDF_frag", "modules/ui/papyrus/shaders/FontSDF.frag");

        return exe;
    }

    pub fn generateVulkan(self: *@This(), exe: *std.build.CompileStep) void {
        if (self.target.getOs().tag == .windows) {
            exe.addObjectFile("modules/graphics/lib/zig-vma/test/vulkan-1.lib");
        } else {
            exe.linkSystemLibrary("vulkan");
        }

        // generate the vulkan package
        const gen = vkgen.VkGenerateStep.init(self.b, "modules/graphics/lib/vk.xml", "vk.zig");

        exe.addModule("glslTypes", self.spirvGen.glslTypes);
        vma_build.link(exe, gen.package, self.optimize, self.target, self.b);
        exe.addModule("vulkan", gen.package);
    }

    pub fn addShader(self: *@This(), exe: *std.build.CompileStep, name: []const u8, path: []const u8) void {
        var shader = self.spirvGen.shader(path, name, .{ .embedFile = true });
        exe.addModule(name, shader);
    }
};
