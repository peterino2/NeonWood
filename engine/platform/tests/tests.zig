const core = @import("core");
const platform = @import("platform");

const std = @import("std");

test "test platform integration" {
    core.start_module(std.testing.allocator);
    defer core.shutdown_module(std.testing.allocator);

    try platform.start_module(std.testing.allocator, .{});
    defer platform.shutdown_module(std.testing.allocator);
}
