const std = @import("std");
const graphics = @import("graphics");
const core = @import("core");

test "simple_integration" {
    // this doesn't really do anything other than just a simple compile check
    std.debug.print("sizeof NeonVkContext = {d}\n", .{@sizeOf(graphics.NeonVkContext)});
    std.debug.print("sizeof triangle_mesh_vert.ObjectData = {d}\n", .{@sizeOf(graphics.vk_renderer.triangle_mesh_vert.ObjectData)});
}

test "renderthread queue" {
    const allocator = std.testing.allocator;
    core.start_module(allocator);
    defer core.shutdown_module(allocator);
}
