// mostly empty bindings, just here to make sure things get linked

pub const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const std = @import("std");

test "glfw3-test" {
    try std.testing.expect(c.GLFW_VERSION_MAJOR == 3);
    try std.testing.expect(c.GLFW_VERSION_MINOR == 3);
}
