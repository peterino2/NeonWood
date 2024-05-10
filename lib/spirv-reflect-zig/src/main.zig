// Copyright (c) peterino2@github.com

const std = @import("std");
const ReflectedJsonInfo = @import("ReflectedJsonInfo.zig");

const ProgramOptions = struct {
    outputFile: []u8,
    verbose: bool = false,
    sourceFile: ?[]u8 = null,
    errorMsg: ?[]u8 = null,
    embedFile: ?[]u8 = null,

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.outputFile);
        if (self.sourceFile) |src| {
            allocator.free(src);
        }

        if (self.errorMsg) |msg| {
            allocator.free(msg);
        }

        if (self.embedFile) |embedFile| {
            allocator.free(embedFile);
        }
    }
};

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

fn dupe(allocator: std.mem.Allocator, str: []const u8) ![]u8 {
    return try std.fmt.allocPrint(allocator, "{s}", .{str});
}

fn parseArgs(allocator: std.mem.Allocator) !ProgramOptions {
    const ParseState = enum {
        zero,
        default,
        output,
        embed,
    };

    var state: ParseState = .zero;

    var opts: ProgramOptions = .{
        .outputFile = try dupe(allocator, "reflected_spirv.zig"),
    };
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    for (args) |arg| {
        switch (state) {
            .zero => {
                state = .default;
            },
            .default => {
                if (arg[0] == '-') {
                    if (matchArgOpt(arg, "embed", "e"))
                        state = .embed;
                    if (matchArgOpt(arg, "output", "o"))
                        state = .output;
                    if (matchArgOpt(arg, "verbose", "v"))
                        opts.verbose = true;
                } else {
                    if (opts.sourceFile) |src| {
                        allocator.free(src);
                        opts.sourceFile = null;
                        opts.errorMsg = try dupe(allocator, "Too many source files, this is not supported");
                        return opts;
                    }
                    opts.sourceFile = try dupe(allocator, arg);
                }
            },
            .output => {
                allocator.free(opts.outputFile);
                opts.outputFile = try dupe(allocator, arg);
                state = .default;
            },
            .embed => {
                if (opts.embedFile != null)
                    allocator.free(opts.embedFile.?);
                opts.embedFile = try dupe(allocator, arg);
                state = .default;
            },
        }
    }

    return opts;
}

fn usage() void {
    std.debug.print("usage: spirv-reflect <input file> [-o or --output] <output file>\n", .{});
    std.debug.print("the input file is the json file which is the result from running spirv-cross --reflect\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const opts = try parseArgs(allocator);
    defer opts.deinit(allocator);
    if (opts.errorMsg) |msg| {
        std.debug.print("{s}\n", .{msg});
        return;
    }

    if (opts.sourceFile == null) {
        std.debug.print("Missing Source file. \n", .{});
        usage();
        return;
    }

    if (opts.verbose)
        std.debug.print("parsing: {s} >> {s}\n", .{ opts.sourceFile.?, opts.outputFile });

    var reflectedJson = try ReflectedJsonInfo.reflect(
        allocator,
        opts.sourceFile.?,
        .{
            .verbose = opts.verbose,
            .embedFile = opts.embedFile,
        },
    );
    defer reflectedJson.deinit();

    const rendered = try reflectedJson.render(allocator);
    defer allocator.free(rendered);
    try std.fs.cwd().writeFile(opts.outputFile, rendered);
}
