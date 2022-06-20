const std = @import("std");
const core = @import("core/core.zig");
const graphics = @import("graphics/graphics.zig");
const engine_log = core.engine_log;

pub fn main() anyerror!void {
    engine_log("Starting up", .{});

    core.start_module();
    defer core.shutdown_module();

    graphics.start_module();
    defer graphics.shutdown_module();

    try graphics.run();
}
