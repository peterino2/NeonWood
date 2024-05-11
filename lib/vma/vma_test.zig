const std = @import("std");
const vma = @import("vma");

test "vma integration" {
    std.debug.print("vulkanVersion = {any}", .{vma.config.vulkanVersion});
}
