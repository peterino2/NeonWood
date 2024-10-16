const std = @import("std");

const neonwood = @import("NeonWood");
const core = neonwood.core;
const ecs = core.ecs;
const MemoryTracker = core.MemoryTracker;

const sample = @import("components/sample.zig");
const SampleComponent = sample.SampleComponent;
const SampleSystem = sample.SampleSystem;

const script = core.script;

pub const GameContext = struct {
    allocator: std.mem.Allocator,

    entity: core.Entity = undefined,
    entity2: core.Entity = undefined,

    ticksBeforeExit: i32 = 5,

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
        };
        return self;
    }

    pub fn prepare_game(self: *@This()) !void {
        try core.defineComponent(SampleComponent, self.allocator);
        defer core.undefineComponent(SampleComponent);
        try core.fs().addContentPath("headless");
        try script.runScriptFile("scripts/sample.lua");
    }

    pub fn prepare_game2(self: *@This()) !void {
        core.defineComponent(SampleComponent, self.allocator) catch unreachable;
        core.engine_log("SampleComponentBaseContainer @{x}", .{@intFromPtr(SampleComponent.BaseContainer)});

        _ = try ecs.createSystem(SampleSystem, self.allocator);

        self.entity = core.createEntity() catch unreachable;
        _ = self.entity.addComponent(SampleComponent);

        self.entity2 = core.createEntity() catch unreachable;
        const component = self.entity2.addComponent(SampleComponent);
        component.name = "lmao2nova";

        MemoryTracker.PrintStatsWithTag("prepare game end:");

        core.undefineComponent(SampleComponent); // todo remove
        core.exitNow();
    }

    pub fn tick(self: *@This(), _: f64) void {
        self.ticksBeforeExit -= 1;
        if (self.ticksBeforeExit < 0) {
            core.exitNow();
        }
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
