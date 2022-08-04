const std = @import("std");

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
