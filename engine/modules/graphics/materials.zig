const std = @import("std");
const vk = @import("vulkan");
const resources = @import("resources");
const c = @import("c.zig");
const core = @import("../core.zig");
const VkConstants = @import("vk_constants.zig");
const meshes = @import("mesh.zig");
const NeonVkContext = @import("vk_renderer.zig").NeonVkContext;
const vk_pipeline = @import("vk_pipeline.zig");

const NeonVkPipelineBuilder = vk_pipeline.NeonVkPipelineBuilder;
const EulerAngles = core.EulerAngles;
const Mat = core.Mat;
const Vectorf = core.Vectorf;
const Quat = core.Quat;
const zm = core.zm;
const mul = zm.mul;

pub const Material = struct {
    materialName: core.Name,
    textureSet: vk.DescriptorSet = .null_handle,
    pipeline: vk.Pipeline,
    layout: vk.PipelineLayout,

    pub fn deinit(self: *Material, ctx: *NeonVkContext) void {
        ctx.vkd.destroyPipeline(ctx.dev, self.pipeline, null);
        ctx.vkAllocator.destroyPipelineLayout(ctx.dev, self.layout);
    }
};

pub const MaterialBuilder = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    ctx: *NeonVkContext,
    pipelineBuilder: NeonVkPipelineBuilder,

    pub fn init(ctx: *NeonVkContext) MaterialBuilder {
        var self = MaterialBuilder{
            .allocator = ctx.allocator,
            .ctx = ctx,
        };

        return self;
    }

    pub fn build(self: *Self) !void {
        _ = self;
        // try self.ctx.add_material();
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }
};
