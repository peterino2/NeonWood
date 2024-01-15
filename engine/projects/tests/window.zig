const std = @import("std");
const nw = @import("root").neonwood;
const core = nw.core;

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    core.start_module(allocator);
    try nw.platform.start_module(allocator, .{ .windowName = "window test" });

    while (!core.gEngine.exitConfirmed) {
        nw.platform.getInstance().pollEvents();
        std.time.sleep(1000 * 1000 * 25);
    }
}
