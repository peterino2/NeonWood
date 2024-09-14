const std = @import("std");

pub const zphysics = @import("zphysics");
pub const core = @import("core");

pub const Module: core.ModuleDescription = .{
    .name = "physics",
    .enabledByDefault = false,
};

pub fn start_module(comptime programSpec: anytype, args: anytype, allocator: std.mem.Allocator) !void {
    _ = args;
    _ = programSpec;
    _ = allocator;
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    _ = allocator;
}
