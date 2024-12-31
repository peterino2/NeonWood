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
    }

    self.cameraPhysicsBody = try physics.addPrimitiveBody(.box, .{
        .motion_type = .kinematic,
        .object_layer = physics.ObjectLayers.moving,
    }, .activate);

    physics.optimizeBroadPhase();
}

pub fn unpreparePhysics(self: *GameContext) void {
    _ = self;
}

fn swapToPhysics(_: ui.NodeHandle, _: ui.PressedType, context: ?*anyopaque) ui.HandlerError!void {
    if (context) |c| {
        const self: *GameContext = @alignCast(@ptrCast(c));
        if (self.obj.get(graphics.StaticMesh)) |mesh| {
            mesh.visibility = !mesh.visibility;
        }
    }
}

pub fn tick(self: *GameContext, deltaTime: f64) void {
    _ = deltaTime;

    const physicsRuntime = physics.gPhysicsRuntime;

    physics.setBodyPosition(self.cameraPhysicsBody, self.camera.position);

    for (physicsRuntime.spherePositions.items, 0..) |position, i| {
        const id = physicsRuntime.sphereIds.items[i];
        if (id == self.cameraPhysicsBody) {
            continue;
        }
        const rotation = physicsRuntime.sphereRotations.items[i];
        var mesh = self.spheres[i].get(graphics.StaticMesh).?;
        mesh.visibility = true;
        mesh.position = position;
        mesh.scale = .{ .x = 0.5, .y = 0.5, .z = 0.5 };
        mesh.rotation = rotation;
        mesh.applyScalars();
    }
}
