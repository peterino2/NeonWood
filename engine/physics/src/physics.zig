const std = @import("std");

pub const zphysics = @import("zphysics");
pub const core = @import("core");

pub const Module: core.ModuleDescription = .{
    .name = "physics",
    .enabledByDefault = false,
};

pub fn start_module(allocator: std.mem.Allocator) !void {
    _ = allocator;
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    _ = allocator;
}
