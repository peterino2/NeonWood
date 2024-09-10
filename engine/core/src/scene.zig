const std = @import("std");
const core = @import("core.zig");

const ArrayListUnmanaged = std.ArrayListUnmanaged;
const tracy = core.tracy;

pub const Transform = core.Mat;
const SceneSet = core.SparseMultiSet(SceneObject);

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
    _repr: SceneObjectRepr = .{}, // not public
    posRot: SceneObjectPosRot = .{}, // position and rotation
    settings: SceneObjectSettings = .{}, //
    children: ArrayListUnmanaged(core.ObjectHandle) = .{},

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
            .position => {
                @panic("todo: implement position only initialization");
            },
            .rotation => {
                @panic("todo: implement rotation only initialization");
            },
            .positionRotAngles => {
                @panic("todo: implement position + rotation initialization (angles) ");
            },
            .positionRot => {
                @panic("todo: implement position + rotation initialization");
            },
        }

        if (shouldUpdate) {
            self.update();
        }

        return self;
    }
};

pub const Scene = struct {
    handle: core.ObjectHandle,

    pub var BaseContainer: *SceneSet = undefined;
    pub const ComponentName = "Scene";

    pub const ScriptExports: []const []const u8 = &.{
        "setPosition",
        "setRotation",
        "setScale",
        "setScaleV",
        "getPosition",
        "getRotation",
        "getParent",
        // "getTransform", not implemented yet
        // "setMobility", gonna need special setup for this one
    };

    pub fn setPosition(self: @This(), position: core.Vectorf) void {
        // core.engine_log("setPositon called p=0x{p}", .{@as(*const anyopaque, @ptrCast(&self.handle))});
        BaseContainer.get(self.handle, .posRot).?.*.position = position;
    }

    pub fn setRotation(self: @This(), rotation: core.Rotation) void {
        BaseContainer.get(self.handle, .posRot).?.*.rotation = rotation;
    }

    pub fn setScale(self: @This(), x: f32, y: f32, z: f32) void {
        BaseContainer.get(self.handle, .posRot).?.*.scale = .{ .x = x, .y = y, .z = z };
    }

    pub fn setScaleV(self: @This(), scale: core.Vectorf) void {
        BaseContainer.get(self.handle, .posRot).?.*.scale = scale;
    }

    pub fn getPosition(self: @This()) core.Vectorf {
        // core.engine_logs("getPosition called");
        return BaseContainer.get(self.handle, .posRot).?.position;
    }

    pub fn getRotation(self: @This()) core.Rotation {
        return BaseContainer.get(self.handle, .posRot).?.rotation;
    }

    pub fn getParent(self: @This()) core.Entity {
        return core.Entity{ .handle = BaseContainer.get(self.handle, ._repr).?.parent orelse .{} };
    }

    pub fn getTransform(self: @This()) core.Transform {
        return BaseContainer.get(self.handle, ._repr).?.transform;
    }

    pub fn setMobility(self: @This(), mobility: SceneMobilityMode) !void {
        const settings = Scene.BaseContainer.get(self.handle, .settings).?;
        if (settings.sceneMode == .static) {
            if (mobility == .moveable) {
                try core.gScene.dynamicObjects.append(core.gScene.allocator, self.handle);
            }
        }

        if (settings.sceneMode == .moveable) {
            if (mobility == .static) {
                @panic("todo unable to change scene mobility back to static");
            }
        }

        settings.*.sceneMode = mobility;
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

pub const SceneSystem = struct {
    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    allocator: std.mem.Allocator,
    dynamicObjects: ArrayListUnmanaged(core.ObjectHandle) = .{},

    pub const Field = SceneSet.Field;
    pub const FieldType = SceneSet.FieldType;

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
        // todo. calculate a running load factor for the number of movable objects
        // vs static objects
        // if we have a small amount of movable vs static AND if we have > 1000 objects,
        // then iterate over dynamicObjects array instead
        for (Scene.BaseContainer.denseItems(._repr), 0..) |*repr, i| {
            const settings = Scene.BaseContainer.readDense(i, .settings);
            if (settings.sceneMode == .moveable) {
                const posRot = Scene.BaseContainer.readDense(i, .posRot);
                self.updateTransform(repr, posRot.*);
            }
        }
    }

    // ----- NeonObject interace ----
    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
        };
        try core.defineComponent(Scene, allocator);
        return self;
    }

    pub fn tick(self: *@This(), deltaTime: f64) void {
        var z = tracy.ZoneNC(@src(), "Scene System Tick", 0xAABBDD);
        defer z.End();
        self.updateTransforms();
        _ = deltaTime;
    }

    pub fn deinit(self: *@This()) void {
        core.undefineComponent(Scene);
        self.allocator.destroy(self);
    }
};

// LUA_BEGIN

// because scene objects are a special sparse-multiset type,
// they do not have a fixed representation in the sparse set.
// as a result this type requires a special implementation to operate properly.
// multi-set systems should only ever modify values via functions

// we really need a way to deal with multi-set handles.
// idea - in the component registration. if the container type is a sparse multiset
// then the pointer type shall be a pointer to the set handle.
// and the component acquisition shall do absolutely nothing but grab the sparse index of the set handle
//
// custom component registration i think should be created

// LUA_END
