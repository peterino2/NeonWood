usingnamespace @import("misc.zig");
usingnamespace @import("logging.zig");
usingnamespace @import("algorithm.zig");
usingnamespace @import("engineTime.zig");

const tests = @import("tests.zig");

const logging = @import("logging.zig");

const logs = logging.engine_logs;
const log = logging.engine_log;

pub fn start_module() void {
    logs("core module starting up... ");
    return;
}

pub fn shutdown_module() void {
    logs("core module shutting down...");
    return;
}
