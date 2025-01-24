const std = @import("std");
const core = @import("core.zig");

pub const DebugDrawParams = struct {
    color: core.Vectorf = .{ .x = 0, .y = 1.0, .z = 0 },
    duration: f32 = 0,
    rotation: core.Quat = .{ 0, 0, 0, 1 },
};

const DebugDrawInterface = struct {
    debugSphereFn: *const fn (pos: core.Vectorf, radius: f32, DebugDrawParams) void,
    debugBoxFn: *const fn (pos: core.Vectorf, extents: core.Vectorf, DebugDrawParams) void,
    debugLineFn: *const fn (start: core.Vectorf, end: core.Vectorf, DebugDrawParams) void,
};

var gDebugDrawInterface: ?*DebugDrawInterface = null;
var gDebugDrawAllocator: ?std.mem.Allocator = null;

pub fn debugSphereTransform(t: core.Mat, radius: f32, params: DebugDrawParams) void {
    if (gDebugDrawInterface) |i| {
        i.debugSphereFn(core.Vectorf.fromZm(core.zm.mul(core.zm.Vec{ 0, 0, 0, 1 }, t)), radius, params);
    }
}

pub fn debugSphere(position: core.Vectorf, radius: f32, params: DebugDrawParams) void {
    if (gDebugDrawInterface) |i| {
        i.debugSphereFn(position, radius, params);
    }
}

pub fn debugLine(start: core.Vectorf, end: core.Vectorf, params: DebugDrawParams) void {
    if (gDebugDrawInterface) |i| {
        i.debugLineFn(start, end, params);
    }
}

pub fn debugBox(pos: core.Vectorf, extents: core.Vectorf, params: DebugDrawParams) void {
    if (gDebugDrawInterface) |i| {
        i.debugBoxFn(pos, extents, params);
    }
}

pub fn installDebugDrawInterface(allocator: std.mem.Allocator, newInterface: DebugDrawInterface) !void {
    gDebugDrawInterface = try allocator.create(DebugDrawInterface);
    gDebugDrawAllocator = allocator;

    if (gDebugDrawInterface) |interface| {
        interface.* = newInterface;
    }
}

pub fn shutdownDrawInterface() void {
    if (gDebugDrawInterface) |interface| {
        gDebugDrawAllocator.?.destroy(interface);
    }
}
