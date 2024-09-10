const std = @import("std");
const core = @import("core.zig");

const ArrayListUnmanaged = std.ArrayListUnmanaged;
const tracy = core.tracy;

pub const Transform = core.Mat;

pub const SceneAttachMode = enum {
    none, // default, parent attachment is irrelevant and not used
    relativePositionOnly, // only position is relative to parent transform
    relativeRotationOnly, // only rotation is relative to parent transform
    relative, // position and rotation are relative to parent transform
    snapToParentPositionOnly, // snaps to the parent's position, maintaining independent rotation (not implemented)
    snapToParentRotationOnly, // copys the parent's rotation, maintaining independent rotation (not implemented)
    snapToParent, // snaps to parent rotation and position
};

pub const SceneMobilityMode = enum {
    static, // scene is updated once and never again
    moveable, // sceneobject is moveable and has it's final transform updated
};

pub const SceneObjectPosRot = struct {
    position: core.Vectorf = .{ .x = 0, .y = 0, .z = 0 },
    rotation: core.Rotation = core.Rotation.init(),
    scale: core.Vectorf = core.Vectorf.new(1.0, 1.0, 1.0),
};

pub const SceneObjectSettings = struct {
    attachmentMode: SceneAttachMode = .none,
    sceneMode: SceneMobilityMode = .static,
};

pub const SceneObjectRepr = struct {
    // fields intended to be internally used, don't touch them
    // unless you know what you're doing
    transform: core.Mat = core.zm.identity(),
    parent: ?core.ObjectHandle = null,
    attachmentMode: SceneAttachMode = .relative,
};

pub const SceneObject = struct {
    _repr: SceneObjectRepr, // not public
    posRot: SceneObjectPosRot, // position and rotation
    settings: SceneObjectSettings, //
    children: ArrayListUnmanaged(core.ObjectHandle),

    // --- these.. are all useless lmao
    pub fn getPosition(self: @This()) core.Vectorf {
        return self.posRot.position;
    }

    pub fn getRotation(self: @This()) core.Rotation {
        return self.posRot.rotation;
    }

    pub fn getParent(self: @This()) ?core.ObjectHandle {
        return self._repr.parent;
    }

    // may be out of date by a frame or two unless you call Update() specifically
    pub fn getTransform(self: @This()) core.Transform {
        return self._repr.transform;
    }

    pub fn update(self: *@This()) void {
        self._repr.transform = core.zm.mul(
            core.zm.translationV(self.getPosition().toZm()),
            core.zm.matFromQuat(self.getRotation().quat),
        );
    }
    // ----

    pub fn init(params: SceneObjectInitParams) @This() {
        // Hmm thinking in the future we could have scene objects be f64s then crunch them down to f32s when we are submiting to gpu
        var self = @This(){
            .posRot = .{},
            ._repr = .{},
            .settings = .{},
            .children = .{},
        };

        const shouldUpdate: bool = false; // should mutate

        switch (params) {
            .transform => {
                self._repr.transform = params.transform;
                self.posRot.position = core.Vectorf.fromZm(core.zm.mul(params.transform, core.Vectorf.zero().toZm()));
                self.posRot.rotation = .{ .quat = core.zm.matToQuat(params.transform) };
            },
            .position => {},
            .rotation => {},
            .positionRotAngles => {},
            .positionRot => {},
        }

        if (shouldUpdate) {
            self.update();
        }

        return self;
    }
};

pub const SceneObjectInitParams = union(enum) {
    transform: core.Transform,
    position: core.Vectorf,
    rotation: core.Quat,
    positionRotAngles: struct {
        position: core.Vectorf = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        angles: core.Vectorf = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
    },
    positionRot: struct {
        position: core.Vectorf = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        angles: core.Quat = core.zm.qidentity(),
    },
};

const SceneSet = core.SparseMultiSet(SceneObject);

