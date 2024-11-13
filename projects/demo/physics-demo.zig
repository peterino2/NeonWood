const std = @import("std");
const neonwood = @import("NeonWood");
const main = @import("main.zig");
const physics = neonwood.physics;
const GameContext = main.GameContext;
const ui = neonwood.ui;

const zphys = physics.zphysics;

pub fn preparePhysics(self: *GameContext) !void {
    const ctx = ui.getContext();
    const panel = ui.getContext().getPanel(self.panel);
    panel.layoutMode = .Vertical;
    const button = try ctx.addButton(self.panel, "switch to physics demo");
    try ctx.events.installOnPressedEvent(button, .onPressed, .Mouse1, self, &enableTimeline);

    {
        const btn = ctx.get(button);
        btn.setSize(.{ .x = 120, .y = 50 });
    }
}

pub fn unpreparePhysics(self: *GameContext) void {
    _ = self;
}

fn enableTimeline(_: ui.NodeHandle, _: ui.PressedType, context: ?*anyopaque) ui.HandlerError!void {
    if (context) |c| {
        const self: *GameContext = @alignCast(@ptrCast(c));
        var obj = self.gc.renderObjectSet.get(self.objHandle, .renderObject).?;
        obj.visibility = false;
    }
}

pub fn tick(self: *GameContext, deltaTime: f64) void {
    _ = self;
    _ = deltaTime;
}
