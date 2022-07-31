const std = @import("std");
const core = @import("../core/core.zig");
const VkConstants = @import("VkConstants.zig");
const VkRenderer = @import("VkRenderer.zig");
const vk = @import("vk");

const ArrayList = std.ArrayList;
const Vectorf = core.math.Vectorf;
const NeonVkContext = VkRenderer.NeonVkContext;
const NeonVkBuffer = VkRenderer.NeonVkBuffer;

pub const Vertex = struct {
    position: Vectorf,
    normal: Vectorf,
    color: core.math.LinearColor,
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

pub const VertexInputDescription = struct {
    bindings: ArrayList(vk.VertexInputBindingDescription),
    attributes: ArrayList(vk.VertexInputAttributeDescription),
    flags: vk.PipelineVertexInputStateCreateFlags = .{},

    pub fn init(allocator: std.mem.Allocator) !VertexInputDescription {
        var self = VertexInputDescription{
            .bindings = ArrayList(vk.VertexInputBindingDescription).init(allocator),
            .attributes = ArrayList(vk.VertexInputAttributeDescription).init(allocator),
        };

        try self.bindings.append(.{
            .binding = 0,
            .stride = @sizeOf(Vertex),
            .input_rate = .vertex,
        });

        // position
        try self.attributes.append(.{
            .binding = 0,
            .location = 0,
            .format = .r32g32b32_sfloat,
            .offset = @offsetOf(Vertex, "position"),
        });

        // normal
        try self.attributes.append(.{
            .binding = 0,
            .location = 1,
            .format = .r32g32b32_sfloat,
            .offset = @offsetOf(Vertex, "normal"),
        });

        // color
        try self.attributes.append(.{
            .binding = 0,
            .location = 2,
            .format = .r32g32b32a32_sfloat,
            .offset = @offsetOf(Vertex, "color"),
        });

        return self;
    }

    pub fn deinit(self: *@This()) void {
        self.bindings.deinit();
        self.attributes.deinit();
    }
};
