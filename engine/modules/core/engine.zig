const std = @import("std");
const logging = @import("logging.zig");

const engine_log = logging.engine_log;

pub fn start_module() void {
    engine_log("core module starting up... ", .{});
    return;
}

pub fn shutdown_module() void {
    engine_log("core module shutting down...", .{});
    return;
}
