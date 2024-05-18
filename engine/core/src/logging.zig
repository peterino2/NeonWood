const std = @import("std");
const core = @import("core.zig");
const tracy = @import("tracy");
const build_opts = core.build_options;

const builtin = @import("builtin");

var gLoggerSys: ?*LoggerSys = null;

pub fn printInner(comptime fmt: []const u8, args: anytype) void {
    if (build_opts.zero_logging) {
        return;
    }

    if (build_opts.slow_logging) {
        std.debug.print("> " ++ fmt, args);
    } else {
        if (gLoggerSys) |loggerSys| {
            loggerSys.print(fmt, args) catch std.debug.print("!> " ++ fmt, args);
        } else {
            std.debug.print("> " ++ fmt, args);
        }
    }
}

pub fn game_log(comptime fmt: []const u8, args: anytype) void {
    printInner("[GAME     ]: " ++ fmt ++ "\n", args);
}

pub fn game_logs(comptime fmt: []const u8) void {
    printInner("[GAME     ]: " ++ fmt ++ "\n", .{});
}

pub fn ui_log(comptime fmt: []const u8, args: anytype) void {
    printInner("[UI       ]: " ++ fmt ++ "\n", args);
}

pub fn ui_logs(comptime fmt: []const u8) void {
    printInner("[UI       ]: " ++ fmt ++ "\n", .{});
}

pub fn engine_log(comptime fmt: []const u8, args: anytype) void {
    printInner("[ENGINE   ]: " ++ fmt ++ "\n", args);
}

pub fn engine_logs(comptime fmt: []const u8) void {
    printInner("[ENGINE   ]: " ++ fmt ++ "\n", .{});
}

pub fn engine_err(comptime fmt: []const u8, args: anytype) void {
    printInner("[ENGINE   ]: ERROR!! " ++ fmt ++ "\n", args);
}

pub fn engine_errs(comptime fmt: []const u8) void {
    printInner("[ENGINE   ]: ERROR!! " ++ fmt ++ "\n", .{});
}

pub fn test_log(comptime fmt: []const u8, args: anytype) void {
    printInner("[TEST     ]: " ++ fmt ++ "\n", args);
}

pub fn test_logs(comptime fmt: []const u8) void {
    printInner("[TEST     ]: " ++ fmt ++ "\n", .{});
}

pub fn graphics_log(comptime fmt: []const u8, args: anytype) void {
    printInner("[GRAPHICS ]: " ++ fmt ++ "\n", args);
}

pub fn graphics_logs(comptime fmt: []const u8) void {
    printInner("[GRAPHICS ]: " ++ fmt ++ "\n", .{});
}

