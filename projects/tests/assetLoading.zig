const std = @import("std");
pub const neonwood = @import("root").neonwood;

const core = neonwood.core;
const graphics = neonwood.graphics;
const assets = neonwood.assets;
const engine_log = core.engine_log;
const c = graphics.c;
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
        _ = deltaTime;

        if (self.showDemo) {
            c.igShowDemoWindow(&self.showDemo);
        }

        if (self.debugOpen) {
            if (!c.igBegin("Debug Menu", &(self.debugOpen), 0)) {
                c.igEnd();
            } else {
                c.igText("hello boss");

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

        const drawList = c.igGetBackgroundDrawList_Nil();
        c.ImDrawList_AddQuad(
            drawList,
            .{ .x = 100, .y = 100 },
            .{ .x = 200, .y = 100 },
            .{ .x = 200, .y = 200 },
            .{ .x = 100, .y = 200 },
            0xFF0000FF,
            2.0,
        );
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
