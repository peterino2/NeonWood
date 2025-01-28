const std = @import("std");
const zphysics = @import("zphysics");
const core = @import("core");
const zm = core.zm;

const physicsCollider = @import("physicsCollider.zig");
pub const PhysicsCollider = physicsCollider.PhysicsCollider;

const physicsCharacter = @import("physicsCharacter.zig");
pub const PhysicsCharacter = physicsCharacter.PhysicsCharacter;

pub const ObjectLayers = struct {
    pub const non_moving: zphysics.ObjectLayer = 0;
    pub const moving: zphysics.ObjectLayer = 1;
    pub const len: u32 = 2;
};

pub const BroadPhaseLayers = struct {
    pub const non_moving: zphysics.BroadPhaseLayer = 0;
    pub const moving: zphysics.BroadPhaseLayer = 1;
    pub const len: u32 = 2;
};

const BroadPhaseLayerInterface = extern struct {
    usingnamespace zphysics.BroadPhaseLayerInterface.Methods(@This());
    __v: *const zphysics.BroadPhaseLayerInterface.VTable = &vtable,

    object_to_broad_phase: [ObjectLayers.len]zphysics.BroadPhaseLayer = undefined,

    const vtable = zphysics.BroadPhaseLayerInterface.VTable{
        .getNumBroadPhaseLayers = _getNumBroadPhaseLayers,
        .getBroadPhaseLayer = _getBroadPhaseLayer,
    };

    fn init() BroadPhaseLayerInterface {
        var layer_interface: BroadPhaseLayerInterface = .{};
        layer_interface.object_to_broad_phase[ObjectLayers.non_moving] = BroadPhaseLayers.non_moving;
        layer_interface.object_to_broad_phase[ObjectLayers.moving] = BroadPhaseLayers.moving;
        return layer_interface;
    }

    fn _getNumBroadPhaseLayers(_: *const zphysics.BroadPhaseLayerInterface) callconv(.C) u32 {
        return BroadPhaseLayers.len;
    }

    fn _getBroadPhaseLayer(
        interface_self: *const zphysics.BroadPhaseLayerInterface,
        object_layer: zphysics.ObjectLayer,
    ) callconv(.C) zphysics.BroadPhaseLayer {
        const self: *const BroadPhaseLayerInterface = @ptrCast(interface_self);
        return self.object_to_broad_phase[object_layer];
    }
};

const ObjectVsBroadPhaseLayerFilter = extern struct {
    usingnamespace zphysics.ObjectVsBroadPhaseLayerFilter.Methods(@This());
    __v: *const zphysics.ObjectVsBroadPhaseLayerFilter.VTable = &vtable,

    const vtable = zphysics.ObjectVsBroadPhaseLayerFilter.VTable{ .shouldCollide = _shouldCollide };

    fn _shouldCollide(
        _: *const zphysics.ObjectVsBroadPhaseLayerFilter,
        object_layer: zphysics.ObjectLayer,
        broad_phase_layer: zphysics.BroadPhaseLayer,
    ) callconv(.C) bool {
        return switch (object_layer) {
            ObjectLayers.non_moving => broad_phase_layer == BroadPhaseLayers.moving,
            ObjectLayers.moving => true,
            else => unreachable,
        };
    }
};

const ObjectLayerPairFilter = extern struct {
    usingnamespace zphysics.ObjectLayerPairFilter.Methods(@This());
    __v: *const zphysics.ObjectLayerPairFilter.VTable = &vtable,

    const vtable = zphysics.ObjectLayerPairFilter.VTable{ .shouldCollide = _shouldCollide };

    fn _shouldCollide(
        _: *const zphysics.ObjectLayerPairFilter,
        a: zphysics.ObjectLayer,
        b: zphysics.ObjectLayer,
    ) callconv(.C) bool {
        return switch (a) {
            ObjectLayers.non_moving => b == ObjectLayers.moving,
            ObjectLayers.moving => true,
            else => unreachable,
        };
    }
};

