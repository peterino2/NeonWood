const core = @import("core");
const std = @import("std");
const memory = core.MemoryTracker;

const engine_log = core.engine_log;
const engine_logs = core.engine_logs;

test "simple systems setup for core" {
    std.testing.refAllDecls(core.algorithm);

    memory.MTSetup(std.testing.allocator, .{ .timeline = false });
    defer memory.MTShutdown();
    const tracker = memory.MTGet().?;
    const allocator = tracker.allocator();

    std.debug.print("Starting up \n", .{});
    engine_logs("systems starting");
    try core.start_module(.{}, .{ .unitTest = true }, allocator);
    defer core.shutdown_module(allocator);

    engine_logs("systems started, shutting down");
    memory.MTPrintStatsDelta();

    try memory.dumpTimeline("test-core-timeline.txt");
}
