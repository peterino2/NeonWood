pub const PhysicsCharacter = struct {
    entity: core.Entity = undefined,

    // character: *zphysics.CharacterVirtual = undefined,
    character: *zphysics.Character = undefined,

    pub fn initECS(self: *@This(), handle: core.SetHandle) void {
        self.entity = core.Entity.fromHandle(handle);

        if (self.entity.get(PhysicsCollider) != null) {
            @panic("adding a physics character to an entity already controlled by PhysicsCollider. I'm not going to support this");
        }

        if (self.entity.get(core.Scene) == null) {
            @panic("a scene component needs to be created in order to add a physics collider");
        }
    }

    pub fn setupCharacter(self: *@This(), shapeName: core.Name) !void {
        var n = shapeName;
        const system = physics.gPhysicsRuntime;
        const interface = system.system.getBodyInterfaceMut();
        const shape = system.shapes.get(n.handle()).?;

        const scene = self.entity.get(core.Scene).?;
        const p = scene.getPosition();

        var settings = try zphysics.CharacterSettings.create();
        defer settings.release();
        // base o
        // up: [4]f32 align(16), // 4th element is ignored
        // supporting_volume: [4]f32 align(16), // JPH::Plane - 4th element is used
        // max_slope_angle: f32,
        // shape: *Shape, // must provide valid shape (such as the typical capsule)

        settings.base.shape = shape.shape;
        settings.layer = physics.ObjectLayers.moving;
        settings.mass = 70;
        settings.friction = 0.8;

        self.character = try zphysics.Character.create(settings, .{ p.x, p.y, p.z }, scene.getRotation().quat, 0, system.system);

        self.character.addToPhysicsSystem(.{});

        _ = interface;
    }

    pub fn update(self: *@This(), dt: f64) void {
        _ = dt;
        // self.character.update(@floatCast(dt), .{ 0, -1.0, 0 }, .{});

        const scene = self.entity.get(core.Scene).?;
        const p = self.character.getPosition();
        const position = .{ .x = p[0], .y = p[1], .z = p[2] };
        // core.debugSphere(position, 20, .{});
        scene.setPosition(position);
    }

    pub fn setVelocity(self: *@This(), v: core.Vectorf) void {
        self.character.setLinearVelocity(.{ v.x, v.y, v.z });
    }

    pub fn getPosition(self: *@This()) core.Vectorf {
        const p = self.character.getPosition();
        const position: core.Vectorf = .{ .x = p[0], .y = p[1], .z = p[2] };

        return position;
    }

    pub fn deinit(self: *@This()) void {
        self.character.removeFromPhysicsSystem(.{});
        self.character.destroy();
    }

    pub var BaseContainer: *core.SparseMap(PhysicsCharacter) = undefined;
    pub const ComponentName = "PhysicsCharacter";
    pub const ScriptExports: []const []const u8 = &.{};
};

const core = @import("core");
const zphysics = @import("zphysics");
const physicsSystem = @import("physicsSystem.zig");
const PhysicsCollider = physicsSystem.PhysicsCollider;
const physics = @import("physics.zig");
const BodyId = physics.BodyId;
const CharacterVirtualSettings = zphysics.CharacterVirtualSettings;
const CharacterVirtual = zphysics.CharacterVirtual;
