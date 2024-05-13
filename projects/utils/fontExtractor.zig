const std = @import("std");
const papyrus = @import("../../modules/ui/papyrus/papyrus.zig");

const logger = std.log.scoped(.main);

// a little utility to extract fonts from ttf files and create both
// a png file and a json file with corresponding font vertex coordinates.
//
const ProgramOptions = struct {
    outputFile: []u8,
    verbose: bool = false,
    sourceFile: ?[]u8 = null,
    errorMsg: ?[]u8 = null,

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.outputFile);
        if (self.sourceFile) |src| {
            allocator.free(src);
        }

        if (self.errorMsg) |msg| {
            allocator.free(msg);
        }
    }
};

fn dupe(allocator: std.mem.Allocator, str: []const u8) ![]u8 {
    return try std.fmt.allocPrint(allocator, "{s}", .{str});
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

fn parseArgs(allocator: std.mem.Allocator) !ProgramOptions {
    const ParseState = enum {
        zero,
        default,
        output,
    };

    var state: ParseState = .zero;

    var opts: ProgramOptions = .{
        .outputFile = try dupe(allocator, "bitmap_font"),
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
        }
    }

    return opts;
}

pub fn usage() void {}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const opts = try parseArgs(allocator);
    defer opts.deinit(allocator);

    logger.info("\n", .{});
    logger.info("fontExtractor: extract bitmaps and texture coordinates into bmps and json files", .{});
    if (opts.errorMsg) |msg| {
        logger.err("error message detected in font extractor: {s}", .{msg});
    }
}
