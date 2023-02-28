const std = @import("std");
const core = @import("../core.zig");

pub fn game_log(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[GAME     ]: " ++ fmt ++ "\n", args);
}

pub fn game_logs(comptime fmt: []const u8) void {
    std.debug.print("[GAME     ]: " ++ fmt ++ "\n", .{});
}

pub fn ui_log(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[UI       ]: " ++ fmt ++ "\n", args);
}

pub fn ui_logs(comptime fmt: []const u8) void {
    std.debug.print("[UI       ]: " ++ fmt ++ "\n", .{});
}

pub fn engine_log(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[ENGINE   ]: " ++ fmt ++ "\n", args);
}

pub fn engine_logs(comptime fmt: []const u8) void {
    std.debug.print("[ENGINE   ]: " ++ fmt ++ "\n", .{});
}

pub fn engine_err(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[ENGINE   ]: ERROR!! " ++ fmt ++ "\n", args);
}

pub fn engine_errs(comptime fmt: []const u8) void {
    std.debug.print("[ENGINE   ]: ERROR!! " ++ fmt ++ "\n", .{});
}

pub fn test_log(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[TEST     ]: " ++ fmt ++ "\n", args);
}

pub fn test_logs(comptime fmt: []const u8) void {
    std.debug.print("[TEST     ]: " ++ fmt ++ "\n", .{});
}

pub fn test_setup() void {
    std.debug.print("\n", .{});
}

pub fn graphics_log(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[GRAPHICS ]: " ++ fmt ++ "\n", args);
}

pub fn graphics_logs(comptime fmt: []const u8) void {
    std.debug.print("[GRAPHICS ]: " ++ fmt ++ "\n", .{});
}

pub const FileLog = struct {
    buffer: std.ArrayList(u8),
    allocator: std.mem.Allocator,
    fileName: []u8,

    pub fn init(allocator: std.mem.Allocator, fileName: []const u8) !@This() {
        return .{
            .buffer = std.ArrayList(u8).init(allocator),
            .allocator = allocator,
            .fileName = try core.dupeString(allocator, fileName),
        };
    }

    pub fn write(self: *@This(), comptime fmt: []const u8, args: anytype) !void {
        var writer = self.buffer.writer();
        try writer.print(fmt, args);
    }

    pub fn writeOut(self: @This()) !void {
        const cwd = std.fs.cwd();
        var ofile = try std.fmt.allocPrint(self.allocator, "Saved/{s}", .{self.fileName});
        defer self.allocator.free(ofile);
        try cwd.makePath("Saved");
        try cwd.writeFile(ofile, self.buffer.items);
    }
};
