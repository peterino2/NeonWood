const gl = @import("gl");
const std = @import("std");

test "gl" {
    std.debug.print("c.GL_VERSION = {any}\n", .{gl.c.GL_VERSION});
}
