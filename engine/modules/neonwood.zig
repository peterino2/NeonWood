pub const core = @import("core.zig");
pub const graphics = @import("graphics.zig");
pub const assets = @import("assets.zig");
pub const audio = @import("audio.zig");
pub const platform = @import("platform.zig");
pub const ui = @import("ui.zig");

const std = @import("std");

const c = graphics.c;

pub fn start_everything(allocator: std.mem.Allocator, windowName: []const u8) !void {
    graphics.setWindowName(windowName);
    core.engine_log("Starting up", .{});

    core.start_module(allocator); // 1
    try platform.start_module(std.heap.c_allocator, windowName, null); // 2
    assets.start_module(allocator); // 3
    audio.start_module(allocator); //4
    graphics.start_module(allocator); //5
    try ui.start_module(allocator); //6
}

pub fn shutdown_everything(allocator: std.mem.Allocator) void {
    ui.shutdown_module(); //6
    graphics.shutdown_module(); //5
    audio.shutdown_module(); //4
    assets.shutdown_module(); //3
    platform.shutdown_module(allocator); //2
    core.shutdown_module(allocator); // 1
}

pub fn run_with_context(comptime T: type, input_callback: anytype) !void {
    var gameContext = try core.createObject(T, .{ .can_tick = true });
    try gameContext.prepare_game();

    // run the game
    core.gEngine.run();
    _ = platform.c.glfwSetKeyCallback(platform.getInstance().window, input_callback);
    _ = platform.c.glfwSetMouseButtonCallback(platform.getInstance().window, mouseInputCallback);

    while (!core.gEngine.exitConfirmed) {
        graphics.getContext().pollEventsFunc();
    }
}

pub fn run_no_input_tickable(comptime T: type) !void {
    var gameContext = try core.createObject(T, .{ .can_tick = true });
    try gameContext.prepare_game();

    // run the game
    try core.gEngine.run();

    while (!core.gEngine.exitConfirmed) {
        platform.getInstance().pollEvents();
        std.time.sleep(1000 * 1000 * 25);
    }
}

pub fn run_no_input(comptime T: type) !void {
    var gameContext = try core.createObject(T, .{});
    try gameContext.prepare_game();

    _ = platform.c.glfwSetKeyCallback(platform.getInstance().window, inputCallback);
    _ = platform.c.glfwSetCursorPosCallback(platform.getInstance().window, mousePositionCallback);
    _ = platform.c.glfwSetMouseButtonCallback(platform.getInstance().window, mouseInputCallback);

    // run the game
    try core.gEngine.run();

    while (!core.gEngine.exitSignal) {
        platform.getInstance().pollEvents();
    }
}

pub fn mousePositionCallback(window: ?*platform.c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    _ = window;
    _ = xpos;
    _ = ypos;
}

pub fn mouseInputCallback(window: ?*platform.c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = window;
    _ = button;
    _ = action;
    _ = mods;
}

pub fn inputCallback(window: ?*platform.c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = window;
    _ = key;
    _ = scancode;
    _ = action;
    _ = mods;
}
