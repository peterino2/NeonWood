const std = @import("std");
const core = @import("../core/core.zig");
const ArrayList = std.ArrayList;

const vk = @import("vulkan");
const c = @import("c.zig");

const GraphicsContext = @import("graphicsContext.zig").GraphicsContext;

const engine_logs = core.engine_logs;
const engine_log = core.engine_log;

const graphics_logs = core.graphics_logs;
const graphics_log = core.graphics_log;
const resources = @import("resources");

const Self = @This();

const Swapchain = @import("swapchain.zig").Swapchain;

const Vertex = struct {
    const binding_description = vk.VertexInputBindingDescription{
        .binding = 0,
        .stride = @sizeOf(Vertex),
        .input_rate = .vertex,
    };

    const attribute_description = [_]vk.VertexInputAttributeDescription{
        .{
            .binding = 0,
            .location = 0,
            .format = .r32g32_sfloat,
            .offset = @offsetOf(Vertex, "pos"),
        },
        .{
            .binding = 0,
            .location = 1,
            .format = .r32g32b32_sfloat,
            .offset = @offsetOf(Vertex, "color"),
        },
    };

    pos: [2]f32,
    color: [3]f32,
};

bIsInitialized: bool = false,
gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined,
allocator: std.mem.Allocator = undefined,

// names prefixed with underbars, are external API names.
_extent: vk.Extent2D = undefined,
_window: ?*c.GLFWwindow = null,
_windowName: [*c]const u8,
_gc: GraphicsContext = undefined,
_swapchain: Swapchain = undefined,
_pipelineLayout: vk.PipelineLayout = undefined,
_renderPass: vk.RenderPass = undefined,

pub fn init(self: *Self) !void {
    _ = self;

    try self.init_window();
    try self.init_vulkan_api();
    try self.init_swapchain();
    try self.init_renderpass();
    try self.init_pipelines();
    try self.init_load_engine_assets();

    self.bIsInitialized = true;
}

fn init_window(self: *Self) !void {
    _ = self;

    engine_logs("initializing glfw");
    if (c.glfwInit() != c.GLFW_TRUE) {
        engine_logs("Glfw Init Failed");
        return error.GlfwInitFailed;
    }

    self._extent = vk.Extent2D{ .width = 800, .height = 600 };
    engine_log("creating window\n  with extents: {any},\n  with name = {s}", .{
        self._extent,
        self._windowName,
    });

    c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);

    self._window = c.glfwCreateWindow(
        @intCast(c_int, self._extent.width),
        @intCast(c_int, self._extent.height),
        self._windowName,
        null,
        null,
    ) orelse return error.WindowInitFailed;

    self.gpa = std.heap.GeneralPurposeAllocator(.{}){};
}

fn init_vulkan_api(self: *Self) !void {
    _ = self;

    self.allocator = self.gpa.allocator();
    self._gc =
        try GraphicsContext.init(
        self.allocator,
        self._windowName,
        self._window.?,
    );

    graphics_log("Vulkan api -- using device {s}", .{self._gc.deviceName()});
}

fn init_swapchain(self: *Self) !void {
    _ = self;
    self._swapchain = try Swapchain.init(
        &self._gc,
        self.allocator,
        self._extent,
    );
}

fn init_renderpass(s: *Self) !void {
    const vkd = s._gc.vkd;
    const colorAttachment = vk.AttachmentDescription{
        .flags = .{},
        .format = s._swapchain.surface_format.format,
        .samples = .{ .@"1_bit" = true },
        .load_op = .clear,
        .store_op = .store,
        .stencil_load_op = .dont_care,
        .stencil_store_op = .dont_care,
        .initial_layout = .@"undefined",
        .final_layout = .present_src_khr,
    };

    const color_attachment_ref = vk.AttachmentReference{
        .attachment = 0,
        .layout = .color_attachment_optimal,
    };

    const subpass = vk.SubpassDescription{
        .flags = .{},
        .pipeline_bind_point = .graphics,
        .input_attachment_count = 0,
        .p_input_attachments = undefined,
        .color_attachment_count = 1,
        .p_color_attachments = @ptrCast([*]const vk.AttachmentReference, &color_attachment_ref),
        .p_resolve_attachments = null,
        .p_depth_stencil_attachment = null,
        .preserve_attachment_count = 0,
        .p_preserve_attachments = undefined,
    };

    // const renderPassCreateInfo = vk.RenderPassCreateInfo {
    //  flags: RenderPassCreateFlags align(@alignOf(Flags)),
    //  attachment_count: u32,
    //  p_attachments: [*]const AttachmentDescription2,
    //  subpass_count: u32,
    //  p_subpasses: [*]const SubpassDescription2,
    //  dependency_count: u32,
    //  p_dependencies: [*]const SubpassDependency2,
    //  correlated_view_mask_count: u32,
    //  p_correlated_view_masks: [*]const u32,
    // };
    //
    //
    s._renderPass = try vkd.createRenderPass(s._gc.dev, &.{
        .flags = .{},
        .attachment_count = 1,
        .p_attachments = @ptrCast([*]const vk.AttachmentDescription, &colorAttachment),
        .subpass_count = 1,
        .p_subpasses = @ptrCast([*]const vk.SubpassDescription, &subpass),
        .dependency_count = 0,
        .p_dependencies = undefined,
    }, null);
}

fn setup_pipeline_layout(self: *Self) !void {
    const gc = self._gc;
    const pipelineCreateInfo = vk.PipelineLayoutCreateInfo{
        .flags = .{},
        .set_layout_count = 0,
        .p_set_layouts = undefined,
        .push_constant_range_count = 0,
        .p_push_constant_ranges = undefined,
    };
    self._pipelineLayout = try gc.vkd.createPipelineLayout(gc.dev, &pipelineCreateInfo, null);
}

