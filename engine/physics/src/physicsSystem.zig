const std = @import("std");
const zphysics = @import("zphysics");
const core = @import("core");
const zm = core.zm;

const ObjectLayers = struct {
    const non_moving: zphysics.ObjectLayer = 0;
    const moving: zphysics.ObjectLayer = 1;
    const len: u32 = 2;
};

const BroadPhaseLayers = struct {
    const non_moving: zphysics.BroadPhaseLayer = 0;
    const moving: zphysics.BroadPhaseLayer = 1;
    const len: u32 = 2;
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
    ovbplf: ObjectVsBroadPhaseLayerFilter,
    olpf: ObjectLayerPairFilter,
    max_bodies: u32,

    system: *zphysics.PhysicsSystem = undefined,

    boxSettings: *zphysics.BoxShapeSettings = undefined,
    boxShape: *zphysics.Shape = undefined,

    sphereSettings: *zphysics.SphereShapeSettings = undefined,
    sphereShape: *zphysics.Shape = undefined,

    floorShapeSettings: *zphysics.BoxShapeSettings = undefined,
    floorShape: *zphysics.Shape = undefined,

    spherePositions: std.ArrayList(core.Vectorf),
    sphereIds: std.ArrayList(zphysics.BodyId),

    newBallTime: f64 = 5,
    offset: f32 = 0,

    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .allocator = allocator,
            .bpli = BroadPhaseLayerInterface.init(),
            .ovbplf = .{},
            .olpf = .{},
            .spherePositions = std.ArrayList(core.Vectorf).init(allocator),
            .sphereIds = std.ArrayList(zphysics.BodyId).init(allocator),
            .max_bodies = 4096,
        };

        const system = try zphysics.PhysicsSystem.create(
            @as(*const zphysics.BroadPhaseLayerInterface, @ptrCast(&self.bpli)),
            @as(*const zphysics.ObjectVsBroadPhaseLayerFilter, @ptrCast(&self.ovbplf)),
            @as(*const zphysics.ObjectLayerPairFilter, @ptrCast(&self.olpf)),
            .{
                .max_bodies = self.max_bodies,
                .num_body_mutexes = 0,
                .max_body_pairs = 8192,
                .max_contact_constraints = 8192,
            },
        );

        self.system = system;

        const bodyInterface = self.system.getBodyInterfaceMut();

        // setup primitives for settings.
        self.boxSettings = try zphysics.BoxShapeSettings.create(.{ 0.5, 0.5, 0.5 });
        self.boxShape = try self.boxSettings.createShape();

        self.sphereSettings = try zphysics.SphereShapeSettings.create(0.5);
        self.sphereShape = try self.sphereSettings.createShape();

        self.floorShapeSettings = try zphysics.BoxShapeSettings.create(.{ 300, 1, 300 });
        self.floorShape = try self.floorShapeSettings.createShape();

        // create floor
        _ = try bodyInterface.createAndAddBody(.{
            .position = .{ 0, -1, 0, 1 },
            .rotation = .{ 0, 0, 0, 1 },
            .shape = self.floorShape,
            .motion_type = .static,
            .object_layer = ObjectLayers.non_moving,
        }, .activate);

        const roomSize = 7;
        // create up and down walls
        {
            const rotation = zm.quatFromMat(zm.rotationZ(core.radians(90.0)));
            _ = try bodyInterface.createAndAddBody(.{
                .position = .{ roomSize, -1, 0, 1 },
                .rotation = rotation,
                .shape = self.floorShape,
                .motion_type = .static,
                .object_layer = ObjectLayers.non_moving,
            }, .activate);

            _ = try bodyInterface.createAndAddBody(.{
                .position = .{ -roomSize, -1, 0, 1 },
                .rotation = rotation,
                .shape = self.floorShape,
                .motion_type = .static,
                .object_layer = ObjectLayers.non_moving,
            }, .activate);
        }

        // create left and right walls
        {
            const rotation = zm.quatFromMat(zm.rotationX(core.radians(90.0)));
            _ = try bodyInterface.createAndAddBody(.{
                .position = .{ 0, -1, -roomSize, 1 },
                .rotation = rotation,
                .shape = self.floorShape,
                .motion_type = .static,
                .object_layer = ObjectLayers.non_moving,
            }, .activate);

            _ = try bodyInterface.createAndAddBody(.{
                .position = .{ 0, -1, roomSize, 1 },
                .rotation = rotation,
                .shape = self.floorShape,
                .motion_type = .static,
                .object_layer = ObjectLayers.non_moving,
            }, .activate);
        }

        for (0..240) |i| {
            _ = try bodyInterface.createAndAddBody(
                .{
                    .position = .{ 0, @as(f32, @floatFromInt(i)) * 0.1 + 1.0, 2, 1 },
                    .rotation = .{ 0, 0, 0, 1 },
                    .shape = self.sphereShape,
                    .motion_type = .dynamic,
                    .object_layer = ObjectLayers.moving,
                    .angular_velocity = .{ 0, 0, 0, 0 },
                },
                .activate,
            );
            _ = try bodyInterface.createAndAddBody(
                .{
                    .position = .{ 5, @as(f32, @floatFromInt(i)) * 0.1 + 1.0, 2, 1 },
                    .rotation = .{ 0, 0, 0, 1 },
                    .shape = self.sphereShape,
                    .motion_type = .dynamic,
                    .object_layer = ObjectLayers.moving,
                    .angular_velocity = .{ 0, 0, 0, 0 },
                },
                .activate,
            );
        }

        self.system.optimizeBroadPhase();

        return self;
    }

    pub fn updateSpherePositions(self: *@This()) !void {
        try self.system.getBodyIds(&self.sphereIds);
        try self.spherePositions.resize(self.sphereIds.items.len);
        const lockInterface = self.system.getBodyLockInterface();

        for (self.sphereIds.items, 0..) |bodyId, i| {
            var readLock: zphysics.BodyLockRead = .{};
            readLock.lock(lockInterface, bodyId);
            defer readLock.unlock();

            if (readLock.body) |body| {
                self.spherePositions.items[i] = core.Vectorf.fromArray(body.position);
            }
        }
    }

    pub fn tick(self: *@This(), dt: f64) void {
        self.system.update(1.0 / @as(f32, @floatFromInt(60)), .{}) catch unreachable;
        self.updateSpherePositions() catch unreachable;

        self.newBallTime -= dt;

        if (self.newBallTime < 0) {
            const bodyInterface = self.system.getBodyInterfaceMut();
            self.newBallTime = 5.0;
            self.offset += 0.01;

            _ = bodyInterface.createAndAddBody(
                .{
                    .position = .{ 0 + self.offset, 15, 0, 1 },
                    .rotation = .{ 0, 0, 0, 1 },
                    .shape = self.sphereShape,
                    .motion_type = .dynamic,
                    .object_layer = ObjectLayers.moving,
                    .angular_velocity = .{ 0, 0, 0, 0 },
                    .inertia_multiplier = 30,
                },
                .activate,
            ) catch unreachable;

            self.system.optimizeBroadPhase();
        }
    }

    pub fn deinit(self: *@This()) void {
        const allocator = self.allocator;

        self.sphereShape.release();
        self.sphereSettings.release();

        self.floorShape.release();
        self.floorShapeSettings.release();

        self.boxShape.release();
        self.boxSettings.release();

        self.system.destroy();
        self.sphereIds.deinit();
        self.spherePositions.deinit();
        allocator.destroy(self);
    }
};
