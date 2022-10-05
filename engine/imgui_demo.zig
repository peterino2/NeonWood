const std = @import("std");
pub const neonwood = @import("modules/neonwood.zig");

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
    debugOpen: bool = true,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
        };

        core.game_logs("Game starting");

        return self;
    }

    pub fn uiTick(self: *Self, deltaTime: f64) void {
        _ = self;
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

    graphics.start_module();
    defer graphics.shutdown_module();

    var gameContext = try core.createObject(GameContext, .{ .can_tick = false });
    try gameContext.prepare_game();

    // run the game
    core.gEngine.run();
}

pub fn input_callback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = window;
    _ = key;
    _ = scancode;
    _ = action;
    _ = mods;

    if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS) {
        core.engine_logs("Escape key pressed, game ends now");
        core.gEngine.exit();
    }

    if (key == c.GLFW_KEY_SPACE and action == c.GLFW_PRESS) {
        gGame.showDemo = true;
    }
}
