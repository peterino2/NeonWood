const tracy = @import("tracy");

const std = @import("std");

test "test-tracy-integration" {
    std.debug.print("tracy integration testing enabled = {any}", .{tracy.enabled});
}
