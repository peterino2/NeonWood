const std = @import("std");
const vk = @import("vulkan");
const resources = @import("resources");
const c = @import("c.zig");
const core = @import("../core.zig");
const VkConstants = @import("vk_constants.zig");
const meshes = @import("mesh.zig");
const NeonVkContext = @import("vk_renderer.zig").NeonVkContext;
const assert = core.assert;

pub const NeonVkMeshPushConstant = struct {
    data: core.Vector4f,
    render_matrix: core.Mat,
};

const DeviceDispatch = VkConstants.DeviceDispatch;
const BaseDispatch = VkConstants.BaseDispatch;
const InstanceDispatch = VkConstants.InstanceDispatch;

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CStr = core.CStr;

const debug_struct = core.debug_struct;
const p2a = core.p_to_a;
const p2av = core.p_to_av;

pub fn default_pipeline_layout() vk.PipelineLayoutCreateInfo {
    return vk.PipelineLayoutCreateInfo{
        .flags = .{},
        .set_layout_count = 0,
        .p_set_layouts = undefined,
        .push_constant_range_count = 0,
        .p_push_constant_ranges = undefined,
    };
}

fn make_depth_stencil_create_info(
    depth_test: bool,
    depth_write: bool,
    compareOp: vk.CompareOp,
) vk.PipelineDepthStencilStateCreateInfo {
    var pdsci = vk.PipelineDepthStencilStateCreateInfo{
        .flags = .{},
        .depth_test_enable = if (depth_test) vk.TRUE else vk.FALSE,
        .depth_write_enable = if (depth_write) vk.TRUE else vk.FALSE,
        .depth_compare_op = if (depth_test) compareOp else .never,
        .depth_bounds_test_enable = vk.FALSE,
        .min_depth_bounds = 0.0,
        .max_depth_bounds = 1.0,
        .stencil_test_enable = vk.FALSE,
        .front = std.mem.zeroes(vk.StencilOpState),
        .back = std.mem.zeroes(vk.StencilOpState),
    };

    return pdsci;
}

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
    plci: ?vk.PipelineLayoutCreateInfo,
    pdsci: ?vk.PipelineDepthStencilStateCreateInfo,

    topology: vk.PrimitiveTopology = .triangle_list,
    polygonMode: vk.PolygonMode = .fill,

    pushConstantRange: ?vk.PushConstantRange,

    viewport: vk.Viewport,
    scissor: vk.Rect2D,

    vertexInputDescription: ?meshes.VertexInputDescription,

    colorBlendAttachment: vk.PipelineColorBlendAttachmentState,
    pipelineLayout: vk.PipelineLayout,

    descriptorLayouts: ArrayList(vk.DescriptorSetLayout),

    // a seperate more convenient version of the default one
    pub fn initFromContext(ctx: *NeonVkContext, vert_resource: anytype, frag_resource: anytype) !@This() {
        return try NeonVkPipelineBuilder.init(
            ctx.dev,
            ctx.vkd,
            ctx.allocator,
            vert_resource.len,
            @ptrCast([*]const u32, @alignCast(4, &vert_resource)),
            frag_resource.len,
            @ptrCast([*]const u32, @alignCast(4, &frag_resource)),
        );
    }

    // call after all parameters are good to go.
    pub fn build(self: *NeonVkPipelineBuilder, renderPass: vk.RenderPass) !?vk.Pipeline {
        var pvsci = vk.PipelineViewportStateCreateInfo{
            .flags = .{},
            .viewport_count = 1,
            .p_viewports = p2a(&self.viewport),
            .scissor_count = 1,
            .p_scissors = p2a(&self.scissor),
        };

        var pcbsci = vk.PipelineColorBlendStateCreateInfo{
            .flags = .{},
            .logic_op_enable = vk.FALSE,
            .attachment_count = 1,
            .p_attachments = p2a(&self.colorBlendAttachment),
            .logic_op = .copy,
            .blend_constants = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
        };

        var dynamicStates = [_]vk.DynamicState{
            .viewport,
            .scissor,
        };

        var dynamicStateCreateInfo = vk.PipelineDynamicStateCreateInfo{
            .flags = .{},
            .dynamic_state_count = 2,
            .p_dynamic_states = &dynamicStates,
        };

        var gpci = vk.GraphicsPipelineCreateInfo{
            .flags = .{},
            .stage_count = @intCast(u32, self.sscis.items.len),
            .p_stages = self.sscis.items.ptr,
            .p_vertex_input_state = &self.pvisci, // : ?*const PipelineVertexInputStateCreateInfo,
            .p_input_assembly_state = &self.piasci, //: ?*const PipelineInputAssemblyStateCreateInfo,
            .p_tessellation_state = null, //: ?*const PipelineTessellationStateCreateInfo,
            .p_viewport_state = &pvsci, //: ?*const PipelineViewportStateCreateInfo,
            .p_rasterization_state = &self.prsci, //: *const PipelineRasterizationStateCreateInfo,
            .p_multisample_state = &self.pmsci, //: ?*const PipelineMultisampleStateCreateInfo,
            .p_depth_stencil_state = null, //: ?*const PipelineDepthStencilStateCreateInfo,
            .p_color_blend_state = &pcbsci, //: ?*const PipelineColorBlendStateCreateInfo,
            .p_dynamic_state = &dynamicStateCreateInfo, //: ?*const PipelineDynamicStateCreateInfo,
            //.p_dynamic_state = null, //: ?*const PipelineDynamicStateCreateInfo,
            .layout = self.pipelineLayout,
            .render_pass = renderPass,
            .subpass = 0,
            .base_pipeline_handle = .null_handle,
            .base_pipeline_index = 0,
        };

        if (self.pdsci != null) {
            core.graphics_logs("configuring with a valid set of stencil information");
            gpci.p_depth_stencil_state = &(self.pdsci.?);
        }
        //debug_struct("building with pvisci: ", self.pvisci);

        var pipeline: vk.Pipeline = undefined;

        _ = self.vkd.createGraphicsPipelines(self.dev, .null_handle, 1, p2a(&gpci), null, p2av(&pipeline)) catch return null;

        return pipeline;
    }

    pub fn add_depth_stencil(self: *NeonVkPipelineBuilder) !void {
        self.pdsci = make_depth_stencil_create_info(true, true, .less_or_equal);
    }

    // VkPipeline build_pipeline(VkDevice device, VkRenderPass pass);

    pub fn init(
        dev: vk.Device,
        vkd: DeviceDispatch,
        allocator: Allocator,
        vert_spv_len: u32,
        vert_spv: [*]const u32,
        frag_spv_len: u32,
        frag_spv: [*]const u32,
    ) !NeonVkPipelineBuilder {
        var self: NeonVkPipelineBuilder = undefined;

        self.vkd = vkd;
        self.allocator = allocator;
        self.dev = dev;
        self.sscis = ArrayList(vk.PipelineShaderStageCreateInfo).init(allocator);
        self.plci = null;
        self.pushConstantRange = null;
        self.pdsci = null;
        self.descriptorLayouts = ArrayList(vk.DescriptorSetLayout).init(allocator);

        self.topology = .triangle_list;
        self.polygonMode = .fill;

        self.vertShaderModule = try self.vkd.createShaderModule(self.dev, &.{
            .flags = .{},
            .code_size = vert_spv_len,
            .p_code = vert_spv,
        }, null);

        self.fragShaderModule = try self.vkd.createShaderModule(self.dev, &.{
            .flags = .{},
            .code_size = frag_spv_len,
            .p_code = frag_spv,
        }, null);

        self.vertexInputDescription = null;

        return self;
    }

    pub fn add_layout(self: *NeonVkPipelineBuilder, layout: vk.DescriptorSetLayout) !void {
        if (self.plci == null) {
            self.plci = default_pipeline_layout();
            assert(self.descriptorLayouts.items.len == 0);
        }

        try self.descriptorLayouts.append(layout);
        self.plci.?.set_layout_count += 1;
        self.plci.?.p_set_layouts = self.descriptorLayouts.items.ptr;
    }

    pub fn add_push_constant(self: *NeonVkPipelineBuilder) !void {
        if (self.plci == null) {
            self.plci = default_pipeline_layout();
        }

        self.pushConstantRange = vk.PushConstantRange{
            .offset = 0,
            .size = @sizeOf(NeonVkMeshPushConstant),
            .stage_flags = .{ .vertex_bit = true },
        };

        self.plci.?.push_constant_range_count = 1;
        self.plci.?.p_push_constant_ranges = p2a(&(self.pushConstantRange.?));
    }

    pub fn add_mesh_description(self: *NeonVkPipelineBuilder) !void {
        core.graphics_logs("adding vertex mesh description");
        self.vertexInputDescription = try meshes.VertexInputDescription.init(self.allocator);
    }

    pub fn set_topology(self: *@This(), topology: vk.PrimitiveTopology) void {
        self.topology = topology;
    }

    pub fn set_polygon_mode(self: *@This(), polygonMode: vk.PolygonMode) void {
        self.polygonMode = polygonMode;
    }

    // the init _ functions are called last and perform cleanup. all the other add_ functions can be called
    // before this
    pub fn init_triangle_pipeline(self: *NeonVkPipelineBuilder, extents: vk.Extent2D) !void {
        try self.add_shader_stage(.{ .vertex_bit = true }, self.vertShaderModule);
        try self.add_shader_stage(.{ .fragment_bit = true }, self.fragShaderModule);

        self.pvisci = vk.PipelineVertexInputStateCreateInfo{
            .flags = .{},
            .vertex_binding_description_count = 0,
            .vertex_attribute_description_count = 0,
            .p_vertex_attribute_descriptions = undefined,
            .p_vertex_binding_descriptions = undefined,
        };

        if (self.vertexInputDescription != null) {
            const desc = self.vertexInputDescription.?;

            self.pvisci.vertex_attribute_description_count = @intCast(u32, desc.attributes.items.len);
            self.pvisci.p_vertex_attribute_descriptions = desc.attributes.items.ptr;

            self.pvisci.vertex_binding_description_count = @intCast(u32, desc.bindings.items.len);
            self.pvisci.p_vertex_binding_descriptions = desc.bindings.items.ptr;
            core.graphics_logs("setting up vertex description");
        }

        self.piasci = vk.PipelineInputAssemblyStateCreateInfo{
            .flags = .{},
            .topology = self.topology,
            // .topology = .line_list,
            .primitive_restart_enable = vk.FALSE,
        };

        self.prsci = .{
            .flags = .{},
            .depth_clamp_enable = vk.FALSE,
            .rasterizer_discard_enable = vk.FALSE,
            .polygon_mode = self.polygonMode,
            //.polygon_mode = .line,
            //.cull_mode = .{ .back_bit = true },
            .cull_mode = .{ .back_bit = false },
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
            .blend_enable = vk.TRUE,
            .src_color_blend_factor = .src_alpha,
            .dst_color_blend_factor = .one_minus_src_alpha,
            .src_alpha_blend_factor = .src_alpha,
            .dst_alpha_blend_factor = .one_minus_src_alpha,
            .alpha_blend_op = .add,
            .color_write_mask = .{
                .r_bit = true,
                .g_bit = true,
                .b_bit = true,
                .a_bit = true,
            },
            .color_blend_op = .add,
        }; //

        if (self.plci == null)
            self.plci = default_pipeline_layout();

        self.pipelineLayout = try self.vkd.createPipelineLayout(self.dev, &(self.plci.?), null);
    }

    pub fn add_shader_stage(
        self: *NeonVkPipelineBuilder,
        stageFlags: vk.ShaderStageFlags,
        shaderModule: vk.ShaderModule,
    ) !void {
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
        self.vkd.destroyShaderModule(self.dev, self.fragShaderModule, null);
        self.vkd.destroyShaderModule(self.dev, self.vertShaderModule, null);
        self.sscis.deinit();

        if (self.vertexInputDescription != null)
            self.vertexInputDescription.?.deinit();

        self.descriptorLayouts.deinit();
    }
};