pub const FileLog = struct {
    buffer: std.ArrayList(u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !@This() {
        const self = @This(){
            .buffer = std.ArrayList(u8).init(allocator),
            .allocator = allocator,
        };

        return self;
    }

    pub fn write(self: *@This(), comptime fmt: []const u8, args: anytype) !void {
        var writer = self.buffer.writer();
        try writer.print(fmt, args);
    }

    pub fn writeGraphvizHeader(self: *@This()) !void {
        try self.write("digraph G {{", .{});
    }

    pub fn writeOutGraphViz(self: *@This(), fileName: []const u8) !void {
        const obuf = try std.fmt.allocPrint(
            self.allocator,
            "{s}{s}",
            .{ self.buffer.items, "}}\n" },
        );
        defer self.free(obuf);

        const cwd = std.fs.cwd();
        const ofile = try std.fmt.allocPrint(self.allocator, "Saved/{s}", .{fileName});
        defer self.allocator.free(ofile);

        try cwd.makePath("Saved");
        try cwd.writeFile(ofile, obuf);
    }

    pub fn writeOut(self: @This(), fileName: []const u8) !void {
        const cwd = std.fs.cwd();
        const ofile = try std.fmt.allocPrint(self.allocator, "Saved/{s}", .{fileName});
        defer self.allocator.free(ofile);
        try cwd.makePath("Saved");
        try cwd.writeFile(ofile, self.buffer.items);
    }

    pub fn deinit(self: *@This()) void {
        self.buffer.deinit();
    }
};

pub const LoggerSys = struct {
    pub var NeonObjectTable: core.RttiData = core.RttiData.from(@This());

    writeOutBuffer: std.ArrayList(u8),
    flushBuffer: std.ArrayList(u8),
    allocator: std.mem.Allocator,
    logFilePath: []const u8,
    logFile: std.fs.File,
    consoleFile: std.fs.File,
    lock: std.Thread.Mutex = .{},
    flushing: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    pub fn flush(self: *@This()) !void {
        var z = tracy.ZoneN(@src(), "Trying to flush");
        defer z.End();

        self.lock.lock();

        if (!self.flushing.load(.acquire)) {
            self.flushing.store(true, .seq_cst);
            const swap = self.writeOutBuffer;
            self.writeOutBuffer = self.flushBuffer;
            self.flushBuffer = swap;

            std.debug.print("flushing\n", .{});
            const L = struct {
                loggerSys: *LoggerSys,

                pub fn func(ctx: @This(), _: *core.JobContext) void {
                    var z1 = tracy.ZoneN(@src(), "flushing output buffer");
                    defer z1.End();
                    ctx.loggerSys.flushFromJob() catch unreachable;
                    ctx.loggerSys.flushing.store(false, .seq_cst);
                }
            };

            try core.dispatchJob(L{ .loggerSys = self });
        } else {
            //self.flushWriteBuffer();
        }

        self.lock.unlock();
    }

    pub fn shutdownFlush(self: *@This()) !void {
        while (self.flushing.load(.seq_cst)) {}

        // try self.logFile.writer().writeAll(self.writeOutBuffer.items);
        // try self.consoleFile.writer().writeAll(self.writeOutBuffer.items);
    }

    pub fn flushWriteBuffer(self: *@This()) !void {
        self.lock.lock();
        try self.logFile.writer().writeAll(self.writeOutBuffer.items);
        if (builtin.is_test) {
            std.debug.print("{s}", .{self.flushBuffer.items});
        } else {
            try self.consoleFile.writer().writeAll(self.writeOutBuffer.items);
        }
        self.writeOutBuffer.clearRetainingCapacity();
        self.lock.unlock();
    }

    pub fn flushFromJob(self: *@This()) !void {
        self.lock.lock();
        try self.logFile.writer().writeAll(self.flushBuffer.items);
        if (builtin.is_test) {
            std.debug.print("{s}", .{self.flushBuffer.items});
        } else {
            try self.consoleFile.writer().writeAll(self.flushBuffer.items);
        }
        self.flushBuffer.clearRetainingCapacity();
        self.lock.unlock();
    }

    pub fn print(self: *@This(), comptime fmt: []const u8, args: anytype) !void {
        self.lock.lock();
        try self.writeOutBuffer.writer().print(fmt, args);
        self.lock.unlock();

        if (self.writeOutBuffer.items.len > 8192) {
            if (self.flushBuffer.items.len == 0) {
                try self.flush();
            } else {
                try self.flushWriteBuffer();
            }
        }
    }

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const cwd = std.fs.cwd();
        const ofile = std.fmt.allocPrint(allocator, "Saved/{s}", .{"Session_Log.txt"}) catch unreachable;
        cwd.makePath("Saved") catch unreachable;

        const self = try allocator.create(@This());
        self.* = @This(){
            .allocator = allocator,
            .writeOutBuffer = std.ArrayList(u8).initCapacity(allocator, 8192 * 4) catch unreachable,
            .flushBuffer = std.ArrayList(u8).initCapacity(allocator, 8192 * 4) catch unreachable,
            .logFilePath = ofile,
            .logFile = cwd.createFile(ofile, .{}) catch unreachable,
            .consoleFile = std.io.getStdOut(),
        };

        return self;
    }

    pub fn deinit(self: *@This()) void {
        self.flushWriteBuffer() catch {};
        self.allocator.free(self.logFilePath);
        self.logFile.close();

        self.writeOutBuffer.deinit();
        self.flushBuffer.deinit();

        self.allocator.destroy(self);
    }

    pub fn processEvents(self: *@This(), frameNumber: u64) core.EngineDataEventError!void {
        _ = frameNumber;
        if (self.writeOutBuffer.items.len == 0) {
            return;
        }

        self.flush() catch return error.UnknownStatePanic;
    }
};

var gFlushForcing: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

pub fn forceFlush() void {
    if (gFlushForcing.load(.seq_cst)) {
        return;
    }
    gFlushForcing.store(true, .seq_cst);
    if (gLoggerSys != null) {
        gLoggerSys.?.flushWriteBuffer() catch {};
    }
}

pub fn setupLogging(engine: *core.Engine) !void {
    gLoggerSys = try engine.createObject(LoggerSys, .{
        .responds_to_events = true,
    });
}

pub fn shutdownLogging() void {
    gLoggerSys = null;
}
