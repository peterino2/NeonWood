// build library for resources, modules, and codegen

const std = @import("std");

pub fn loadFileAlloc(allocator: std.mem.Allocator, filename: []const u8) []const u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    const filesize = (try file.stat()).size;
    var buffer: []u8 = try allocator.alignedAlloc(u8, 8, filesize);
    try file.reader().readNoEof(buffer);
    return buffer;
}

const NwProgram = struct {
    b: *std.build.Builder,
    exe: *std.build.LibExeObjStep,
    name: []const u8,

    pub fn init(b: std.build.Builder, exe: *std.build.LibExeObjStep, name: []const u8) *@This() {
        var self = b.allocator.create(@This());

        self.* = @This(){
            .b = b,
            .exe = exe,
            .name = name,
        };

        return self;
    }

    pub fn addShader(self: *@This(), name: []const u8, path: []const u8) void {
        _ = path;
        _ = name;
        _ = self;
    }
};

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

    pub fn init(
        b: *std.build.Builder,
        target: anytype,
        optimize: anytype,
        opts: BuildSystemOpts,
    ) *@This() {
        var self = b.allocator.create(@This()) catch unreachable;

        var enginePathBuffer = std.mem.zeroes([std.fs.MAX_PATH_BYTES]u8);
        var enginePath = try std.fs.realpath(b.build_root.path.?, &enginePathBuffer);

        self.* = @This(){
            .b = b,
            .target = target,
            .optimize = optimize,
            .cflags = std.ArrayList([]const u8).init(b.allocator),
            .enginePath = b.fmt("{s}", .{enginePath}),
            .opts = opts,
        };

        self.addCFlags() catch unreachable;

        return self;
    }

    pub fn addCFlags(self: *@This()) !void {
        var b = self.b;

        try self.cflags.append(b.fmt("-I{s}/modules/core/lib/stb/", .{self.enginePath}));

        if (self.opts.useTracy) {
            try self.cflags.append(try b.fmt("-DTRACY_ENABLE=1", .{}));
            try self.cflags.append(try b.fmt("-DTRACY_HAS_CALLSTACK=0", .{}));
            try self.cflags.append(try b.fmt("-D_Win32_WINNT=0x601", .{}));
        }
        try self.cflags.append(try b.fmt("-fno-sanitize=all", .{}));
    }

    pub fn addProgram(self: *@This(), name: []const u8, mainFile: []const u8) *NwProgram {
        const exe = self.b.addExecutable(.{
            .name = name,
            .root_source_file = .{ .path = mainFile },
            .target = self.target,
            .optimize = self.optimize,
        });

        return NwProgram.init(self.b, exe, name);
    }
};
