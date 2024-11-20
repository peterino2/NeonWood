const std = @import("std");
const neonwood = @import("NeonWood");
const main = @import("main.zig");
const physics = neonwood.physics;
const GameContext = main.GameContext;
const ui = neonwood.ui;
const core = neonwood.core;
const graphics = neonwood.graphics;

const zphys = physics.zphysics;

pub fn preparePhysics(self: *GameContext) !void {
    const ctx = ui.getContext();
    const panel = ui.getContext().getPanel(self.panel);
    panel.layoutMode = .Vertical;
    const button = try ctx.addButton(self.panel, "switch to physics demo");
    try ctx.events.installOnPressedEvent(button, .onPressed, .Mouse1, self, &swapToPhysics);

    {
        const btn = ctx.get(button);
        btn.setSize(.{ .x = 120, .y = 50 });
        var obj = self.gc.renderObjectSet.get(self.objHandle, .renderObject).?;
        obj.visibility = !obj.visibility;
    }
}

pub fn unpreparePhysics(self: *GameContext) void {
    _ = self;
}

fn swapToPhysics(_: ui.NodeHandle, _: ui.PressedType, context: ?*anyopaque) ui.HandlerError!void {
    if (context) |c| {
        const self: *GameContext = @alignCast(@ptrCast(c));
        var obj = self.gc.renderObjectSet.get(self.objHandle, .renderObject).?;
        obj.visibility = !obj.visibility;
    }
}

var lolaBunny = core.MakeName("t_lolaBunny");

pub fn tick(self: *GameContext, deltaTime: f64) void {
    _ = deltaTime;

    const physicsRuntime = physics.gPhysicsRuntime;

    for (physicsRuntime.spherePositions.items, 0..) |position, i| {
        // graphics.debugSphere(position, 0.5, .{ .rotation = physicsRuntime.sphereRotations.items[i] });
        const rotation = physicsRuntime.sphereRotations.items[i];
        const handle = self.spheres[i];
        var obj = self.gc.renderObjectSet.get(handle, .renderObject).?;
        obj.visibility = true;
        obj.position = position;
        obj.scale = .{ .x = 0.5, .y = 0.5, .z = 0.5 };
        obj.rotation = rotation;
        obj.applyScalars();
    }
}
