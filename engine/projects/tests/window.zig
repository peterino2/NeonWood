const std = @import("std");
const nw = @import("root").neonwood;
const core = nw.core;

pub fn main() !void {
    core.start_module();
    defer core.shutdown_module();

    try nw.platform.start_module(std.heap.c_allocator, "jobTest", null);

    while (!core.gEngine.exitSignal) {}

    try core.gEngine.run();
}
