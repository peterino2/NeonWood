// this will be replaced by build system symbols later.
const core = @import("../core/core.zig");
const std = @import("std");
const vk_renderer = @import("vk_renderer.zig");
const NeonVkContext = @import("vk_renderer.zig").NeonVkContext;

const engine_logs = core.engine_logs;
const engine_log = core.engine_log;

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

// pub fn run_graphics_test() !void {
//     var renderer = try NeonVkContext.create_object();
//     defer renderer.deinit();
//
//     vk_renderer.gContext = &renderer;
//     defer vk_renderer.gContext = undefined;
//
//     var lastTimeStamp = core.getEngineTime();
//
//     core.graphics_log("renderer @ {*}", .{&renderer});
//
//     while (!try renderer.shouldExit()) {
//         const newTime = core.getEngineTime();
//         var dt: f64 = newTime - lastTimeStamp;
//         renderer.pollInput();
//         try renderer.updateGame(dt);
//         try renderer.draw(dt);
//         std.debug.print("{d} {d}\r", .{ renderer.rendererTime, dt * 1000 });
//         lastTimeStamp = newTime;
//     }
// }
