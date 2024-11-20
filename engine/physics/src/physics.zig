const std = @import("std");

pub const zphysics = @import("zphysics");
pub const core = @import("core");

pub const BodyId = zphysics.BodyId;

pub const BodyCreationSettings = zphysics.BodyCreationSettings;
pub const Activation = zphysics.Activation;

pub const ObjectLayers = runtime.ObjectLayers;

const runtime = @import("physicsSystem.zig");

pub const PrimitiveType = enum {
    box,
    sphere,
};

pub fn addPrimitiveBody(primitive: PrimitiveType, settings: BodyCreationSettings, activationMode: Activation) !BodyId {
    const interface = gPhysicsRuntime.system.getBodyInterfaceMut();
    var s = settings;

    switch (primitive) {
        .box => {
            s.shape = gPhysicsRuntime.primBoxShape;
        },
        .sphere => {
            s.shape = gPhysicsRuntime.primSphereShape;
        },
    }

    return try interface.createAndAddBody(s, activationMode);
}

pub fn setBodyPosition(id: BodyId, pos: core.Vectorf) void {
    const interface = gPhysicsRuntime.system.getBodyInterfaceMut();
    interface.setPosition(id, pos.toArr3(), .activate);
}

pub fn optimizeBroadPhase() void {
    gPhysicsRuntime.system.optimizeBroadPhase();
}

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

pub const Module: core.ModuleDescription = .{
    .name = "physics",
    .enabledByDefault = false,
};
