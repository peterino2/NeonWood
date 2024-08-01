const std = @import("std");

const neonwood = @import("NeonWood");
const core = neonwood.core;

const SampleComponent = @import("SampleComponent.zig");

pub const GameContext = struct {
    allocator: std.mem.Allocator,

    entity: core.Entity = undefined,
    entity2: core.Entity = undefined,

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
        };
        core.defineComponent(SampleComponent, self.allocator) catch unreachable;

        self.entity = core.createEntity() catch unreachable;
        _ = self.entity.addComponent(SampleComponent, .{});

        self.entity2 = core.createEntity() catch unreachable;
        _ = self.entity2.addComponent(SampleComponent, .{ .name = "entity2" });

        core.undefineComponent(SampleComponent); // todo remove
        return self;
    }

    pub fn tick(_: *@This(), _: f64) void {
        core.exitNow();
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.destroy(self);
    }

    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());
};

pub fn main() anyerror!void {
    try neonwood.initializeAndRunStandardProgram(GameContext, .{
        .name = "imguiSample",
        .enabledModules = .{
            .platform = false,
            .graphics = false,
            .ui = false,
            .papyrus = false,
            .vkImgui = false,
        },
    });
}
