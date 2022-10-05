const std = @import("std");
const core = @import("core.zig");
const graphics = @import("graphics.zig");
const engine_log = core.engine_log;

// primarily a test file that exists to create a simple application for
// basic engine onboarding

pub fn main() anyerror!void {
    engine_log("Starting up", .{});

    core.start_module();
    defer core.shutdown_module();

    graphics.start_module();
    defer graphics.shutdown_module();

    core.gEngine.run();
    engine_log("executions complete", .{});
}
