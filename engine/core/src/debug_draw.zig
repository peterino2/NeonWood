const core = @import("core.zig");

pub const DebugDrawParams = struct {
    color: core.Vectorf = .{ .x = 0, .y = 1.0, .z = 0 },
    duration: f32 = 0,
    rotation: core.Quat = .{ 0, 0, 0, 1 },
};

const DebugDrawInterface = struct {
    debugSphereFn: *const fn (core.Vectorf, f32, DebugDrawParams) void,
};

var gDebugDrawInterface: ?*DebugDrawInterface = null;

pub fn debugSphere(position: core.Vectorf, radius: f32, params: DebugDrawParams) void {
    if (gDebugDrawInterface) |i| {
        i.debugSphereFn(position, radius, params);
    }
}
