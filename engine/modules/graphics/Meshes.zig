const std = @import("std");
const core = @import("../core/core.zig");
const vulkan_constants = @import("vulkan_constants.zig");
const VkRenderer = @import("VkRenderer.zig");

const ArrayList = std.ArrayList;
const Vectorf = core.math.Vectorf;
const NeonVkContext = VkRenderer.NeonVkContext;
const NeonVkBuffer = VkRenderer.NeonVkBuffer;

pub const Vertex = struct {
    position: Vectorf,
    color: core.math.LinearColor,
    normal: Vectorf,
};

pub const Mesh = struct {
    vertices: ArrayList(Vertex),
    buffer: NeonVkBuffer,

    pub fn init(context: *NeonVkContext, allocator: std.mem.Allocator) Mesh {
        var self = Mesh{
            .vertices = ArrayList(Vertex).init(allocator),
            .buffer = undefined,
        };
        _ = context;
        return self;
    }
};
