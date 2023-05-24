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
    generator: SpirvGenerator,
    options: *std.build.OptionsStep,
    enable_tracy: bool,

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
        options.addOption(bool, "release_build", false); // set to true to override all other debug flags.
        //
        const enable_tracy = b.option(bool, "tracy", "Enables integration with tracy profiler") orelse false;

        self.* = @This(){
            .b = b,
            .target = target,
            .optimize = optimize,
            .cflags = std.ArrayList([]const u8).init(b.allocator),
            .enginePath = b.fmt("{s}", .{enginePath}),
            .opts = opts,
            .generator = SpirvGenerator.init(b, .{
                .target = target,
                .optimize = optimize,
                .repoPath = "modules/graphics/lib/spirv-reflect-zig/src",
            }),
            .enable_tracy = enable_tracy,
            .options = options,
        };

        return self;
    }

    fn addCFlags(self: *@This()) !void {
        var b = self.b;

        try self.cflags.append(b.fmt("-I{s}/modules/core/lib/stb/", .{self.enginePath}));
        try self.cflags.append(try b.fmt("-fno-sanitize=all", .{}));

        if (self.opts.useTracy) {
            try self.cflags.append(try b.fmt("-DTRACY_ENABLE=1", .{}));
            try self.cflags.append(try b.fmt("-DTRACY_HAS_CALLSTACK=0", .{}));
            try self.cflags.append(try b.fmt("-D_Win32_WINNT=0x601", .{}));
        }
    }

    pub fn addProgram(
        self: *@This(),
        comptime name: []const u8,
        comptime mainFile: []const u8,
        comptime description: []const u8,
    ) *std.build.LibExeObjStep {
        const exe = self.b.addExecutable(.{
            .name = name,
            .root_source_file = .{ .path = mainFile },
            .target = self.target,
            .optimize = self.optimize,
        });

        self.b.installArtifact(exe);
        exe.linkLibC();

        exe.addOptions("game_build_opts", self.options);

        if (self.target.getOs().tag == .windows) {
            exe.linkSystemLibrary("glfw3dll");
        } else {
            exe.linkSystemLibrary("glfw");
            exe.linkSystemLibrary("dl");
            exe.linkSystemLibrary("pthread");
        }
        exe.linkSystemLibrary("m");

        assets.addLibs(self.b, exe, "modules/assets", self.cflags.items);
        audio.addLibs(self.b, exe, "modules/audio", self.cflags.items);
        core.addLibs(self.b, exe, "modules/core", self.cflags.items);
        game.addLibs(self.b, exe, "modules/game", self.cflags.items);
        graphics.addLibs(self.b, exe, "modules/graphics", self.cflags.items);
        platform.addLibs(self.b, exe, "modules/platform", self.cflags.items);
        ui.addLibs(self.b, exe, "modules/ui", self.cflags.items);

        self.addDefaultIncludeDirs(exe);

        const runCmd = self.b.addRunArtifact(exe);
        runCmd.step.dependOn(self.b.getInstallStep());
        if (self.b.args) |args| {
            runCmd.addArgs(args);
        }

        const runStep = self.b.step(name, description);
        runStep.dependOn(&runCmd.step);

        return exe;
    }
};
