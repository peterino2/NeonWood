const std = @import("std");
const test_vk = @import("test_vk");
const test_vk2 = @import("test_vk2");

pub fn main() !void {
    std.debug.print("hello world {d}\n", .{@sizeOf(test_vk.ImageRenderData)});
    std.debug.print("hello world {d}\n", .{@sizeOf(test_vk2.ImageRenderData)});
    return;
}
