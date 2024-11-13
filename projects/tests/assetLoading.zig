const std = @import("std");
pub const neonwood = @import("NeonWood");

const core = neonwood.core;
const graphics = neonwood.graphics;
const assets = neonwood.assets;
const engine_log = core.engine_log;
var gGame: *GameContext = undefined;

const testimage1 = "content/textures/lost_empire-RGBA.png";

// Asset loader
const AssetReferences = [_]assets.AssetImportReference{
    assets.MakeImportRef("Texture", "a0", testimage1),
    assets.MakeImportRef("Texture", "a1", testimage1),
    assets.MakeImportRef("Texture", "a2", testimage1),
    assets.MakeImportRef("Texture", "a3", testimage1),

    assets.MakeImportRef("Texture", "a4", testimage1),
    assets.MakeImportRef("Texture", "a5", testimage1),
    assets.MakeImportRef("Texture", "a6", testimage1),
    assets.MakeImportRef("Texture", "a7", testimage1),
};

// Primarily a test file that exists to create a simple application for
// basic engine onboarding
const GameContext = struct {
    const Self = @This();
    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(Self);
    pub const InterfaceUiTable = core.InterfaceUiData.from(Self);

    allocator: std.mem.Allocator,
    showDemo: bool = true,
    debugOpen: bool = true,

    pub fn init(allocator: std.mem.Allocator) Self {
        const self = Self{
            .allocator = allocator,
        };

        core.game_logs("Game starting");

        return self;
    }

    pub fn tick(self: *Self, deltaTime: f64) void {
        _ = self;
        _ = deltaTime;
    }

    pub fn prepare_game(self: *Self) !void {
        gGame = self;

        try assets.loadList(AssetReferences);
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }
};

pub fn main() anyerror!void {
    engine_log("Starting up", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{
        .stack_trace_frames = 20,
    }){};
    defer {
        core.printInner("shutting down gpa", .{});
        const cleanupStatus = gpa.deinit();
        if (cleanupStatus == .leak) {
            core.printInner("gpa cleanup leaked memory\n", .{});
        }
    }
    const allocator = gpa.allocator();

    try core.start_module(.{}, .{}, allocator);
    defer core.shutdown_module(allocator);
    try assets.start_module(.{}, .{}, allocator);
    defer assets.shutdown_module(allocator);

    try graphics.start_module(.{}, .{}, allocator);
    defer graphics.shutdown_module(allocator);

    var gameContext = try core.createObject(GameContext, .{ .can_tick = false });
    try gameContext.prepare_game();

    // run the game
    core.gEngine.run();
}

pub fn input_callback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = window;
    _ = scancode;
    _ = mods;

    if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS) {
        core.engine_logs("Escape key pressed, game ends now");
        core.gEngine.exit();
    }

    if (key == c.GLFW_KEY_SPACE and action == c.GLFW_PRESS) {
        gGame.showDemo = true;
    }
}
