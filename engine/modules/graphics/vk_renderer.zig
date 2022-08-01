const std = @import("std");
const vk = @import("vulkan");
const resources = @import("resources");
const c = @import("c.zig");
const vma = @import("vma");
const core = @import("../core/core.zig");
const vk_constants = @import("vk_constants.zig");
const vk_pipeline = @import("vk_pipeline.zig");
const NeonVkPipelineBuilder = vk_pipeline.NeonVkPipelineBuilder;
const meshes = @import("meshes.zig");

// Aliases
const p2a = core.p_to_a;
const p2av = core.p_to_av;

const DeviceDispatch = vk_constants.DeviceDispatch;
const BaseDispatch = vk_constants.BaseDispatch;
const InstanceDispatch = vk_constants.InstanceDispatch;

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CStr = core.CStr;

const debug_struct = core.debug_struct;

const required_device_extensions = [_]CStr{
    vk.extension_info.khr_swapchain.name,
};

pub const NeonVkBuffer = struct {
    buffer: vk.Buffer,
    allocation: vma.Allocation,

    pub fn deinit(self: *NeonVkBuffer, allocator: vma.Allocator) void {
        allocator.destroyBuffer(self.buffer, self.allocation);
    }
};

pub const NeonVkSwapImage = struct {
    image: vk.Image,
    view: vk.ImageView,
    imageIndex: usize,

    pub fn deinit(self: *NeonVkSwapImage, ctx: *NeonVkContext) void {
        ctx.vkd.destroyImageView(ctx.dev, self.view, null);
    }
};

pub const NeonVkQueue = struct {
    handle: vk.Queue,
    family: u32,

    fn init(vkd: DeviceDispatch, dev: vk.Device, family: u32) @This() {
        return .{
            .handle = vkd.getDeviceQueue(dev, family, 0),
            .family = family,
        };
    }
};

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

pub const NeonVkPhysicalDeviceInfo = struct {
    physicalDevice: vk.PhysicalDevice,
    queueFamilyProperties: ArrayList(vk.QueueFamilyProperties),
    supportedExtensions: ArrayList(vk.ExtensionProperties),
    surfaceFormats: ArrayList(vk.SurfaceFormatKHR),
    presentModes: ArrayList(vk.PresentModeKHR),
    memoryProperties: vk.PhysicalDeviceMemoryProperties,
    deviceProperties: vk.PhysicalDeviceProperties,
    surfaceCapabilites: vk.SurfaceCapabilitiesKHR,

    pub fn enumerateFrom(
        vki: InstanceDispatch,
        pdevice: vk.PhysicalDevice,
        surface: vk.SurfaceKHR,
        allocator: std.mem.Allocator,
    ) !NeonVkPhysicalDeviceInfo {
        var self = NeonVkPhysicalDeviceInfo{
            .queueFamilyProperties = ArrayList(vk.QueueFamilyProperties).init(allocator),
            .supportedExtensions = ArrayList(vk.ExtensionProperties).init(allocator),
            .surfaceFormats = ArrayList(vk.SurfaceFormatKHR).init(allocator),
            .presentModes = ArrayList(vk.PresentModeKHR).init(allocator),
            .memoryProperties = undefined,
            .deviceProperties = undefined,
            .surfaceCapabilites = undefined,
            .physicalDevice = pdevice,
        };

        core.graphics_logs("=== Enumerating Device ===");

        var count: u32 = 0; // adding this for the vulkan two-step
        // load family properties
        vki.getPhysicalDeviceQueueFamilyProperties(pdevice, &count, null);
        core.graphics_log("  Found {d} family properties", .{count});
        if (count == 0)
            return error.NoPhysicalDeviceQueueFamilyProperties;
        try self.queueFamilyProperties.resize(@intCast(usize, count));
        vki.getPhysicalDeviceQueueFamilyProperties(pdevice, &count, self.queueFamilyProperties.items.ptr);

        // load supported extensions
        _ = try vki.enumerateDeviceExtensionProperties(pdevice, null, &count, null);
        core.graphics_log("  Found {d} extension properties", .{count});
        if (count > 0) {
            try self.queueFamilyProperties.resize(@intCast(usize, count));
            _ = try vki.enumerateDeviceExtensionProperties(pdevice, null, &count, self.supportedExtensions.items.ptr);
        }

        // load surface formats
        _ = try vki.getPhysicalDeviceSurfaceFormatsKHR(pdevice, surface, &count, null);
        core.graphics_log("  Found {d} surface formats", .{count});
        if (count > 0) {
            try self.surfaceFormats.resize(@intCast(usize, count));
            _ = try vki.getPhysicalDeviceSurfaceFormatsKHR(pdevice, surface, &count, self.surfaceFormats.items.ptr);
        }

        // load present modes
        _ = try vki.getPhysicalDeviceSurfacePresentModesKHR(pdevice, surface, &count, null);
        core.graphics_log("  Found {d} present modes", .{count});
        if (count > 0) {
            try self.presentModes.resize(@intCast(usize, count));
            _ = try vki.getPhysicalDeviceSurfacePresentModesKHR(pdevice, surface, &count, self.presentModes.items.ptr);
        }

        // load device properties
        self.deviceProperties = vki.getPhysicalDeviceProperties(pdevice);
        // load memory properties
        self.memoryProperties = vki.getPhysicalDeviceMemoryProperties(pdevice);
        // get surface capabilities
        self.surfaceCapabilites = try vki.getPhysicalDeviceSurfaceCapabilitiesKHR(pdevice, surface);

        return self;
    }

    pub fn deinit(self: *NeonVkPhysicalDeviceInfo) void {
        self.queueFamilyProperties.deinit();
        self.supportedExtensions.deinit();
        self.surfaceFormats.deinit();
        self.presentModes.deinit();
    }
};

