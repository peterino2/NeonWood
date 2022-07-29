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

    pub fn init_all(self: *NeonVkPipelineBuilder, extents: vk.Extent2D) !void {
        try self.add_shader_stage(.{ .vertex_bit = true }, self.vertShaderModule);
        try self.add_shader_stage(.{ .fragment_bit = true }, self.fragShaderModule);

        self.pvisci = vk.PipelineVertexInputStateCreateInfo{
            .flags = .{},
            .vertex_binding_description_count = 0,
            .p_vertex_binding_descriptions = undefined,
            .vertex_attribute_description_count = 0,
            .p_vertex_attribute_descriptions = undefined,
        };

        self.piasci = vk.PipelineInputAssemblyStateCreateInfo{
            .flags = .{},
            .topology = .triangle_list,
            .primitive_restart_enable = vk.FALSE,
        };

        self.prsci = .{
            .flags = .{},
            .depth_clamp_enable = vk.FALSE,
            .rasterizer_discard_enable = vk.FALSE,
            .polygon_mode = .fill,
            .cull_mode = .{},
            .front_face = .clockwise,
            .depth_bias_enable = vk.FALSE,
            .depth_bias_constant_factor = 0.0,
            .depth_bias_clamp = 0.0,
            .depth_bias_slope_factor = 0.0,
            .line_width = 1.0,
        }; // rasterizer settings

        self.pmsci = .{
            .flags = .{},
            .rasterization_samples = .{ .@"1_bit" = true },
            .min_sample_shading = 1.0,
            .sample_shading_enable = vk.FALSE,
            .p_sample_mask = null,
            .alpha_to_coverage_enable = vk.FALSE,
            .alpha_to_one_enable = vk.FALSE,
        }; // multisampling settings

        self.viewport = vk.Viewport{
            .x = 0,
            .y = 0,
            .width = @intToFloat(f32, extents.width),
            .height = @intToFloat(f32, extents.height),
            .min_depth = 0.0,
            .max_depth = 1.0,
        };

        self.scissor = .{
            .offset = .{ .x = 0, .y = 0 },
            .extent = extents,
        };

        self.colorBlendAttachment = .{
            .blend_enable = vk.FALSE,
            .src_color_blend_factor = .zero,
            .dst_color_blend_factor = .zero,
            .src_alpha_blend_factor = .zero,
            .dst_alpha_blend_factor = .zero,
            .alpha_blend_op = .add,
            .color_write_mask = .{
                .r_bit = true,
                .g_bit = true,
                .b_bit = true,
                .a_bit = true,
            },
            .color_blend_op = .add,
        }; //

        const plci = vk.PipelineLayoutCreateInfo{
            .flags = .{},
            .set_layout_count = 0,
            .p_set_layouts = undefined,
            .push_constant_range_count = 0,
            .p_push_constant_ranges = undefined,
        };

        self.pipelineLayout = try self.vkd.createPipelineLayout(self.dev, &plci, null);
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
