const std = @import("std");

pub const log_level: std.log.Level = .debug;

const ProgramOptions = struct {
    outputFile: ?[]u8 = null,
    inputFile: ?[]u8 = null,
    allocator: std.mem.Allocator,

    pub fn deinit(self: @This()) void {
        if (self.outputFile) |f| {
            self.allocator.free(f);
        }

        if (self.inputFile) |f| {
            self.allocator.free(f);
        }
    }

    fn matchArgOpt(arg: []const u8, long: []const u8, short: ?[]const u8) bool {
        if (arg.len < 2) {
            return false;
        }

        if (arg[0] == '-') {
            if (arg[1] == '-') {
                return std.mem.eql(u8, arg[2..], long);
            } else if (short) |s| {
                return arg[1] == s[0];
            }
        }

        return false;
    }

    pub fn parseArgs(allocator: std.mem.Allocator) !@This() {
        var rv: @This() = .{ .allocator = allocator };

        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);

        var i: usize = 0;
        while (i < args.len) : (i += 1) {
            if (i <= 0) {
                continue;
            }

            if (matchArgOpt(args[i], "input", "i")) {
                i += 1;
                rv.inputFile = try allocator.dupe(u8, args[i]);
            } else if (matchArgOpt(args[i], "output", "o")) {
                i += 1;
                rv.outputFile = try allocator.dupe(u8, args[i]);
            }
        }

        if (rv.outputFile == null) {
            rv.outputFile = try allocator.dupe(u8, "imgui.zig");
        }

        return rv;
    }
};

// Parses out all of the cimgui functions and sorts them by calling type.

const ParserContext = struct {
    arena: std.heap.ArenaAllocator,
    backingAllocator: std.mem.Allocator,
    opts: *const ProgramOptions,

    read: []const u8 = undefined,
    buffer: []const u8 = undefined,

    state: enum {
        Empty,
        Label,
        Struct,
        Function,
    } = .Empty,

    pub fn create(allocator: std.mem.Allocator, options: *const ProgramOptions) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .backingAllocator = allocator,
            .arena = std.heap.ArenaAllocator.init(allocator),
            .opts = options,
        };

        return self;
    }

    const ParseResults = struct {};

    pub fn getAllocator(self: *@This()) std.mem.Allocator {
        return self.arena.allocator();
    }

    fn matchString(self: *@This(), str: []const u8) ?usize {
        std.log.info("checking: [{s}]", .{self.read[0..@min(str.len, self.read.len)]});
        if (std.mem.eql(u8, self.read, str)) {
            return str.len - 1;
        }
        return null;
    }

    fn advanceEmpty(self: *@This()) !void {
        if (self.matchString("struct")) |len| {
            std.log.info("STRUCT FOUND! {s}", .{self.read[0 .. len + 1]});
            self.advance(len);
        }
    }

    inline fn next(self: *@This()) !void {

        // because this is just a simple C parser, we don't need to backtrack or do recursive descent.
        // a simple forward pass should be enough to just determine typing
        //
        // phase 1: just parse struct types
        switch (self.state) {
            .Empty => {
                try self.advanceEmpty();
            },
            .Label => {},
            .Struct => {},
            .Function => {},
        }

        self.advance(1);
    }

    inline fn advance(self: *@This(), count: usize) void {
        self.read = self.read[count..];
    }

    pub fn parseHeader(self: *@This()) !ParseResults {
        var file = try std.fs.cwd().openFile(self.opts.inputFile.?, .{});
        defer file.close();

        self.buffer = try file.reader().readAllAlloc(self.getAllocator(), 1 * 1024 * 1024 * 1024);
        self.read = self.buffer;

        while (self.read.len > 0) {
            try self.next();
        }

        return .{};
    }

    pub fn destroy(self: *@This()) void {
        self.arena.deinit();
        self.backingAllocator.destroy(self);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const opts = try ProgramOptions.parseArgs(allocator);
    defer opts.deinit();

    std.log.info("inputFile={?s}, outputFile={?s}", .{
        opts.inputFile,
        opts.outputFile,
    });

    const parser = try ParserContext.create(allocator, &opts);
    defer parser.destroy();

    const parseResults = try parser.parseHeader();
    _ = parseResults; // part of parser arenas, gets oblitereated when parser gets destroyed
}
