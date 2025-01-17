pub const PhysicsCollider = struct {
    entity: core.Entity = undefined,
    ready: bool = false,

    bodyId: ?BodyId = null,
    mobile: bool = false,

    pub fn initECS(self: *@This(), handle: core.SetHandle) void {
        self.entity = core.Entity.fromHandle(handle);

        if (self.entity.get(PhysicsCharacter) != null) {
            @panic("adding a physics character to an entity already controlled by physics character... not supported... i think");
        }

        if (self.entity.get(core.Scene) == null) {
            @panic("a scene component needs to be created in order to add a physics collider");
        }
    }

    pub fn setupShape(self: *@This(), name: []const u8) void {
        _ = self;
        _ = name;
    }

    pub fn setupByShapeName(self: *@This(), shapeName: core.Name, bodySettings: zphysics.BodyCreationSettings) !void {
        var n = shapeName;
        const system = physics.gPhysicsRuntime;
        const interface = system.system.getBodyInterfaceMut();
        const shape = system.shapes.get(n.handle()).?;
        var settings = bodySettings;

        settings.shape = shape.shape;

        const scene = self.entity.get(core.Scene).?;
        const p = scene.getPosition();
        core.engine_log("setting up collider shape {any}", .{p});
        settings.position = .{ p.x, p.y, p.z, 1.0 };
        settings.rotation = scene.getRotation().quat;

        if (scene.getParent().handle.alive) {
            // ... FUCK!! need to implement that..... for now just get get the parent's
            // location and ... yeah... we will need to transform these in
            // the future.
            // settings.position = (scene.getParent().get(core.Scene).?.getPosition().add(core.Vectorf.fromZm(settings.position))).toZm();
        }

        self.bodyId = try interface.createAndAddBody(settings, .activate);
        self.mobile = settings.motion_type == .dynamic;
    }

    pub fn applyScene(self: *@This()) void {
        const scene = self.entity.get(core.Scene).?;
        if (scene.getParent().handle.alive != false) {
            @panic("trying to apply scene but it has a parent. physics bodies do not support having parents... yet");
        }
        physics.setBodyPosition(self.bodyId, scene.getPosition());
        physics.setRotation(self.bodyId, scene.getRotation());
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
    }

    pub var BaseContainer: *core.SparseMap(PhysicsCollider) = undefined;
    pub const ComponentName = "PhysicsCollider";
    pub const ScriptExports: []const []const u8 = &.{};
};

const core = @import("core");
const zphysics = @import("zphysics");
const physicsSystem = @import("physicsSystem.zig");
const PhysicsCharacter = physicsSystem.PhysicsCharacter;
const physics = @import("physics.zig");
const BodyId = physics.BodyId;
