const std = @import("std");
const core = @import("../core/core.zig");
const vulkan_constants = @import("vulkan_constants.zig");
const Renderer = @import("VkRenderer.zig");

const Vectorf = core.math.Vectorf;

pub const Vertex = struct {
    position: Vectorf,
    color: Vectorf,
    normal: Vectorf,
};

pub const Mesh = struct {
    vertices: ArrayList(Vertex),
    buffer: Renderer.AllocatedBuffer,
};
