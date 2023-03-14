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
    _ = c.glfwSetMouseButtonCallback(graphics.getContext().window, mouseInputCallback);

    while (!core.gEngine.exitSignal) {
        graphics.getContext().pollEventsFunc();
    }
}

pub fn run_no_input(comptime T: type) !void {
    var gameContext = try core.createObject(T, .{});
    try gameContext.prepare_game();

    _ = c.glfwSetKeyCallback(graphics.getContext().window, inputCallback);
    _ = c.glfwSetCursorPosCallback(graphics.getContext().window, mousePositionCallback);
    _ = c.glfwSetMouseButtonCallback(graphics.getContext().window, mouseInputCallback);

    // run the game
    core.gEngine.run();

    while (!core.gEngine.exitSignal) {
        graphics.getContext().pollEventsFunc();
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

pub fn mousePositionCallback(window: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    c.cImGui_ImplGlfw_CursorPosCallback(window, xpos, ypos);
}

pub fn mouseInputCallback(window: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    c.cImGui_ImplGlfw_MouseButtonCallback(window, button, action, mods);
}

pub fn inputCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    c.cImGui_ImplGlfw_KeyCallback(window, key, scancode, action, mods);
}
