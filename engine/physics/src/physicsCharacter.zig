pub const PhysicsCharacter = struct {
    entity: core.Entity = undefined,

    pub fn initECS(self: *@This(), handle: core.SetHandle) void {
        self.entity = core.Entity.fromHandle(handle);
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
    }

    pub var BaseContainer: *core.SparseMap(PhysicsCharacter) = undefined;
    pub const ComponentName = "PhysicsCharacter";
    pub const ScriptExports: []const []const u8 = &.{};
};

const core = @import("core");
const zphysics = @import("zphysics");
const physicsSystem = @import("physicsSystem.zig");
