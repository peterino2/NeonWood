const std = @import("std");
pub const cgltf = @import("cgltf");
pub const spng = @import("spng");

test "000-helloWorld" {
    std.testing.refAllDeclsRecursive(@This());
}
