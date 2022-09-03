// this will be replaced by build system symbols later.
//const core = @import("../core/core.zig");
const core = @import("core.zig");
const std = @import("std");
const vk_renderer = @import("graphics/vk_renderer.zig");
pub const NeonVkContext = @import("graphics/vk_renderer.zig").NeonVkContext;
pub const c = vk_renderer.c;

const engine_logs = core.engine_logs;
const engine_log = core.engine_log;

pub fn getContext() *NeonVkContext {
    return vk_renderer.gContext;
}

pub const render_object = @import("graphics/render_object.zig");
pub const Camera = render_object.Camera;

pub fn start_module() void {
    engine_logs("graphics module starting up...");

    var context: *NeonVkContext = core.gEngine.createObject(
        NeonVkContext,
        .{ .can_tick = true },
    ) catch unreachable;

    vk_renderer.gContext = context;
}

pub fn shutdown_module() void {
    vk_renderer.gContext.deinit();
    engine_logs("graphics module shutting down...");
}