pub const SceneSystem = struct {
    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    allocator: std.mem.Allocator,
    objects: SceneSet,
    dynamicObjects: ArrayListUnmanaged(core.ObjectHandle) = .{},

    pub const Field = SceneSet.Field;
    pub const FieldType = SceneSet.FieldType;

    // ----- creating and updating objects -----

    // scene objects are the primary object type
    pub fn createSceneObject(self: *@This(), params: SceneObjectInitParams) !core.ObjectHandle {
        const newHandle = try self.objects.createObject(SceneObject.init(params));
        return newHandle;
    }

    pub fn createSceneObjectWithHandle(
        self: *@This(),
        objectHandle: core.ObjectHandle,
        params: SceneObjectInitParams,
    ) !core.ObjectHandle {
        const newHandle = try self.objects.createWithHandle(objectHandle, SceneObject.init(params));
        return newHandle;
    }

    pub fn setPosition(self: *@This(), handle: core.ObjectHandle, position: core.Vectorf) void {
        self.objects.get(handle, .posRot).?.*.position = position;
    }

    pub fn setRotation(self: *@This(), handle: core.ObjectHandle, rotation: core.Rotation) void {
        self.objects.get(handle, .posRot).?.*.rotation = rotation;
    }

    pub fn setScale(self: *@This(), handle: core.ObjectHandle, x: f32, y: f32, z: f32) void {
        self.objects.get(handle, .posRot).?.*.scale = .{ .x = x, .y = y, .z = z };
    }

    pub fn setScaleV(self: *@This(), handle: core.ObjectHandle, scale: core.Vectorf) void {
        self.objects.get(handle, .posRot).?.*.scale = scale;
    }

    pub fn getPosition(self: *@This(), handle: core.ObjectHandle) core.Vectorf {
        return self.objects.get(handle, .posRot).?.position;
    }

    pub fn getRotation(self: *@This(), handle: core.ObjectHandle) core.Rotation {
        return self.objects.get(handle, .posRot).?.rotation;
    }

    pub fn getParent(self: *@This(), handle: core.ObjectHandle) ?core.ObjectHandle {
        return self.objects.get(handle, ._repr).?.parent;
    }

    pub fn getTransform(self: *@This(), handle: core.ObjectHandle) core.Transform {
        return self.objects.get(handle, ._repr).?.transform;
    }

    // ----- subsystem update procedures

    // internal update transform function
    fn updateTransform(self: *@This(), repr: *SceneObjectRepr, posRot: SceneObjectPosRot) void {
        _ = self;

        repr.*.transform = core.zm.mul(
            core.zm.mul(
                core.zm.scalingV(posRot.scale.toZm()),
                core.zm.matFromQuat(posRot.rotation.quat),
            ),
            core.zm.translationV(posRot.position.toZm()),
        );
    }

    pub fn updateTransforms(self: *@This()) void {
        for (self.objects.denseItems(._repr), 0..) |*repr, i| {
            const settings = self.objects.readDense(i, .settings);
            if (settings.sceneMode == .moveable) {
                const posRot = self.objects.readDense(i, .posRot);
                self.updateTransform(repr, posRot.*);
            }
        }
    }

    // ----- NeonObject interace ----
    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
            .objects = SceneSet.init(allocator),
        };
        return self;
    }

    pub fn setMobility(self: *@This(), objectHandle: core.ObjectHandle, mobility: SceneMobilityMode) !void {
        const settings = self.objects.get(objectHandle, .settings).?;
        if (mobility == .moveable) {
            if (settings.sceneMode == .static) {
                try self.dynamicObjects.append(self.allocator, objectHandle);
            }
        }

        if (mobility == .static) {
            if (settings.sceneMode == .moveable) {
                core.engine_errs("TODO: Changing sceneMode from moveable back to static is not supported yet.");
                unreachable;
            }
        }

        settings.*.sceneMode = mobility;
    }

    pub fn get(self: *@This(), handle: core.ObjectHandle, comptime field: Field) ?*FieldType(field) {
        return self.objects.get(handle, field);
    }

    pub fn tick(self: *@This(), deltaTime: f64) void {
        _ = self;
        var z = tracy.ZoneNC(@src(), "Scene System Tick", 0xAABBDD);
        defer z.End();
        _ = deltaTime;
    }

    pub fn deinit(self: *@This()) void {
        self.objects.deinit();
        self.allocator.destroy(self);
    }
};

// LUA_BEGIN

// because scene objects are a special sparse-multiset type,
// they do not have a fixed representation in the sparse set.
// as a result this type requires a special implementation to operate properly.

pub const Scene = struct {
    denseIndex: u32,

    pub var BaseContainer: *core.SparseMap(@This()) = undefined;

    pub fn setPosition(self: @This()) void {
        _ = self;
    }

    pub fn setRotation(self: @This()) void {
        _ = self;
    }

    pub fn setParent(self: @This()) void {
        _ = self;
    }
};

// LUA_END