pub const PhysicsRuntime = struct {
    allocator: std.mem.Allocator,

    bpli: BroadPhaseLayerInterface,
    ovbplf: ObjectVsBroadPhaseLayerFilter = .{},
    olpf: ObjectLayerPairFilter = .{},
    max_bodies: u32 = 8192,

    system: *zphysics.PhysicsSystem = undefined,

    shapes: std.AutoHashMapUnmanaged(u32, ShapeRef) = .{},

    updatePeriod: f64 = 1.0 / 60.0,
    timeSinceUpdate: f64 = 0.0,
    idToEntity: std.AutoHashMapUnmanaged(zphysics.BodyId, core.Entity) = .{},

    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    pub fn registerBodyEntity(self: *@This(), bodyId: zphysics.BodyId, entity: core.Entity) !void {
        try self.idToEntity.put(self.allocator, bodyId, entity);
    }

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .allocator = allocator,
            .bpli = BroadPhaseLayerInterface.init(),
        };

        const system = try zphysics.PhysicsSystem.create(
            @as(*const zphysics.BroadPhaseLayerInterface, @ptrCast(&self.bpli)),
            @as(*const zphysics.ObjectVsBroadPhaseLayerFilter, @ptrCast(&self.ovbplf)),
            @as(*const zphysics.ObjectLayerPairFilter, @ptrCast(&self.olpf)),
            .{
                .max_bodies = self.max_bodies,
                .max_body_pairs = self.max_bodies * 2,
                .max_contact_constraints = self.max_bodies * 2,
                .num_body_mutexes = 0,
            },
        );

        self.system = system;

        try core.defineComponent(PhysicsCharacter, self.allocator);
        try core.defineComponent(PhysicsCollider, self.allocator);

        return self;
    }

    pub fn tick(self: *@This(), dt: f64) void {
        // self.timeSinceUpdate += dt;

        // while (self.timeSinceUpdate > self.updatePeriod) {
        //     self.timeSinceUpdate -= self.updatePeriod;
        //     self.system.update(@floatCast(self.updatePeriod), .{}) catch unreachable;
        // }
        self.system.update(@floatCast(dt), .{}) catch unreachable;

        // todo.. interpolation kinda easy here.
        self.updateScenes(dt);
    }

    fn updateScenes(self: *@This(), dt: f64) void {
        const lockInterface = self.system.getBodyLockInterface();

        // update character controllers

        for (PhysicsCharacter.BaseContainer.list.items) |physChar| {
            physChar.update(dt);
        }

        // update physics colliders
        for (PhysicsCollider.BaseContainer.list.items) |collider| {
            if (collider.mobile == false) {
                continue;
            }

            if (collider.bodyId) |bodyId| {
                var readLock: zphysics.BodyLockRead = .{};
                readLock.lock(lockInterface, bodyId);
                defer readLock.unlock();

                if (readLock.body) |body| {
                    const scene = collider.entity.get(core.Scene).?;
                    scene.setPosition(core.Vectorf.fromArray(body.position));
                    scene.setRotation(.{ .quat = body.rotation });
                }
            }
        }
    }

    pub fn deinit(self: *@This()) void {
        const allocator = self.allocator;

        for (PhysicsCharacter.BaseContainer.list.items) |physChar| {
            physChar.deinit();
        }
        self.idToEntity.deinit(self.allocator);
        core.undefineComponent(PhysicsCharacter);
        core.undefineComponent(PhysicsCollider);
        self.shapes.deinit(self.allocator);
        self.system.destroy();
        allocator.destroy(self);
    }

    pub fn createShape(self: *@This(), name: *core.Name, settings: ShapeSettings) !void {
        const ref: ShapeRef = .{
            .settings = settings,
            .shape = try settings.createShape(),
        };
        try self.shapes.put(self.allocator, name.handle(), ref);
    }
};

pub const ShapeSettings = union(enum(u8)) {
    convex: *zphysics.ConvexShapeSettings,
    box: *zphysics.BoxShapeSettings,
    sphere: *zphysics.SphereShapeSettings,
    triangle: *zphysics.TriangleShapeSettings,
    capsule: *zphysics.CapsuleShapeSettings,
    taperedCapsule: *zphysics.TaperedCapsuleShapeSettings,
    cylinder: *zphysics.CylinderShapeSettings,
    convexHull: *zphysics.ConvexHullShapeSettings,
    heightField: *zphysics.HeightFieldShapeSettings,
    mesh: *zphysics.MeshShapeSettings,
    decorated: *zphysics.DecoratedShapeSettings,
    compound: *zphysics.CompoundShapeSettings,

    pub fn release(self: @This()) void {
        switch (self) {
            .convex => |x| {
                x.release();
            },
            .box => |x| {
                x.release();
            },
            .sphere => |x| {
                x.release();
            },
            .triangle => |x| {
                x.release();
            },
            .capsule => |x| {
                x.release();
            },
            .taperedCapsule => |x| {
                x.release();
            },
            .cylinder => |x| {
                x.release();
            },
            .convexHull => |x| {
                x.release();
            },
            .heightField => |x| {
                x.release();
            },
            .mesh => |x| {
                x.release();
            },
            .decorated => |x| {
                x.release();
            },
            .compound => |x| {
                x.release();
            },
        }
    }

    pub fn createShape(self: @This()) !*zphysics.Shape {
        switch (self) {
            .convex => |x| {
                return try x.createShape();
            },
            .box => |x| {
                return try x.createShape();
            },
            .sphere => |x| {
                return try x.createShape();
            },
            .triangle => |x| {
                return try x.createShape();
            },
            .capsule => |x| {
                return try x.createShape();
            },
            .taperedCapsule => |x| {
                return try x.createShape();
            },
            .cylinder => |x| {
                return try x.createShape();
            },
            .convexHull => |x| {
                return try x.createShape();
            },
            .heightField => |x| {
                return try x.createShape();
            },
            .mesh => |x| {
                return try x.createShape();
            },
            .decorated => |x| {
                return try x.createShape();
            },
            .compound => |x| {
                return try x.createShape();
            },
        }
    }
};

pub const ShapeRef = struct {
    settings: ShapeSettings = undefined,
    shape: *zphysics.Shape = undefined,
};
