const std = @import("std");
const glslTypes = @import("glslTypes");
const triangle_mesh_vert = @import("triangle_mesh_vert");

pub fn main() !void {
    std.debug.print("hello {any}\n", .{triangle_mesh_vert.spirv});
}
