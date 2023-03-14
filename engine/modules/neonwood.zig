pub const core = @import("core.zig");
pub const graphics = @import("graphics.zig");
pub const assets = @import("assets.zig");
pub const audio = @import("audio.zig");

const c = graphics.c;

pub fn start_everything(windowName: []const u8) void {
    graphics.setWindowName(windowName);
    core.engine_log("Starting up", .{});
    core.start_module();
    assets.start_module();
    audio.start_module();
    graphics.start_module();
}

pub fn shutdown_everything() void {
    defer core.shutdown_module();
    defer assets.shutdown_module();
    defer audio.shutdown_module();
    defer graphics.shutdown_module();
}

pub fn run_with_context(comptime T: type, input_callback: anytype) !void {
    var gameContext = try core.createObject(T, .{ .can_tick = true });
    try gameContext.prepare_game();

    // run the game
    core.gEngine.run();

    _ = c.glfwSetKeyCallback(graphics.getContext().window, input_callback);

    while (!core.gEngine.exitSignal) {
        graphics.getContext().pollEventsFunc();
    }
}

pub fn run_no_input(comptime T: type) !void {
    var gameContext = try core.createObject(T, .{});
    try gameContext.prepare_game();

    // run the game
    core.gEngine.run();

    while (!core.gEngine.exitSignal) {
        graphics.getContext().pollEventsFunc();
    }
}

pub fn inputCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = key;
    _ = window;
    _ = scancode;
    _ = mods;
    _ = action;
    _ = mods;
}
