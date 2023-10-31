const std = @import("std");
const nw = @import("root").neonwood;
const core = nw.core;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .stack_trace_frames = 20,
    }){};

    defer {
        const cleanupStatus = gpa.deinit();
        if (cleanupStatus == .leak) {
            std.debug.print("gpa cleanup leaked memory\n", .{});
        }
    }

    core.start_module(gpa.allocator());
    defer core.shutdown_module(gpa.allocator());
}
