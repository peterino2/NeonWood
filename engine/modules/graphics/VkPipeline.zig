const std = @import("std");
const vk = @import("vulkan");
const resources = @import("resources");
const c = @import("c.zig");
const core = @import("../core/core.zig");
const vulkan_constants = @import("vulkan_constants.zig");

const DeviceDispatch = vulkan_constants.DeviceDispatch;
const BaseDispatch = vulkan_constants.BaseDispatch;
const InstanceDispatch = vulkan_constants.InstanceDispatch;

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CStr = core.CStr;

const debug_struct = core.debug_struct;

pub const NeonVkPipelineBuilder = struct {
    vkd: DeviceDispatch,
    allocator: Allocator,
    dev: vk.Device,
    vertShaderModule: vk.ShaderModule,
    fragShaderModule: vk.ShaderModule,

    sscis: ArrayList(vk.PipelineShaderStageCreateInfo),
    pvisci: vk.PipelineVertexInputStateCreateInfo,
    piasci: vk.PipelineInputAssemblyStateCreateInfo,
    prsci: vk.PipelineRasterizationStateCreateInfo,
    pmsci: vk.PipelineMultisampleStateCreateInfo,

    viewport: vk.Viewport,
    scissor: vk.Rect2D,

    colorBlendAttachment: vk.PipelineColorBlendAttachmentState,
    pipelineLayout: vk.PipelineLayout,

    // call after all parameters are good to go.
    pub fn build(self: *NeonVkPipelineBuilder, renderPass: vk.RenderPass) !vk.Pipeline {
        _ = self;
        _ = renderPass;
        return error.NotImplemented;
    }

    // VkPipeline build_pipeline(VkDevice device, VkRenderPass pass);

    pub fn init(dev: vk.Device, vkd: DeviceDispatch, allocator: Allocator, vert_spv: []const u8, frag_spv: []const u8) !NeonVkPipelineBuilder {
        var self: NeonVkPipelineBuilder = undefined;

        self.vkd = vkd;
        self.allocator = allocator;
        self.dev = dev;
        self.sscis = ArrayList(vk.PipelineShaderStageCreateInfo).init(allocator);

        self.vertShaderModule = try self.vkd.createShaderModule(self.dev, &.{
            .flags = .{},
            .code_size = vert_spv.len,
            .p_code = @ptrCast([*]const u32, @alignCast(4, vert_spv)),
        }, null);

        self.fragShaderModule = try self.vkd.createShaderModule(self.dev, &.{
            .flags = .{},
            .code_size = frag_spv.len,
            .p_code = @ptrCast([*]const u32, @alignCast(4, frag_spv)),
        }, null);

        return self;
    }

    pub fn init_all(self: *NeonVkPipelineBuilder) !void {
        try self.add_shader_stage(.{ .vertex_bit = true }, self.vertShaderModule);
        try self.add_shader_stage(.{ .fragment_bit = true }, self.fragShaderModule);
    }

    pub fn add_shader_stage(self: *NeonVkPipelineBuilder, stageFlags: vk.ShaderStageFlags, shaderModule: vk.ShaderModule) !void {
        var info = vk.PipelineShaderStageCreateInfo{
            .flags = .{},
            .stage = stageFlags,
            .module = shaderModule,
            .p_name = "main",
            .p_specialization_info = null,
        };
        try self.sscis.append(info);
    }

    pub fn deinit(self: *NeonVkPipelineBuilder) void {
        core.graphics_logs("destroying pipeline builder resources");
        self.vkd.destroyShaderModule(self.dev, self.fragShaderModule, null);
        self.vkd.destroyShaderModule(self.dev, self.vertShaderModule, null);
    }
};
