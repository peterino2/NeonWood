const std = @import("std");
const neonwood = @import("modules/neonwood.zig");
const core = neonwood.core;
const graphics = neonwood.graphics;
const engine_log = core.engine_log;

const Camera = graphics.render_objects.Camera;
const RenderObject = graphics.render_objects.RenderObject;

const GameTextureAsset = struct {
    name: []const u8,
    path: []const u8,
};

const textureAssets = [_]GameTextureAsset{
    .{ .name = "test_sprite", .path = "content/singleSpriteTest.png" },
    .{ .name = "test_sprite", .path = "content/singleSpriteTest.png" },
};

// primarily a test file that exists to create a simple application for
// basic engine onboarding
const GameContext = struct {
    const Self = @This();
    pub const NeonObjectTable = core.RttiData.from(Self);

    allocator: std.mem.Allocator,
    camera: graphics.Camera,
    gc: *graphics.NeonVkContext,

    isRotating: bool = false,
    shouldExit: bool = false,
    textureAssets: []GameTextureAsset,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
            .camera = Camera.init(),
            .gc = graphics.gContext,
        };

        self.init_resource_paths();

        return self;
    }

    pub fn prepare_game(self: *Self) void {
        var gc = self.gc;
        _ = gc;
    }

    pub fn tick(self: *Self) void {
        _ = self;
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }
};

pub fn main() anyerror!void {
    engine_log("Starting up", .{});
    core.start_module();
    defer core.shutdown_module();
    graphics.start_module();
    defer graphics.shutdown_module();

    // Setup the game
    //var gameContext = core.createObject(GameContext, .{ .can_tick = true });
    //gameContext.prepare_game();

    // run the game
    core.gEngine.run();
}
