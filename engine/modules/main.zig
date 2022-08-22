const std = @import("std");
const core = @import("core/core.zig");
const graphics = @import("graphics/graphics.zig");
const engine_log = core.engine_log;

// primarily a test file that exists to create a simple application for
// basic engine onboarding

pub fn main() anyerror!void {
    engine_log("Starting up", .{});

    core.start_module();
    defer core.shutdown_module();

    graphics.start_module();
    defer graphics.shutdown_module();

    // try graphics.run_graphics_test();
    engine_log("executions complete", .{});
}