pub const NeonVkContext = struct {
    const Self = @This();
    const NumFrames = vk_constants.NUM_FRAMES;

    const vertices = [_]Vertex{
        .{ .pos = .{ 0, -0.5 }, .color = .{ 1, 0, 0 } },
        .{ .pos = .{ 0.5, 0.5 }, .color = .{ 0, 1, 0 } },
        .{ .pos = .{ -0.5, 0.5 }, .color = .{ 0, 0, 1 } },
    };

    pub const maxNode = 2;
    mode: u32,

    // Quirks of the way the zig wrapper loads the functions for vulkan, means i gotta maintain these
    vkb: vk_constants.BaseDispatch,
    vki: vk_constants.InstanceDispatch,
    vkd: vk_constants.DeviceDispatch,

    instance: vk.Instance,
    surface: vk.SurfaceKHR,
    physicalDevice: vk.PhysicalDevice,
    physicalDeviceProperties: vk.PhysicalDeviceProperties,
    physicalDeviceMemoryProperties: vk.PhysicalDeviceMemoryProperties,

    enumeratedPhysicalDevices: ArrayList(NeonVkPhysicalDeviceInfo),

    graphicsFamilyIndex: u32,
    presentFamilyIndex: u32,

    dev: vk.Device,
    graphicsQueue: NeonVkQueue,
    presentQueue: NeonVkQueue,

    gpa: std.heap.GeneralPurposeAllocator(.{}),
    allocator: std.mem.Allocator,

    window: ?*c.GLFWwindow,
    windowName: [*c]const u8,
    extent: vk.Extent2D,
    actual_extent: vk.Extent2D,
    caps: vk.SurfaceCapabilitiesKHR,

    acquireSemaphores: ArrayList(vk.Semaphore),
    renderCompleteSemaphores: ArrayList(vk.Semaphore),
    extraSemaphore: vk.Semaphore,

    commandPool: vk.CommandPool,
    commandBuffers: ArrayList(vk.CommandBuffer),
    commandBufferFences: ArrayList(vk.Fence),
    renderPass: vk.RenderPass,

    surfaceFormat: vk.SurfaceFormatKHR,
    presentMode: vk.PresentModeKHR,
    swapchain: vk.SwapchainKHR,
    swapImages: ArrayList(NeonVkSwapImage),
    framebuffers: ArrayList(vk.Framebuffer),
    nextFrameIndex: u32,
    rendererTime: f64,

    depthFormat: vk.Format,

    static_triangle_pipeline: vk.Pipeline,
    static_colored_triangle_pipeline: vk.Pipeline,

    mesh_pipeline: vk.Pipeline,

    vmaFunctions: vma.VulkanFunctions,
    vmaAllocator: vma.Allocator,

    testMesh: meshes.Mesh,

    exitSignal: bool,

    pub fn create_object() !Self {
        var self: Self = undefined;

        try self.init_zig_data();
        try self.init_glfw();
        try self.init_api();
        try self.init_device();
        try self.init_command_pools();
        try self.init_command_buffers();
        try self.init_syncs();
        try self.init_vk_allocator();
        try self.init_or_recycle_swapchain();
        try self.init_vma();
        try self.init_rendertarget();
        try self.init_renderpasses();
        try self.init_framebuffers();

        try self.init_pipelines();
        try self.init_meshes();

        return self;
    }

    pub fn init_meshes(self: *Self) !void {
        self.testMesh = meshes.Mesh.init(self, self.allocator);
        try self.testMesh.vertices.resize(3);
        self.testMesh.vertices.items[0].position = .{ .x = 1.0, .y = 1.0, .z = 0.0 };
        self.testMesh.vertices.items[1].position = .{ .x = -1.0, .y = 1.0, .z = 0.0 };
        self.testMesh.vertices.items[2].position = .{ .x = 0.0, .y = -1.0, .z = 0.0 };

        self.testMesh.vertices.items[0].color = .{ .r = 1.0, .g = 1.0, .b = 0.0, .a = 1.0 }; //pure green
        self.testMesh.vertices.items[1].color = .{ .r = 0.0, .g = 1.0, .b = 1.0, .a = 1.0 }; //pure green
        self.testMesh.vertices.items[2].color = .{ .r = 1.0, .g = 0.0, .b = 1.0, .a = 1.0 }; //pure green

        self.testMesh.buffer = try self.upload_mesh(&self.testMesh);
    }

    pub fn upload_mesh(self: *Self, mesh: *meshes.Mesh) !NeonVkBuffer {
        const size = mesh.vertices.items.len * @sizeOf(meshes.Vertex);
        core.graphics_log("Uploading mesh size = {d} bytes {d} vertices", .{ size, mesh.vertices.items.len });
        var bci = vk.BufferCreateInfo{
            .flags = .{},
            .size = size,
            .usage = .{ .vertex_buffer_bit = true },
            .sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = undefined,
        };

        var vmaCreateInfo = vma.AllocationCreateInfo{
            .flags = .{},
            .usage = .cpuToGpu,
        };

        const results = try self.vmaAllocator.createBuffer(bci, vmaCreateInfo);

        var buffer = NeonVkBuffer{
            .buffer = results.buffer,
            .allocation = results.allocation,
        };

        const data = try self.vmaAllocator.mapMemory(buffer.allocation, u8);
        defer self.vmaAllocator.unmapMemory(buffer.allocation);

        @memcpy(data, @ptrCast([*]const u8, mesh.vertices.items.ptr), size);

        return buffer;
    }

    pub fn init_vma(self: *Self) !void {
        self.vmaFunctions = vma.VulkanFunctions.init(self.instance, self.dev, self.vkb.dispatch.vkGetInstanceProcAddr);

        self.vmaAllocator = try vma.Allocator.create(.{
            .instance = self.instance,
            .physicalDevice = self.physicalDevice,
            .device = self.dev,
            .frameInUseCount = NumFrames,
            .pVulkanFunctions = &self.vmaFunctions,
        });
    }

    pub fn init_pipelines(self: *Self) !void {
        var static_tri_builder = try NeonVkPipelineBuilder.init(
            self.dev,
            self.vkd,
            self.allocator,
            resources.triangle_vert_static.len,
            @ptrCast([*]const u32, resources.triangle_vert_static),
            resources.triangle_frag_static.len,
            @ptrCast([*]const u32, resources.triangle_frag_static),
        );
        try static_tri_builder.init_triangle_pipeline(self.actual_extent);
        self.static_triangle_pipeline = (try static_tri_builder.build(self.renderPass)).?;
        defer static_tri_builder.deinit();

        var colored_tri_b = try NeonVkPipelineBuilder.init(
            self.dev,
            self.vkd,
            self.allocator,
            resources.triangle_vert_colored.len,
            @ptrCast([*]const u32, resources.triangle_vert_colored),
            resources.triangle_frag_colored.len,
            @ptrCast([*]const u32, resources.triangle_frag_colored),
        );
        try colored_tri_b.init_triangle_pipeline(self.actual_extent);
        self.static_colored_triangle_pipeline = (try colored_tri_b.build(self.renderPass)).?;
        defer colored_tri_b.deinit();

        {
            core.graphics_logs("Creating mesh pipeline");
            var mesh_pipeline_b = try NeonVkPipelineBuilder.init(
                self.dev,
                self.vkd,
                self.allocator,
                resources.triangle_mesh_vert.len,
                @ptrCast([*]const u32, resources.triangle_mesh_vert),
                resources.triangle_mesh_frag.len,
                @ptrCast([*]const u32, resources.triangle_mesh_frag),
            );
            try mesh_pipeline_b.add_mesh_description();
            try mesh_pipeline_b.init_triangle_pipeline(self.actual_extent);
            self.mesh_pipeline = (try mesh_pipeline_b.build(self.renderPass)).?;
            defer mesh_pipeline_b.deinit();
        }
        core.graphics_logs("Finishing up pipeline creation");
    }

    pub fn shouldExit(self: Self) !bool {
        if (c.glfwWindowShouldClose(self.window) == c.GLFW_TRUE)
            return true;

        if (self.exitSignal)
            return true;

        return false;
    }

    pub fn getNextSwapImage(self: *Self) !u32 {
        var image_index = (try self.vkd.acquireNextImageKHR(
            self.dev,
            self.swapchain,
            1000000000,
            self.extraSemaphore,
            .null_handle,
        )).image_index;

        std.mem.swap(
            vk.Semaphore,
            &self.extraSemaphore,
            &self.acquireSemaphores.items[image_index],
        );
        return image_index;
    }

    pub fn pollRendererEvents(self: *Self) !void {
        _ = self;
    }

    fn updateTime(self: *Self, deltaTime: f64) void {
        self.rendererTime += deltaTime;
    }

    pub fn draw(self: *Self, deltaTime: f64) !void {
        self.updateTime(deltaTime);
        self.nextFrameIndex = try self.getNextSwapImage();

        _ = try self.vkd.waitForFences(self.dev, 1, @ptrCast([*]const vk.Fence, &self.commandBufferFences.items[self.nextFrameIndex]), 1, 1000000000);
        try self.vkd.resetFences(self.dev, 1, @ptrCast([*]const vk.Fence, &self.commandBufferFences.items[self.nextFrameIndex]));

        var cmd = self.commandBuffers.items[self.nextFrameIndex];
        try self.vkd.resetCommandBuffer(cmd, .{});

        var cbi = vk.CommandBufferBeginInfo{
            .p_inheritance_info = null,
            .flags = .{ .one_time_submit_bit = true },
        };
        try self.vkd.beginCommandBuffer(cmd, &cbi);

        var clearValue = vk.ClearValue{ .color = .{
            .float_32 = [4]f32{ 0.015, 0.015, 0.015, 1.0 },
        } };

        var rpbi = vk.RenderPassBeginInfo{
            .render_area = .{
                .extent = self.actual_extent,
                .offset = .{ .x = 0, .y = 0 },
            },
            .framebuffer = self.framebuffers.items[self.nextFrameIndex],
            .render_pass = self.renderPass,
            .clear_value_count = 1,
            .p_clear_values = @ptrCast([*]const vk.ClearValue, &clearValue),
        };

        self.vkd.cmdBeginRenderPass(cmd, &rpbi, .@"inline");

        if (self.mode == 0) {
            self.vkd.cmdBindPipeline(cmd, .graphics, self.mesh_pipeline);
            var offset: vk.DeviceSize = 0;
            self.vkd.cmdBindVertexBuffers(cmd, 0, 1, p2a(&self.testMesh.buffer.buffer), p2a(&offset));

            self.vkd.cmdDraw(cmd, @intCast(u32, self.testMesh.vertices.items.len), 1, 0, 0);
        } else if (self.mode == 1) {
            self.vkd.cmdBindPipeline(cmd, .graphics, self.static_triangle_pipeline);
            self.vkd.cmdDraw(cmd, 3, 1, 0, 0);
        } else if (self.mode == 2) {
            self.vkd.cmdBindPipeline(cmd, .graphics, self.static_colored_triangle_pipeline);
            self.vkd.cmdDraw(cmd, 3, 1, 0, 0);
        }

        self.vkd.cmdEndRenderPass(cmd);
        try self.vkd.endCommandBuffer(cmd);

        try self.finish_frame();
    }

    fn finish_frame(self: *Self) !void {
        var waitStage = vk.PipelineStageFlags{ .color_attachment_output_bit = true };

        var submit = vk.SubmitInfo{
            .p_wait_dst_stage_mask = @ptrCast([*]const vk.PipelineStageFlags, &waitStage),
            .wait_semaphore_count = 1,
            .p_wait_semaphores = @ptrCast([*]const vk.Semaphore, &self.acquireSemaphores.items[self.nextFrameIndex]),
            .signal_semaphore_count = 1,
            .p_signal_semaphores = @ptrCast([*]const vk.Semaphore, &self.renderCompleteSemaphores.items[self.nextFrameIndex]),
            .command_buffer_count = 1,
            .p_command_buffers = @ptrCast([*]const vk.CommandBuffer, &self.commandBuffers.items[self.nextFrameIndex]),
        };

        try self.vkd.queueSubmit(
            self.graphicsQueue.handle,
            1,
            @ptrCast([*]const vk.SubmitInfo, &submit),
            self.commandBufferFences.items[self.nextFrameIndex],
        );

        var presentInfo = vk.PresentInfoKHR{
            .p_swapchains = @ptrCast([*]const vk.SwapchainKHR, &self.swapchain),
            .swapchain_count = 1,
            .p_wait_semaphores = @ptrCast([*]const vk.Semaphore, &self.renderCompleteSemaphores.items[self.nextFrameIndex]),
            .wait_semaphore_count = 1,
            .p_image_indices = @ptrCast([*]const u32, &self.nextFrameIndex),
            .p_results = null,
        };

        var outOfDate: bool = false;
        _ = self.vkd.queuePresentKHR(self.graphicsQueue.handle, &presentInfo) catch |err| switch (err) {
            error.OutOfDateKHR => {
                outOfDate = true;
            },
            else => |narrow| return narrow,
        };

        var w: c_int = undefined;
        var h: c_int = undefined;
        c.glfwGetWindowSize(self.window, &w, &h);

        if (outOfDate or self.extent.width != @intCast(u32, w) or self.extent.height != @intCast(u32, h)) {
            self.extent = .{ .width = @intCast(u32, w), .height = @intCast(u32, h) };

            try self.vkd.deviceWaitIdle(self.dev);
            try self.destroy_framebuffers();

            try self.init_or_recycle_swapchain();
            try self.init_framebuffers();
        }

        c.glfwPollEvents();
    }

    fn destroy_framebuffers(self: *Self) !void {
        for (self.framebuffers.items) |framebuffer| {
            self.vkd.destroyFramebuffer(self.dev, framebuffer, null);
        }
        self.framebuffers.deinit();
        for (self.swapImages.items) |_, i| {
            self.swapImages.items[i].deinit(self);
        }
        self.swapImages.deinit();
    }

    fn init_vk_allocator(self: *Self) !void {
        _ = self;
    }

    fn init_framebuffers(self: *Self) !void {
        self.framebuffers = ArrayList(vk.Framebuffer).init(self.allocator);
        try self.framebuffers.resize(self.swapImages.items.len);

        var attachments = try self.allocator.alloc(vk.ImageView, 1);
        defer self.allocator.free(attachments);
        //attachments[1] = self.depthImage; // slot 0 is going to be the current image view, slot 1 is the depth image view

        var fbci = vk.FramebufferCreateInfo{
            .flags = .{},
            .render_pass = self.renderPass,
            .attachment_count = 1,
            .p_attachments = attachments.ptr,
            .width = self.actual_extent.width,
            .height = self.actual_extent.height,
            .layers = 1,
        };

        core.graphics_log("swapImages count = {d}", .{self.swapImages.items.len});

        for (self.swapImages.items) |image, i| {
            attachments[0] = image.view;
            debug_struct("fbci.p_attachment[0]", fbci.p_attachments[0]);
            self.framebuffers.items[i] = try self.vkd.createFramebuffer(self.dev, &fbci, null);
            core.graphics_logs("Created a framebuffer!");
        }
    }

    fn init_rendertarget(self: *Self) !void {
        var formats = [_]vk.Format{
            .d32_sfloat_s8_uint,
            .d24_unorm_s8_uint,
        };

        self.depthFormat = try self.find_supported_format(formats[0..], .optimal, .{ .depth_stencil_attachment_bit = true });
        core.graphics_log("created depth format: {any}", .{self.depthFormat});
    }

    fn init_renderpasses(self: *Self) !void {
        var attachments = ArrayList(vk.AttachmentDescription).init(self.allocator);
        defer attachments.deinit();

        // create color attachment
        var colorAttachment = vk.AttachmentDescription{
            .flags = .{},
            .format = self.surfaceFormat.format,
            .samples = .{ .@"1_bit" = true },
            .load_op = .clear,
            .store_op = .store,
            .stencil_load_op = .dont_care,
            .stencil_store_op = .dont_care,
            .initial_layout = .@"undefined",
            .final_layout = .present_src_khr,
        };

        var colorAttachmentRef = vk.AttachmentReference{
            .attachment = @intCast(u32, attachments.items.len),
            .layout = .color_attachment_optimal,
        };

        try attachments.append(colorAttachment);

        var depthAttachment = vk.AttachmentDescription{
            .flags = .{},
            .format = self.depthFormat,
            .samples = .{ .@"1_bit" = true },
            .load_op = .dont_care,
            .store_op = .dont_care,
            .stencil_load_op = .load, // equals to zero
            .stencil_store_op = .store, // equals to zero but we don't care
            .initial_layout = .@"undefined",
            .final_layout = .depth_stencil_attachment_optimal,
        };

        var depthAttachmentRef = vk.AttachmentReference{
            .attachment = @intCast(u32, attachments.items.len),
            .layout = .depth_stencil_attachment_optimal,
        };
        _ = depthAttachmentRef;
        try attachments.append(depthAttachment);

        var subpass = std.mem.zeroes(vk.SubpassDescription);
        subpass.flags = .{};
        subpass.pipeline_bind_point = .graphics;
        subpass.input_attachment_count = 0;
        subpass.color_attachment_count = 1;
        subpass.p_color_attachments = @ptrCast([*]const vk.AttachmentReference, &colorAttachmentRef);
        //subpass.p_depth_stencil_attachment = &depthAttachmentRef; // disable the depth attachment for now
        subpass.p_depth_stencil_attachment = null;

        var rpci = std.mem.zeroes(vk.RenderPassCreateInfo);
        rpci.s_type = .render_pass_create_info;
        rpci.flags = .{};
        rpci.attachment_count = @intCast(u32, attachments.items.len - 1);
        rpci.p_attachments = attachments.items.ptr;
        rpci.subpass_count = 1;
        rpci.p_subpasses = @ptrCast([*]const vk.SubpassDescription, &subpass);
        // debug_struct("rpci", rpci);

        self.renderPass = try self.vkd.createRenderPass(self.dev, &rpci, null);
    }

    pub fn find_supported_format(
        self: Self,
        formats: []vk.Format,
        imageTiling: vk.ImageTiling,
        features: vk.FormatFeatureFlags,
    ) !vk.Format {
        for (formats) |format| {
            var props = self.vki.getPhysicalDeviceFormatProperties(self.physicalDevice, format);
            if (imageTiling == .linear and (@bitCast(u32, props.linear_tiling_features) & @bitCast(u32, features)) == @bitCast(u32, features)) {
                return format;
            } else if (imageTiling == .optimal and (@bitCast(u32, props.optimal_tiling_features) & @bitCast(u32, features)) == @bitCast(u32, features)) {
                return format;
            }
        }

        return error.NoDefinedFormats;
    }

    fn find_actual_extent(self: *Self) !void {
        const caps = self.caps;
        const extent = self.extent;
        if (caps.current_extent.width != 0xFFFF_FFFF) {
            self.actual_extent = caps.current_extent;
        } else {
            self.actual_extent = .{
                .width = std.math.clamp(extent.width, caps.min_image_extent.width, caps.max_image_extent.width),
                .height = std.math.clamp(extent.height, caps.min_image_extent.height, caps.max_image_extent.height),
            };
        }
    }

    pub fn init_or_recycle_swapchain(self: *Self) !void {
        self.caps = try self.vki.getPhysicalDeviceSurfaceCapabilitiesKHR(self.physicalDevice, self.surface);

        try self.find_surface_format();
        debug_struct("selected surface format", self.surfaceFormat);

        try self.find_present_mode();
        debug_struct("selected present mode", self.presentMode);

        try self.find_actual_extent();
        debug_struct("actual extent", self.actual_extent);

        if (self.actual_extent.width == 0 or self.actual_extent.height == 0) {
            return error.InvalidSurfaceDimensions;
        }

        var image_count = @intCast(u32, NumFrames);
        if (self.caps.max_image_count > 0) {
            image_count = std.math.min(image_count, self.caps.max_image_count);
        }

        const qfi = [_]u32{ self.graphicsQueue.family, self.presentQueue.family };

        const sharing_mode: vk.SharingMode = if (self.graphicsQueue.family != self.presentQueue.family)
            .concurrent
        else
            .exclusive;

        var scci = vk.SwapchainCreateInfoKHR{
            .flags = .{},
            .surface = self.surface,
            .min_image_count = image_count,
            .image_format = self.surfaceFormat.format,
            .image_color_space = self.surfaceFormat.color_space,
            .image_extent = self.actual_extent,
            .image_array_layers = 1,
            .image_usage = .{ .color_attachment_bit = true, .transfer_dst_bit = true },
            .image_sharing_mode = sharing_mode,
            .queue_family_index_count = qfi.len,
            .p_queue_family_indices = &qfi,
            .pre_transform = self.caps.current_transform,
            .composite_alpha = .{ .opaque_bit_khr = true },
            .present_mode = self.presentMode,
            .clipped = vk.TRUE,
            .old_swapchain = self.swapchain,
        };

        var newSwapchain = try self.vkd.createSwapchainKHR(self.dev, &scci, null);
        errdefer self.vkd.destroySwapchainKHR(self.dev, newSwapchain, null);

        if (self.swapchain != .null_handle) {
            self.vkd.destroySwapchainKHR(self.dev, self.swapchain, null);
        }

        self.swapchain = newSwapchain;
        try self.create_swapchain_images_and_views();
    }

    fn create_swapchain_images_and_views(self: *Self) !void {
        self.swapImages = ArrayList(NeonVkSwapImage).init(self.allocator);

        var count: u32 = 0;
        _ = try self.vkd.getSwapchainImagesKHR(self.dev, self.swapchain, &count, null);
        if (count == 0) {
            core.engine_errs("No swap chain image found");
            return error.NoSwapchainImagesFound;
        }
        core.graphics_log("Creating {d} swap images", .{count});

        try self.swapImages.resize(count);
        const images = try self.allocator.alloc(vk.Image, count);
        defer self.allocator.free(images);

        _ = try self.vkd.getSwapchainImagesKHR(self.dev, self.swapchain, &count, images.ptr);

        for (core.count(NumFrames)) |_, i| {
            const image = images[i];

            var ivci = vk.ImageViewCreateInfo{
                .flags = .{},
                .image = image,
                .view_type = .@"2d",
                .format = self.surfaceFormat.format,
                .components = .{ .r = .r, .g = .g, .b = .b, .a = .a },
                .subresource_range = .{
                    .aspect_mask = .{
                        .color_bit = true,
                    },
                    .base_mip_level = 0,
                    .level_count = 1,
                    .base_array_layer = 0,
                    .layer_count = 1,
                },
            };

            var imageView = try self.vkd.createImageView(self.dev, &ivci, null);

            debug_struct("imageView", imageView);

            var swapImage = NeonVkSwapImage{
                .image = image,
                .view = imageView,
                .imageIndex = i,
            };

            self.swapImages.items[i] = swapImage;

            debug_struct("swapImage", swapImage);
            debug_struct("self.swapImages.items[i]", self.swapImages.items[i]);
        }
    }

    pub fn init_syncs(self: *Self) !void {
        self.acquireSemaphores = try ArrayList(vk.Semaphore).initCapacity(self.allocator, NumFrames);
        self.renderCompleteSemaphores = try ArrayList(vk.Semaphore).initCapacity(self.allocator, NumFrames);

        try self.acquireSemaphores.resize(NumFrames);
        try self.renderCompleteSemaphores.resize(NumFrames);

        var sci = vk.SemaphoreCreateInfo{
            .flags = .{},
        };

        for (core.count(NumFrames)) |_, i| {
            self.acquireSemaphores.items[i] = try self.vkd.createSemaphore(self.dev, &sci, null);
            self.renderCompleteSemaphores.items[i] = try self.vkd.createSemaphore(self.dev, &sci, null);
        }

        self.extraSemaphore = try self.vkd.createSemaphore(self.dev, &sci, null);
    }

    pub fn init_command_buffers(self: *Self) !void {
        self.commandBuffers = ArrayList(vk.CommandBuffer).init(self.allocator);
        self.commandBufferFences = ArrayList(vk.Fence).init(self.allocator);
        try self.commandBuffers.resize(NumFrames);
        try self.commandBufferFences.resize(NumFrames);

        var cbai = vk.CommandBufferAllocateInfo{
            .command_pool = self.commandPool,
            .level = vk.CommandBufferLevel.primary,
            .command_buffer_count = NumFrames,
        };

        try self.vkd.allocateCommandBuffers(self.dev, &cbai, self.commandBuffers.items.ptr);

        // then create fences for the command buffers
        var fci = vk.FenceCreateInfo{
            .flags = .{ .signaled_bit = true },
        };

        for (core.count(NumFrames)) |_, i| {
            self.commandBufferFences.items[i] = try self.vkd.createFence(self.dev, &fci, null);
        }
    }

    pub fn init_command_pools(self: *Self) !void {
        var cpci = vk.CommandPoolCreateInfo{ .flags = .{}, .queue_family_index = undefined };
        cpci.flags.reset_command_buffer_bit = true;
        cpci.queue_family_index = @intCast(u32, self.graphicsFamilyIndex);

        self.commandPool = try self.vkd.createCommandPool(self.dev, &cpci, null);
        errdefer self.vkd.destroyCommandPool(self.dev, pool, null);
    }

    pub fn init_zig_data(self: *Self) !void {
        self.gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self.allocator = std.heap.c_allocator;
        self.swapchain = .null_handle;
        self.nextFrameIndex = 0;
        self.rendererTime = 0;
        self.exitSignal = false;
        self.mode = 0;
    }

    pub fn init_api(self: *Self) !void {
        self.vkb = try BaseDispatch.load(c.glfwGetInstanceProcAddress);

        try self.create_vulkan_instance();
        errdefer self.vki.destroyInstance(self.instance, null);

        // create KHR surface structure
        try self.create_surface();
        errdefer self.vki.destroySurfaceKHR(self.instance, self.surface, null);
    }

    fn create_vulkan_instance(self: *Self) !void {
        var glfwExtensionsCount: u32 = 0;
        const glfwExtensions = c.glfwGetRequiredInstanceExtensions(&glfwExtensionsCount);

        if (glfwExtensionsCount > 0) {
            core.engine_logs("glfw has requested extensions:");
            var i: usize = 0;
            while (i < glfwExtensionsCount) : (i += 1) {
                var x = @ptrCast([*]const CStr, glfwExtensions);
                core.engine_log("  glfw_extension: {s}", .{x[i]});
            }
        }

        // Make a request for vulkan layers
        const ExtraLayers = [1]CStr{vk_constants.VK_KHRONOS_VALIDATION_LAYER_STRING};
        try self.check_required_vulkan_layers(ExtraLayers[0..]);

        // setup vulkan application info
        const appInfo = vk.ApplicationInfo{
            .p_application_name = self.windowName,
            .application_version = vk.makeApiVersion(0, 0, 0, 0),
            .p_engine_name = self.windowName,
            .engine_version = vk.makeApiVersion(0, 0, 0, 0),
            .api_version = vk.API_VERSION_1_2,
        };

        // instance create info struct
        const icis = vk.InstanceCreateInfo{
            .flags = .{},
            .p_application_info = &appInfo,
            .enabled_layer_count = 1,
            .pp_enabled_layer_names = @ptrCast([*]const [*:0]const u8, &ExtraLayers[0]),
            .enabled_extension_count = glfwExtensionsCount,
            .pp_enabled_extension_names = @ptrCast([*]const [*:0]const u8, glfwExtensions),
        };

        self.instance = try self.vkb.createInstance(&icis, null);

        // load vulkan per instance functions
        self.vki = try InstanceDispatch.load(self.instance, c.glfwGetInstanceProcAddress);
    }

    fn init_device(self: *Self) !void {
        try self.create_physical_devices();

        var ids = ArrayList(u32).init(self.allocator);
        defer ids.deinit();

        try core.AppendToArrayListUnique(&ids, @intCast(u32, self.graphicsFamilyIndex));
        try core.AppendToArrayListUnique(&ids, @intCast(u32, self.presentFamilyIndex));

        var createQueueInfoList = ArrayList(vk.DeviceQueueCreateInfo).init(self.allocator);
        defer createQueueInfoList.deinit();

        const priority = [_]f32{1.0};

        for (ids.items) |id| {
            try createQueueInfoList.append(.{
                .flags = .{},
                .queue_family_index = id,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            });
        }

        var desiredFeatures = vk.PhysicalDeviceFeatures{};
        desiredFeatures.texture_compression_bc = vk.TRUE;
        desiredFeatures.image_cube_array = vk.TRUE;
        desiredFeatures.depth_clamp = vk.TRUE;
        desiredFeatures.depth_bias_clamp = vk.TRUE;
        desiredFeatures.fill_mode_non_solid = vk.TRUE;

        var dci = vk.DeviceCreateInfo{
            .flags = .{},
            .queue_create_info_count = @intCast(u32, createQueueInfoList.items.len),
            .p_queue_create_infos = createQueueInfoList.items.ptr,
            .enabled_layer_count = 0,
            .pp_enabled_layer_names = undefined,
            .enabled_extension_count = @intCast(u32, required_device_extensions.len),
            .pp_enabled_extension_names = @ptrCast([*]const [*:0]const u8, &required_device_extensions),
            .p_enabled_features = &desiredFeatures,
        };

        dci.enabled_layer_count = vk_constants.required_device_layers.len;
        dci.pp_enabled_layer_names = @ptrCast([*]const [*:0]const u8, &vk_constants.required_device_layers);

        self.dev = try self.vki.createDevice(self.physicalDevice, &dci, null);

        self.vkd = try DeviceDispatch.load(self.dev, self.vki.dispatch.vkGetDeviceProcAddr);
        errdefer self.vkd.destroyDevice(self.dev, null);

        self.graphicsQueue = NeonVkQueue.init(self.vkd, self.dev, self.graphicsFamilyIndex);
        self.presentQueue = NeonVkQueue.init(self.vkd, self.dev, self.presentFamilyIndex);

        core.graphics_logs("Successfully created device");
    }

    fn create_physical_devices(self: *Self) !void {
        try self.enumerate_physical_devices();
        try self.find_physical_device();
    }

    fn find_physical_device(self: *Self) !void {
        for (self.enumeratedPhysicalDevices.items) |pDeviceInfo| {
            var graphicsID: isize = -1;
            var presentID: isize = -1;

            if (!try self.check_extension_support(pDeviceInfo))
                continue;

            if (pDeviceInfo.presentModes.items.len == 0)
                continue;

            if (pDeviceInfo.surfaceFormats.items.len == 0)
                continue;

            // look for queueFamilyProperties looking for both a graphics card and a present queue

            for (pDeviceInfo.queueFamilyProperties.items) |props, i| {
                if (props.queue_count == 0)
                    continue;

                if (props.queue_flags.graphics_bit) {
                    core.graphics_log("Found suitable graphics device with queue id: {d}", .{i});
                    graphicsID = @intCast(isize, i);
                    break;
                }
            }

            //  find the present queue family

            for (pDeviceInfo.queueFamilyProperties.items) |props, i| {
                if (props.queue_count == 0)
                    continue;

                var supportsPresent = try self.vki.getPhysicalDeviceSurfaceSupportKHR(pDeviceInfo.physicalDevice, @intCast(u32, i), self.surface);

                if (supportsPresent > 0) {
                    presentID = @intCast(isize, i);
                    break;
                }
            }

            if ((graphicsID != -1) and (presentID != -1)) {
                self.physicalDevice = pDeviceInfo.physicalDevice;
                self.physicalDeviceProperties = pDeviceInfo.deviceProperties;
                self.physicalDeviceMemoryProperties = pDeviceInfo.memoryProperties;
                self.graphicsFamilyIndex = @intCast(u32, graphicsID);
                self.presentFamilyIndex = @intCast(u32, presentID);
                core.graphics_log("Found graphics queue family with id {d} [ {d} available ]", .{ graphicsID, pDeviceInfo.queueFamilyProperties.items.len });
                core.graphics_log("Found present queue family with id {d} [ {d} available ]", .{ presentID, pDeviceInfo.queueFamilyProperties.items.len });
                debug_struct("selected physical device:", self.physicalDevice);
                return;
            }
        }

        core.engine_errs("Unable to find a physical device which fits.");
        return error.NoValidDevice;
    }

    fn check_extension_support(self: *Self, deviceInfo: NeonVkPhysicalDeviceInfo) !bool {
        var count: u32 = undefined;
        _ = try self.vki.enumerateDeviceExtensionProperties(deviceInfo.physicalDevice, null, &count, null);

        const extension_list = try self.allocator.alloc(vk.ExtensionProperties, count);
        defer self.allocator.free(extension_list);

        _ = try self.vki.enumerateDeviceExtensionProperties(deviceInfo.physicalDevice, null, &count, extension_list.ptr);

        for (required_device_extensions) |required_extension| {
            for (extension_list) |ext| {
                const len = std.mem.indexOfScalar(u8, &ext.extension_name, 0).?;
                const prop_ext_name = ext.extension_name[0..len];

                if (std.mem.eql(u8, std.mem.span(required_extension), prop_ext_name)) {
                    break;
                }
            } else {
                return false;
            }
        }

        return true;
    }

    fn check_surface_support(self: *Self, deviceInfo: NeonVkPhysicalDeviceInfo) !bool {
        _ = self;
        _ = deviceInfo;
        return true;
    }

    fn enumerate_physical_devices(self: *Self) !void {
        const vki = self.vki;
        var numDevices: u32 = 0;
        _ = try vki.enumeratePhysicalDevices(self.instance, &numDevices, null);

        if (numDevices == 0)
            return error.NoDevicesFound;

        const devices = try self.allocator.alloc(vk.PhysicalDevice, numDevices);
        defer self.allocator.free(devices);

        _ = try vki.enumeratePhysicalDevices(self.instance, &numDevices, devices.ptr);

        self.enumeratedPhysicalDevices = try ArrayList(NeonVkPhysicalDeviceInfo).initCapacity(self.allocator, @intCast(usize, numDevices));
        core.graphics_log("Enumerating {d} devices...", .{numDevices});
        var i: usize = 0;
        while (i < numDevices) : (i += 1) {
            self.enumeratedPhysicalDevices.appendAssumeCapacity(try NeonVkPhysicalDeviceInfo.enumerateFrom(
                self.vki,
                devices[i],
                self.surface,
                self.allocator,
            ));
        }
    }

    fn create_surface(self: *Self) !void {
        if (self.window == null)
            return error.WindowIsNullCantMakeSurface;

        if (c.glfwCreateWindowSurface(self.instance, self.window.?, null, &self.surface) != .success) {
            core.engine_errs("Unable to create glfw surface");
            return error.SurfaceInitFailed;
        }

        core.graphics_logs("Suraface creation completed!");
    }

    fn check_required_vulkan_layers(self: *Self, requiredNames: []const CStr) !void {
        var layers = try self.get_layer_extensions();
        defer self.allocator.free(layers);
        for (layers) |layer, i| {
            core.graphics_log("  {d}: Layer name: {s} \"{s}\"", .{
                i,
                core.buf_to_cstr(layer.layer_name),
                core.buf_to_cstr(layer.description),
            });
        }

        for (requiredNames) |requested| {
            var layerFound: bool = false;
            for (layers) |layer| {
                var layerName = core.buf_to_cstr(layer.layer_name);
                if (c.strcmp(layerName, core.buf_to_cstr(vk_constants.VK_KHRONOS_VALIDATION_LAYER_STRING)) == 0) {
                    layerFound = true;
                }
            }

            if (!layerFound) {
                core.graphics_log("Requested layer not supported: {s}", .{requested});
                return error.ValidationLayerRequestedNotAvailable;
            }
        }

        core.graphics_logs("All requested layers are available :)");
    }

    pub fn find_surface_format(self: *Self) !void {
        const preferred = vk.SurfaceFormatKHR{
            .format = .b8g8r8a8_srgb,
            .color_space = .srgb_nonlinear_khr,
        };

        var count: u32 = 0;

        _ = try self.vki.getPhysicalDeviceSurfaceFormatsKHR(self.physicalDevice, self.surface, &count, null);

        const surface_formats = try self.allocator.alloc(vk.SurfaceFormatKHR, count);
        defer self.allocator.free(surface_formats);

        _ = try self.vki.getPhysicalDeviceSurfaceFormatsKHR(self.physicalDevice, self.surface, &count, surface_formats.ptr);

        for (surface_formats) |sfmt| {
            if (std.meta.eql(sfmt, preferred)) {
                self.surfaceFormat = preferred;
                return;
            }
        }

        self.surfaceFormat = surface_formats[0];

        core.graphics_log("selected surface format\n   {any}", .{self.surfaceFormat});
    }

    pub fn find_present_mode(self: *Self) !void {
        var count: u32 = undefined;
        _ = try self.vki.getPhysicalDeviceSurfacePresentModesKHR(self.physicalDevice, self.surface, &count, null);
        const present_modes = try self.allocator.alloc(vk.PresentModeKHR, count);
        defer self.allocator.free(present_modes);
        _ = try self.vki.getPhysicalDeviceSurfacePresentModesKHR(self.physicalDevice, self.surface, &count, present_modes.ptr);

        const preferred = [_]vk.PresentModeKHR{
            .mailbox_khr,
            .immediate_khr,
        };

        for (preferred) |mode| {
            if (std.mem.indexOfScalar(vk.PresentModeKHR, present_modes, mode) != null) {
                self.presentMode = mode;
                break;
            }
        }

        self.presentMode = .fifo_khr;
    }

    pub fn get_layer_extensions(self: *Self) ![]const vk.LayerProperties {
        var count: u32 = 0;
        _ = try self.vkb.enumerateInstanceLayerProperties(&count, null);

        const data = try self.allocator.alloc(vk.LayerProperties, count);
        core.graphics_log("layers found : {d}", .{count});

        _ = try self.vkb.enumerateInstanceLayerProperties(&count, data.ptr);

        return data;
    }

    pub fn init_glfw(self: *Self) !void {
        core.engine_logs("initializing glfw");

        if (c.glfwInit() != c.GLFW_TRUE) {
            core.engine_logs("Glfw Init Failed");
            return error.GlfwInitFailed;
        }

        self.extent = .{ .width = 800, .height = 600 };
        self.windowName = "NeonWood Sample Application";

        c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);
        //c.glfwWindowHint(c.GLFW_DECORATED, c.GLFW_FALSE);

        self.window = c.glfwCreateWindow(
            @intCast(c_int, self.extent.width),
            @intCast(c_int, self.extent.height),
            self.windowName,
            null,
            null,
        ) orelse return error.WindowInitFailed;
        var h: c_int = -1;
        var w: c_int = -1;
        var comp: c_int = -1;
        var pixels: ?*u8 = core.stbi_load("assets/icon.png", &w, &h, &comp, core.STBI_rgb_alpha);
        var iconImage = c.GLFWimage{
            .width = w,
            .height = h,
            .pixels = pixels,
        };
        debug_struct("loaded image: ", iconImage);
        _ = comp;
        c.glfwSetWindowIcon(self.window, 1, &iconImage);
        defer core.stbi_image_free(pixels);

        _ = c.glfwSetKeyCallback(self.window, neon_glfw_input_callback);
    }

    pub fn destroy_syncs(self: *Self) !void {
        for (self.acquireSemaphores.items) |x| {
            self.vkd.destroySemaphore(self.dev, x, null);
        }

        for (self.renderCompleteSemaphores.items) |x| {
            self.vkd.destroySemaphore(self.dev, x, null);
        }
        self.vkd.destroySemaphore(self.dev, self.extraSemaphore, null);
        self.acquireSemaphores.deinit();
        self.renderCompleteSemaphores.deinit();

        for (self.commandBufferFences.items) |x| {
            self.vkd.destroyFence(self.dev, x, null);
        }
        self.commandBufferFences.deinit();
    }

    pub fn destroy_pipelines(self: *Self) !void {
        self.vkd.destroyPipeline(self.dev, self.static_triangle_pipeline, null);
        self.vkd.destroyPipeline(self.dev, self.static_colored_triangle_pipeline, null);
        self.vkd.destroyPipeline(self.dev, self.mesh_pipeline, null);
    }

    pub fn destroy_renderpass(self: *Self) !void {
        self.vkd.destroyRenderPass(self.dev, self.renderPass, null);
    }

    pub fn destroy_meshes(self: *Self) !void {
        self.testMesh.deinit(self.vmaAllocator);
    }

    pub fn deinit(self: *Self) void {
        self.vkd.deviceWaitIdle(self.dev) catch unreachable;

        self.destroy_pipelines() catch unreachable;
        self.destroy_renderpass() catch unreachable;
        self.destroy_syncs() catch unreachable;
        self.destroy_meshes() catch unreachable;
        self.destroy_framebuffers() catch unreachable;

        self.vmaAllocator.destroy();

        self.vkd.destroyCommandPool(self.dev, self.commandPool, null);
        self.vkd.destroyDevice(self.dev, null);
        self.vki.destroySurfaceKHR(self.instance, self.surface, null);
        self.vki.destroyInstance(self.instance, null);
    }
};

pub var gContext: *NeonVkContext = undefined;

pub fn neon_glfw_input_callback(
    window: ?*c.GLFWwindow,
    key: c_int,
    scancode: c_int,
    action: c_int,
    mods: c_int,
) callconv(.C) void {
    _ = window;
    _ = key;
    _ = scancode;
    _ = action;
    _ = mods;

    if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS) {
        core.engine_logs("Escape key pressed, everything dies now");
        gContext.exitSignal = true;
    }

    if (key == c.GLFW_KEY_D and action == c.GLFW_PRESS) {
        gContext.mode = (gContext.mode + 1) % 3;
    }
}
