// mostly empty bindings, just here to make sure things get linked

pub usingnamespace @cImport({
    @cDefine("GLFW_INCLUDE_NONE", {});
    @cInclude("GLFW/glfw3.h");
});

const c = @This();
const std = @import("std");

test "glfw3-test" {
    try std.testing.expect(c.GLFW_VERSION_MAJOR == 3);
    try std.testing.expect(c.GLFW_VERSION_MINOR == 3);
}
