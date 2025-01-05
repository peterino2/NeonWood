const std = @import("std");
const core = @import("core.zig");

const ArrayListUnmanaged = std.ArrayListUnmanaged;
const tracy = core.tracy;

pub const Transform = core.Mat;
const SceneObjectSet = core.SparseMultiSet(SceneObject);
const SceneSet = core.SparseSet(Scene);

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

    pub inline fn toTransform(self: @This()) core.Transform {
        var transform = core.zm.mul(
            core.zm.scalingV(self.scale.toZm()),
            core.zm.matFromQuat(self.rotation.quat),
        );

        transform = core.zm.mul(
            transform,
            core.zm.translationV(self.position.toZm()),
        );

        return transform;
    }
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
    attachmentMode: SceneAttachMode = .relative, // doesn't do anything yet, only support relative right now
    transformOverride: ?*core.Transform = null,
    lastUpdate: u32 = 0,
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
    handle: core.ObjectHandle = .{ .generation = 0, .index = 0, .alive = false },

    pub var BaseContainer: *SceneSet = undefined;
    pub var SceneObjectContainer: *SceneObjectSet = undefined;
    pub const ComponentName = "Scene";

    pub const ScriptExports: []const []const u8 = &.{
        "setPosition",
        "setRotation",
        "setScale",
        "setScaleV",
        "getPosition",
        "getRotation",
        "getParent",
        "printHandleIndex",
        // "getTransform", not implemented yet
        // "setMobility", gonna need special setup for this one
    };

    pub fn initECS(self: *@This(), handle: core.ObjectHandle) void {
        self.handle = handle;
        _ = SceneObjectContainer.createWithHandleECS(handle);
    }

    pub fn printHandleIndex(self: @This()) void {
        core.engine_log("handle.index = 0x{x} generation = {d} alive={any}", .{ self.handle.index, self.handle.generation, self.handle.alive });
    }

    pub fn setPosition(self: @This(), position: core.Vectorf) void {
        if (SceneObjectContainer.get(self.handle, .posRot)) |posRot| {
            posRot.*.position = position;
            // core.engine_log("setposition scucess handle.index = 0x{x}", .{self.handle.index});
        } else {
            core.engine_log("setposition failed handle.index = 0x{x} generation = {d} alive={any}", .{ self.handle.index, self.handle.generation, self.handle.alive });
        }
    }

    pub fn getPosRot(self: *@This()) *SceneObjectPosRot {
        return SceneObjectContainer.get(self.handle, .posRot).?;
    }

    pub fn setRotation(self: @This(), rotation: core.Rotation) void {
        SceneObjectContainer.get(self.handle, .posRot).?.*.rotation = rotation;
    }

    pub fn setScale(self: @This(), x: f32, y: f32, z: f32) void {
        SceneObjectContainer.get(self.handle, .posRot).?.*.scale = .{ .x = x, .y = y, .z = z };
    }

    pub fn setScaleV(self: @This(), scale: core.Vectorf) void {
        SceneObjectContainer.get(self.handle, .posRot).?.*.scale = scale;
    }

    pub fn getPosition(self: @This()) core.Vectorf {
        // core.engine_logs("getPosition called");
        return SceneObjectContainer.get(self.handle, .posRot).?.position;
    }

    pub fn getRotation(self: @This()) core.Rotation {
        return SceneObjectContainer.get(self.handle, .posRot).?.rotation;
    }

    pub fn getScaleV(self: @This()) core.Vectorf {
        return SceneObjectContainer.get(self.handle, .posRot).?.scale;
    }

    pub fn getParent(self: @This()) core.Entity {
        return core.Entity{ .handle = SceneObjectContainer.get(self.handle, ._repr).?.parent orelse .{} };
    }

    pub fn setParent(self: @This(), newParent: core.Entity) void {
        core.engine_log("parenting entity {d} -> {d}", .{ self.handle.index, newParent.handle.index });
        const repr: *SceneObjectRepr = SceneObjectContainer.get(self.handle, ._repr).?;
        const thisParent = repr.parent;
        if (thisParent) |p| {
            const parentRef = @This(){ .handle = p };
            parentRef.removeChild(self.handle);
        }

        repr.parent = newParent.handle;

        const children = SceneObjectContainer.get(newParent.handle, .children).?;
        children.append(childAllocator(), newParent.handle) catch unreachable;
    }

    pub fn clearParent(self: @This()) void {
        const repr = SceneObjectContainer.get(self.handle, ._repr).?;
        const thisParent = &repr.parent;
        if (thisParent) |p| {
            const parentRef = @This(){ .handle = p };
            parentRef.removeChild(self.handle);
        }

        repr.parent = null;
    }

    pub fn removeChild(self: @This(), child: core.ObjectHandle) void {
        const children = SceneObjectContainer.get(self.handle, .children).?;
        for (children.items, 0..) |search, i| {
            if (child.eql(search)) {
                _ = children.swapRemove(i);
                break;
            }
        }
    }

    pub fn getTransform(self: @This()) core.Transform {
        return SceneObjectContainer.get(self.handle, ._repr).?.transform;
    }

    // you MUST clearTransfomRefUnsafe() before destroying this transform
    pub fn setTransformRefUnsafe(self: @This(), ref: *core.Transform) void {
        SceneObjectContainer.get(self.handle, ._repr).?.transformOverride = ref;
    }

    pub fn clearTransformRefUnsafe(self: @This(), ref: *core.Transform) void {
        SceneObjectContainer.get(self.handle, ._repr).?.transformOverride = ref;
    }

    pub fn setMobility(self: @This(), mobility: SceneMobilityMode) void {
        const settings = Scene.SceneObjectContainer.get(self.handle, .settings).?;
        if (settings.sceneMode == .static) {
            if (mobility == .moveable) {
                core.gScene.dynamicObjects.append(core.gScene.allocator, self.handle) catch unreachable;
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

pub var gSceneSystem: *SceneSystem = undefined;

fn childAllocator() std.mem.Allocator {
    return gSceneSystem.childrenArena.allocator();
}

pub const SceneSystem = struct {
    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    allocator: std.mem.Allocator,
    dynamicObjects: ArrayListUnmanaged(core.ObjectHandle) = .{},
    childrenArena: std.heap.ArenaAllocator,
    tickCount: u32 = 0,

    pub const Field = SceneObjectSet.Field;
    pub const FieldType = SceneObjectSet.FieldType;

    // internal update transform function
    fn updateTransform(self: *@This(), repr: *SceneObjectRepr, posRot: *const SceneObjectPosRot) void {
        if (repr.lastUpdate == self.tickCount) {
            return;
        }

        if (repr.transformOverride) |override| {
            repr.lastUpdate = self.tickCount;
            repr.transform = override.*;
            return;
        }

        var final: core.Transform = core.zm.identity();

        if (repr.parent) |parent| {
            if (Scene.SceneObjectContainer.get(parent, ._repr)) |parentRepr| {
                const parentPosRot = Scene.SceneObjectContainer.get(parent, .posRot).?;
                self.updateTransform(parentRepr, parentPosRot);
                const parentTransform = parentRepr.transform;
                final = core.zm.mul(parentTransform, final);
            } else {}
        }

        // core.engine_log("final\n{d} {d} {d} {d}\n{d} {d} {d} {d}", .{
        //     final[0][0],
        //     final[0][1],
        //     final[0][2],
        //     final[0][3],
        //     final[1][0],
        //     final[1][1],
        //     final[1][2],
        //     final[1][3],
        // });
        repr.transform = core.zm.mul(
            core.zm.mul(
                core.zm.mul(
                    core.zm.scalingV(posRot.scale.toZm()),
                    core.zm.matFromQuat(posRot.rotation.quat),
                ),
                core.zm.translationV(posRot.position.toZm()),
            ),
            final,
        );

        // core.engine_log("final\n{d} {d} {d} {d}\n{d} {d} {d} {d}", .{
        //     repr.transform[0][0],
        //     repr.transform[0][1],
        //     repr.transform[0][2],
        //     repr.transform[0][3],
        //     repr.transform[1][0],
        //     repr.transform[1][1],
        //     repr.transform[1][2],
        //     repr.transform[1][3],
        // });

        repr.lastUpdate = self.tickCount;
    }

    pub fn updateTransforms(self: *@This()) void {
        self.tickCount +%= 1;
        if (self.tickCount == 0) {
            self.tickCount += 1;
        }
        // todo. calculate a running load factor for the number of movable objects
        // vs static objects
        // if we have a small amount of movable vs static AND if we have > 1000 objects,
        // then iterate over dynamicObjects array instead
        for (Scene.SceneObjectContainer.denseItems(._repr), 0..) |*repr, i| {
            const settings = Scene.SceneObjectContainer.readDense(i, .settings);
            if (settings.sceneMode == .moveable or repr.lastUpdate == 0) {
                const posRot = Scene.SceneObjectContainer.readDense(i, .posRot);
                self.updateTransform(repr, posRot);
            }
        }
    }

    // ----- NeonObject interace ----
    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
            .childrenArena = std.heap.ArenaAllocator.init(allocator),
        };
        gSceneSystem = self;
        try core.defineComponent(Scene, allocator);
        Scene.SceneObjectContainer = try SceneObjectSet.create(allocator);
        return self;
    }

    pub fn tick(self: *@This(), deltaTime: f64) void {
        var z = tracy.ZoneNC(@src(), "Scene System Tick", 0xAABBDD);
        defer z.End();
        self.updateTransforms();
        _ = deltaTime;
    }

    pub fn deinit(self: *@This()) void {
        self.dynamicObjects.deinit(self.allocator);
        self.childrenArena.deinit();
        core.undefineComponent(Scene);
        Scene.SceneObjectContainer.destroy();
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
// man... that shit sounds like so much work...

// LUA_END
