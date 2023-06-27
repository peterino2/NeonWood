pub const core = @import("core.zig");
pub const graphics = @import("graphics.zig");
pub const assets = @import("assets.zig");
pub const audio = @import("audio.zig");
pub const platform = @import("platform.zig");
pub const ui = @import("ui.zig");

const std = @import("std");

const c = graphics.c;

pub fn start_everything(windowName: []const u8) !void {
    graphics.setWindowName(windowName);
    core.engine_log("Starting up", .{});
    core.start_module();
    try platform.start_module(std.heap.c_allocator, windowName, null);
    assets.start_module();
    audio.start_module();
    graphics.start_module();
    try ui.start_module(std.heap.c_allocator);
}

pub fn shutdown_everything() void {
    ui.shutdown_module();
    graphics.shutdown_module();
    audio.shutdown_module();
    assets.shutdown_module();
    core.shutdown_module();
}

pub fn run_with_context(comptime T: type, input_callback: anytype) !void {
    var gameContext = try core.createObject(T, .{ .can_tick = true });
    try gameContext.prepare_game();

    // run the game
    core.gEngine.run();

    _ = platform.c.glfwSetKeyCallback(platform.getInstance().window, input_callback);
    _ = platform.c.glfwSetMouseButtonCallback(platform.getInstance().window, mouseInputCallback);

    while (!core.gEngine.exitSignal) {
        graphics.getContext().pollEventsFunc();
    }
}

pub fn run_no_input_tickable(comptime T: type) !void {
    var gameContext = try core.createObject(T, .{ .can_tick = true });
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

// These are Imgui callbacks that need to be rejigged
// glfwSetWindowFocusCallback(vd->Window, ImGui_ImplGlfw_WindowFocusCallback);
// glfwSetCursorEnterCallback(vd->Window, ImGui_ImplGlfw_CursorEnterCallback);
// glfwSetCursorPosCallback(vd->Window, ImGui_ImplGlfw_CursorPosCallback);
// glfwSetMouseButtonCallback(vd->Window, ImGui_ImplGlfw_MouseButtonCallback);
// glfwSetScrollCallback(vd->Window, ImGui_ImplGlfw_ScrollCallback);
// glfwSetKeyCallback(vd->Window, ImGui_ImplGlfw_KeyCallback);
// glfwSetCharCallback(vd->Window, ImGui_ImplGlfw_CharCallback);
// glfwSetWindowCloseCallback(vd->Window, ImGui_ImplGlfw_WindowCloseCallback);
// glfwSetWindowPosCallback(vd->Window, ImGui_ImplGlfw_WindowPosCallback);
// glfwSetWindowSizeCallback(vd->Window, ImGui_ImplGlfw_WindowSizeCallback);

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
