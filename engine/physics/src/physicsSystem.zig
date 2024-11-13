const std = @import("std");
const zphysics = @import("zphysics");

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

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
            .bpli = BroadPhaseLayerInterface.init(),
            .ovbplf = .{},
            .olpf = .{},
            .max_bodies = 128,
        };

        const system = try zphysics.PhysicsSystem.create(
            @as(*const zphysics.BroadPhaseLayerInterface, @ptrCast(&self.bpli)),
            @as(*const zphysics.ObjectVsBroadPhaseLayerFilter, @ptrCast(&self.ovbplf)),
            @as(*const zphysics.ObjectLayerPairFilter, @ptrCast(&self.olpf)),
            .{
                .max_bodies = self.max_bodies,
                .num_body_mutexes = 0,
                .max_body_pairs = 1024,
                .max_contact_constraints = 1024,
            },
        );

        self.system = system;
        return self;
    }

    pub fn destroy(self: *@This()) void {
        const allocator = self.allocator;
        self.system.destroy();
        allocator.destroy(self);
    }
};
