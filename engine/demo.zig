const std = @import("std");
pub const neonwood = @import("modules/neonwood.zig");
//pub const neonwood = @import("neonwood");

const core = neonwood.core;
const graphics = neonwood.graphics;
const assets = neonwood.assets;
const engine_log = core.engine_log;
const c = graphics.c;
var gGame: *GameContext = undefined;

const testimage = "lost_empire-RGBA";
const testimage2 = "texture_sample";
//const testimage2 = "texture_sample";

// Asset loader
const AssetReferences = [_]assets.AssetRef{
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_210"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_211"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_212"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_213"), .path = "content/textures/" ++ testimage2 ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_310"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_311"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_312"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_313"), .path = "content/textures/" ++ testimage2 ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_411"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_412"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_413"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_414"), .path = "content/textures/" ++ testimage2 ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_510"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_511"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_512"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_513"), .path = "content/textures/" ++ testimage2 ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_210"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_211"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_212"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_213"), .path = "content/textures/" ++ testimage2 ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_310"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_311"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_312"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_313"), .path = "content/textures/" ++ testimage2 ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_411"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_412"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_413"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_414"), .path = "content/textures/" ++ testimage2 ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_510"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_511"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_512"), .path = "content/textures/" ++ testimage2 ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_513"), .path = "content/textures/" ++ testimage2 ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_2d0"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_2d1"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_2d2"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_2d3"), .path = "content/textures/" ++ testimage ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_3d0"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_3d1"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_3d2"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_3d3"), .path = "content/textures/" ++ testimage ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_4d1"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_4d2"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_4d3"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_4d4"), .path = "content/textures/" ++ testimage ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_5d0"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_5d1"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_5d2"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_5d3"), .path = "content/textures/" ++ testimage ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_2d0"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_2d1"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_2d2"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_2d3"), .path = "content/textures/" ++ testimage ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_3d0"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_3d1"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_3d2"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_3d3"), .path = "content/textures/" ++ testimage ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_4d1"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_4d2"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_4d3"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_4d4"), .path = "content/textures/" ++ testimage ++ ".png" },

    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_5d0"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_5d1"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_5d2"), .path = "content/textures/" ++ testimage ++ ".png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("a_5d3"), .path = "content/textures/" ++ testimage ++ ".png" },
};

// Primarily a test file that exists to create a simple application for
// basic engine onboarding
const GameContext = struct {
    const Self = @This();
    pub const NeonObjectTable = core.RttiData.from(Self);
    pub const InterfaceUiTable = core.InterfaceUiData.from(Self);

    allocator: std.mem.Allocator,
    showDemo: bool = true,
    debugOpen: bool = true,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
        };

        core.game_logs("Game starting");

        return self;
    }

    pub fn uiTick(self: *Self, deltaTime: f64) void {
        _ = deltaTime;

        if (self.showDemo) {
            c.igShowDemoWindow(&self.showDemo);
        }

        if (self.debugOpen) {
            if (!c.igBegin("Debug Menu", &(self.debugOpen), 0)) {
                c.igEnd();
            } else {
                c.igText("hello motherfucker");

                if (c.igButton("Press me!", .{ .x = 250.0, .y = 30.0 })) {
                    core.engine_logs("I have been pressed!");
                    self.debugOpen = false;
                }
                c.igEnd();
            }
        }

        _ = c.igBegin(
            "instructions",
            null,
            c.ImGuiWindowFlags_NoResize | c.ImGuiWindowFlags_NoCollapse | c.ImGuiWindowFlags_NoTitleBar,
        );
        c.igText("Press ESC to close\nPress SPACE to open the demo window");
        c.igEnd();
    }

    pub fn prepare_game(self: *Self) !void {
        try graphics.getContext().add_ui_object(.{
            .ptr = self,
            .vtable = &InterfaceUiTable,
        });

        gGame = self;

        try assets.loadList(AssetReferences);

        _ = c.glfwSetKeyCallback(graphics.getContext().window, input_callback);
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
    assets.start_module();
    defer assets.shutdown_module();

    graphics.start_module();
    defer graphics.shutdown_module();

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
