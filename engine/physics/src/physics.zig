const std = @import("std");

pub const zphysics = @import("zphysics");
pub const core = @import("core");

const runtime = @import("physicsSystem.zig");

pub const Module: core.ModuleDescription = .{
    .name = "physics",
    .enabledByDefault = false,
};

pub var gPhysicsRuntime: *runtime.PhysicsRuntime = undefined;

pub fn start_module(comptime programSpec: anytype, args: anytype, allocator: std.mem.Allocator) !void {
    _ = args;
    _ = programSpec;
    try zphysics.init(allocator, .{});
    gPhysicsRuntime = try core.createObject(runtime.PhysicsRuntime, .{ .can_tick = true });
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    _ = allocator;
    zphysics.deinit();
}
