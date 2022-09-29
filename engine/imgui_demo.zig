const std = @import("std");
pub const neonwood = @import("modules/neonwood.zig");
const game = @import("projects/neurophobia/game.zig");

const core = neonwood.core;
const graphics = neonwood.graphics;
const engine_log = core.engine_log;
const c = graphics.c;

var gGame: *GameContext = undefined;

// Primarily a test file that exists to create a simple application for
// basic engine onboarding
const GameContext = struct {
    const Self = @This();
    pub const NeonObjectTable = core.RttiData.from(Self);
    pub const InterfaceUiTable = core.InterfaceUiData.from(Self);

    allocator: std.mem.Allocator,
    showDemo: bool = true,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
            .showDemo = false,
        };

        core.game_logs("Game starting");

        return self;
    }

    pub fn uiTick(self: *Self, deltaTime: f64) void {
        _ = self;
        _ = deltaTime;
        c.igShowDemoWindow(&self.showDemo);
    }

    pub fn prepare_game(self: *Self) !void {
        try graphics.getContext().add_ui_object(.{
            .ptr = self,
            .vtable = &InterfaceUiTable,
        });
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }
};

pub fn main() anyerror!void {
    graphics.setWindowName("NeonWood: imgui demo");
    engine_log("Starting up", .{});
    core.start_module();
    defer core.shutdown_module();
    graphics.start_module();
    defer graphics.shutdown_module();

    var gameContext = try core.createObject(GameContext, .{ .can_tick = false });
    try gameContext.prepare_game();

    // run the game
    core.gEngine.run();
}
