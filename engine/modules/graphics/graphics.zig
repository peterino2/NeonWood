// this will be replaced by build system symbols later.
const core = @import("../core/core.zig");
const RenderSystem = @import("RenderSystem.zig");

pub fn start_module() void {}

pub fn shutdown_module() void {}

pub fn run() !void {
    var system = RenderSystem.create_object();

    try system.init();
    try system.run();

    try system.cleanup();
}
