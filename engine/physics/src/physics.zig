const std = @import("std");

pub const zphysics = @import("zphysics");
pub const core = @import("core");

pub const PhysicsCollider = @import("physicsCollider.zig").PhysicsCollider;
pub const PhysicsCharacter = @import("physicsCharacter.zig").PhysicsCharacter;

pub const ConvexShapeSettings = zphysics.ConvexShapeSettings;
pub const BoxShapeSettings = zphysics.BoxShapeSettings;
pub const SphereShapeSettings = zphysics.SphereShapeSettings;
pub const TriangleShapeSettings = zphysics.TriangleShapeSettings;
pub const CapsuleShapeSettings = zphysics.CapsuleShapeSettings;
pub const TaperedCapsuleShapeSettings = zphysics.TaperedCapsuleShapeSettings;
pub const CylinderShapeSettings = zphysics.CylinderShapeSettings;
pub const ConvexHullShapeSettings = zphysics.ConvexHullShapeSettings;
pub const HeightFieldShapeSettings = zphysics.HeightFieldShapeSettings;
pub const MeshShapeSettings = zphysics.MeshShapeSettings;
pub const DecoratedShapeSettings = zphysics.DecoratedShapeSettings;
pub const CompoundShapeSettings = zphysics.CompoundShapeSettings;

pub const BodyId = zphysics.BodyId;

pub const ShapeSettings = runtime.ShapeSettings;

pub const BodyCreationSettings = zphysics.BodyCreationSettings;
pub const Activation = zphysics.Activation;

pub const ObjectLayers = runtime.ObjectLayers;

const runtime = @import("physicsSystem.zig");
pub const IgnoreFixedBodiesFilter = runtime.IgnoreFixedBodiesFilter;

pub const PrimitiveType = enum {
    box,
    sphere,
};

// low level helpers - old api
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

pub fn setBodyRotation(id: BodyId, rot: core.Rotation) void {
    const interface = gPhysicsRuntime.system.getBodyInterfaceMut();
    interface.setRotation(id, rot.quat, .activate);
}

pub fn optimizeBroadPhase() void {
    gPhysicsRuntime.system.optimizeBroadPhase();
}

pub var gPhysicsRuntime: *runtime.PhysicsRuntime = undefined;

pub fn addShape(name: []const u8, settings: ShapeSettings) !void {
    var n = core.MakeName(name);
    try gPhysicsRuntime.createShape(&n, settings);
}

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

pub fn releaseShape(name: core.Name) void {
    var n = name;
    gPhysicsRuntime.shapes.get(n.handle()).?.shape.release();
}

pub const RayCastSettings = struct {
    entityLookup: bool = false,
    bodyFilter: ?*const anyopaque = null,
};

pub const RayCastResult = struct {
    body: BodyId,
    point: core.Vectorf,
    entity: ?core.Entity = null,
};

pub fn traceLine(start: core.Vectorf, direction: core.Vectorf, settings: RayCastSettings) ?RayCastResult {
    const query = gPhysicsRuntime.system.getNarrowPhaseQuery();
    const result = query.castRay(.{
        .origin = start.toZm(),
        .direction = direction.toZm(),
    }, .{
        .body_filter = @ptrCast(@alignCast(settings.bodyFilter)),
    });

    if (!result.has_hit) {
        return null;
    }

    var rv: RayCastResult = .{
        .body = result.hit.body_id,
        .point = direction.fmul(result.hit.fraction).add(start),
    };

    if (settings.entityLookup) {
        rv.entity = gPhysicsRuntime.idToEntity.get(rv.body).?;
    }

    return rv;
}

pub fn applyForce(body: BodyId, impulse: core.Vectorf, position: core.Vectorf) void {
    const interface = gPhysicsRuntime.system.getBodyInterfaceMut();
    interface.addImpulseAtPosition(body, impulse.toArr3(), position.toArr3());
}
