const core = @import("core");
const std = @import("std");

const engine_log = core.engine_log;
const engine_logs = core.engine_logs;

test "simple systems setup for core" {
    std.debug.print("Starting up \n", .{});
    engine_logs("systems starting");
    core.start_module(std.testing.allocator);
    engine_logs("systems started, shutting down");
    defer core.shutdown_module(std.testing.allocator);
}
