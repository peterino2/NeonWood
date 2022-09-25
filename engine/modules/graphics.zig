const core = @import("core.zig");
const std = @import("std");
const vk_renderer = @import("graphics/vk_renderer.zig");
pub const c = vk_renderer.c;

pub const NeonVkContext = vk_renderer.NeonVkContext;
pub const vk_ui = @import("graphics/vk_imgui.zig");

pub const NeonVkImGui = vk_ui.NeonVkImGui;

const engine_logs = core.engine_logs;
const engine_log = core.engine_log;

pub fn getContext() *NeonVkContext {
    return vk_renderer.gContext;
}

pub const render_object = @import("graphics/render_object.zig");
pub const Camera = render_object.Camera;

pub var gImgui: *NeonVkImGui = undefined;

pub fn start_module() void {
    engine_logs("graphics module starting up...");

    var context: *NeonVkContext = core.gEngine.createObject(
        NeonVkContext,
        .{ .can_tick = true },
    ) catch unreachable;
    vk_renderer.gContext = context;

    var vkUi: *NeonVkImGui = core.gEngine.createObject(
        NeonVkImGui,
        .{ .can_tick = false },
    ) catch unreachable;
    gImgui = vkUi;

    vkUi.setup(context) catch unreachable;
}

pub fn shutdown_module() void {
    gImgui.deinit();
    vk_renderer.gContext.deinit();
    engine_logs("graphics module shutting down...");
}