fn init_pipelines(self: *Self) !void {
    _ = self;
    try self.setup_pipeline_layout();
    try createPipeline(self._gc, self._pipelineLayout);
}

fn init_load_engine_assets(self: *Self) !void {
    _ = self;
}

// All objects shall implement
// a create_object function.

pub fn create_object() @This() {
    return .{ ._windowName = "Hello NeonWood!" };
}

pub fn run(self: *Self) !void {
    _ = self;

    while (c.glfwWindowShouldClose(self._window) == c.GLFW_FALSE) {
        var w: c_int = undefined;
        var h: c_int = undefined;

        c.glfwGetWindowSize(self._window, &w, &h);
        c.glfwPollEvents();
    }

    engine_logs("glfw window closed");
}

pub fn cleanup(self: *Self) !void {
    _ = self;
    if (!self.bIsInitialized)
        return error.RenderSystemNotInitialized;
    const vkd = self._gc.vkd;
    const dev = self._gc.dev;

    vkd.destroyRenderPass(dev, self._renderPass, null);
    self._gc.vkd.destroyPipelineLayout(self._gc.dev, self._pipelineLayout, null);
    self._swapchain.deinit();
    self._gc.deinit();

    c.glfwTerminate();

    _ = self.gpa.deinit();
}

fn createPipeline(
    self: *Self,
    gc: GraphicsContext,
    layout: vk.PipelineLayout,
) !void {
    _ = gc;
    _ = layout;
    const vert = try gc.vkd.createShaderModule(gc.dev, &.{
        .flags = .{},
        .code_size = resources.triangle_vert.len,
        .p_code = @ptrCast([*]const u32, resources.triangle_vert),
    }, null);
    defer gc.vkd.destroyShaderModule(gc.dev, vert, null);

    const frag = try gc.vkd.createShaderModule(gc.dev, &.{
        .flags = .{},
        .code_size = resources.triangle_frag.len,
        .p_code = @ptrCast([*]const u32, resources.triangle_vert),
    }, null);
    defer gc.vkd.destroyShaderModule(gc.dev, frag, null);

    // pipeline shader stage creation info struct
    const pssci = [_]vk.PipelineShaderStageCreateInfo{
        .{
            .flags = .{},
            .stage = .{ .vertex_bit = true },
            .module = vert,
            .p_name = "main",
            .p_specialization_info = null,
        },
        .{
            .flags = .{},
            .stage = .{ .fragment_bit = true },
            .module = vert,
            .p_name = "main",
            .p_specialization_info = null,
        },
    };
    _ = pssci;

    //
    const pvisci = vk.PipelineVertexInputStateCreateInfo{
        .flags = .{},
        .vertex_binding_description_count = 1,
        .p_vertex_binding_descriptions = @ptrCast([*]const vk.VertexInputBindingDescription, &Vertex.binding_description),
        .vertex_attribute_description_count = Vertex.attribute_description.len,
        .p_vertex_attribute_descriptions = &Vertex.attribute_description,
    };
    _ = pvisci;

    const piasci = vk.PipelineInputAssemblyStateCreateInfo{
        .flags = .{},
        .topology = .triangle_list,
        .primitive_restart_enable = vk.FALSE,
    };
    _ = piasci;

    const pvsci = vk.PipelineViewportStateCreateInfo{
        .flags = {},
        .viewport_count = 1,
        .p_viewports = undefined,
        .scissor_count = 1,
        .p_scissors = undefined,
    };
    _ = pvsci;

    const prsci = vk.PipelineRasterizationStateCreateInfo{
        .flags = .{},
    };
    _ = prsci;

    const pmsci = vk.PipelineMultisampleStateCreateInfo{
        .flags = .{},
    };
    _ = pmsci;

    const pcbas = vk.PipelineColorBlendAttachmentState{
        .flag = .{},
    };
    _ = pcbas;

    const pcbsci = vk.PipelineColorBlendStateCreateInfo{
        .flags = .{},
        .logic_op_enable = vk.FALSE,
        .logic_op = .copy,
        .attachment_count = 1,
        .p_attachments = @ptrCast([*]const vk.PipelineColorBlendAttachmentState, &pcbas),
        .blend_constants = [_]f32{ 0, 0, 0, 0 },
    };

    const dynstate = [_]vk.DynamicState{ .viewport, .scissor };
    const pdsci = vk.PipelineDynamicStateCreateInfo{
        .flags = .{},
        .dynamic_state_count = dynstate.len,
        .p_dynamic_states = &dynstate,
    };

    const gpci = vk.GraphicsPipelineCreateInfo{
        .flags = .{},
        .stage_count = 2,
        .p_stages = &pssci,
        .p_vertex_input_state = &pvisci,
        .p_input_assembly_state = &piasci,
        .p_tessellation_state = null,
        .p_viewport_state = &pvsci,
        .p_rasterization_state = &prsci,
        .p_multisample_state = &pmsci,
        .p_depth_stencil_state = null,
        .p_color_blend_state = &pcbsci,
        .p_dynamic_state = &pdsci,
        .layout = layout,
        .render_pass = self._renderPass,
        .subpass = 0,
        .base_pipeline_handle = .null_handle,
        .base_pipeline_index = -1,
    };

    var pipeline: vk.Pipeline = undefined;
    _ = try gc.vkd.createGraphicsPipelines(
        gc.dev,
        .null_handle,
        1,
        @ptrCast([*]const vk.GraphicsPipelineCreateInfo, &gpci),
        null,
        @ptrCast([*]vk.Pipeline, &pipeline),
    );
    _ = pipeline;
}
