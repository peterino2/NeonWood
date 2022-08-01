// this will be replaced by build system symbols later.
const core = @import("../core/core.zig");
const VkRenderer = @import("VkRenderer.zig");
const NeonVkContext = @import("VkRenderer.zig").NeonVkContext;

const engine_logs = core.engine_logs;
const engine_log = core.engine_log;

pub fn start_module() void {
    engine_logs("graphics module starting up...");
}

pub fn shutdown_module() void {
    engine_logs("graphics module shutting down...");
}

pub fn run() !void {
    var renderer = try NeonVkContext.create_object();

    VkRenderer.context = &renderer;
    defer VkRenderer.context = undefined;

    var lastTimeStamp = core.getEngineTime();

    core.graphics_log("renderer @ {*}", .{&renderer});

    while (!try renderer.shouldExit()) {
        const newTime = core.getEngineTime();
        try renderer.draw(newTime - lastTimeStamp);
        lastTimeStamp = newTime;
    }
    // var system = RenderSystem.create_object();

    // try system.init();
    // try system.run();

    // try system.cleanup();
}
