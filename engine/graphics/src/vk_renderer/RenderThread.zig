// API dispatch functions
const vkd = vk_api.vkd;
const vki = vk_api.vki;
const vkb = vk_api.vkb;

exitSignal: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
exitConfirmed: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
// allocators
allocator: std.mem.Allocator,
vkAllocator: *NeonVkAllocator,

// device information and api handles
dev: vk.Device,
pdev: vk.PhysicalDevice,
pdevProperties: vk.PhysicalDeviceProperties,
caps: vk.SurfaceCapabilitiesKHR,
cmdPool: vk.CommandPool,
minUniformBufferAlignment: usize,

// current extent of the window (raw values from platform)
extent: vk.Extent2D,

graphicsQueue: NeonVkQueue,
presentQueue: NeonVkQueue,
frameData: [NumFrames]NeonVkFrameData,

displayTarget: DisplayTarget,

// frame data to upload to gpu
framesInFlight: std.atomic.Value(u32),

sharedData: [NumFrames]SharedData = undefined,

actual_extent: vk.Extent2D = undefined,
commandBuffers: [NumFrames]vk.CommandBuffer = undefined,
frameSync: [NumFrames]FrameSyncs = undefined,

// acquireNextFrame will prime an already allocated semaphore at the same time it
// returns an index.
// with triple buffering we can't garutee which index will be acquired next.
// and we can't risk acquiring a semaphore that is already in flight.
// therefore this extraSemaphore shall act as an empty spot in the semaphore queue
emptyAcquireSemaphore: vk.Semaphore = undefined,

// main renderpass information
renderPass: vk.RenderPass,
sceneParameterBuffer: NeonVkBuffer,
maxObjectCount: u32,

pub const ObjectSharedData = struct {
    visibility: bool,
    textureSet: vk.DescriptorSet,
    pipeline: vk.Pipeline,
    pipelineLayout: vk.PipelineLayout,
    mesh: vk.Buffer,
    vertexCount: u32,
};

pub const SharedData = struct {
    lock: std.Thread.Mutex,
    cameraData: vk_renderer_camera_gpu.NeonVkCameraDataGpu,
    sceneData: NeonVkSceneDataGpu,
    models: std.ArrayList(NeonVkObjectDataGpu) = .{},
    objectData: std.ArrayList(ObjectSharedData) = .{},
};

const DisplayTarget = struct {
    surface: vk.SurfaceKHR,
    surfaceFormat: vk.SurfaceFormatKHR,
    presentMode: vk.PresentModeKHR,
    depthFormat: vk.Format,

    depthImage: NeonVkImage = undefined,
    depthImageView: vk.ImageView = undefined,
    scissor: vk.Rect2D = undefined,
    viewport: vk.Viewport = undefined,
    swapchain: vk.SwapchainKHR = .null_handle,
    swapImages: []NeonVkSwapImage = undefined,
    framebuffers: []vk.Framebuffer = undefined,

    pub fn deinit(self: *@This(), rt: *RenderThread) void {
        for (self.swapImages) |*swapImage| {
            swapImage.deinit(vkd.*, rt.dev);
        }
        rt.allocator.free(self.swapImages);

        for (self.framebuffers) |fb| {
            vkd.destroyFramebuffer(rt.dev, fb, null);
        }
        rt.allocator.free(self.framebuffers);

        vkd.destroySwapchainKHR(rt.dev, self.swapchain, null);

        vkd.destroyImageView(rt.dev, self.depthImageView, null);
        self.depthImage.deinit(rt.vkAllocator);
    }
};

// all the high level synchronization required for a frame
// task to be done with this engine
const FrameSyncs = struct {
    // semaphore = resource dependency specification
    // barrier = command and data flow completion specification
    // fence = notification to host side

    acquire: vk.Semaphore,
    renderComplete: vk.Semaphore,
    cmdFence: vk.Fence,

    pub fn deinit(self: *@This(), dev: vk.Device) void {
        vkd.destroySemaphore(dev, self.acquire, null);
        vkd.destroySemaphore(dev, self.renderComplete, null);
        vkd.destroyFence(dev, self.cmdFence, null);
    }
};

pub fn setup(self: *@This()) !void {
    self.actual_extent = try vk_swapchain_helpers.findActualExtent(self.extent, self.caps);
    try self.createSyncs();
    try self.initCommandBuffers();
    try self.initOrRecycleSwapchain();
    try self.initFramebuffers();
    try self.initShared();
}

fn deinitExtras(self: *@This()) void {
    _ = self;
}

pub fn onExitSignal(self: *@This()) void {
    self.exitSignal.store(true, .seq_cst);
}

fn destroySyncs(self: *@This()) void {
    for (&self.frameSync) |*frameSync| {
        frameSync.deinit(self.dev);
    }
    vkd.destroySemaphore(self.dev, self.emptyAcquireSemaphore, null);
}

fn deinitCommandBuffers(self: *@This()) void {
    // no-op
    _ = self;
}

fn deinitSwapchain(_: *@This()) void {}

fn deinitShared(self: *@This()) void {
    for (&self.sharedData) |*s| {
        s.models.deinit();
        s.objectData.deinit();
    }
}

fn processExitSignal(self: *@This()) void {
    var z1 = tracy.ZoneN(@src(), "RT - destruction");
    defer z1.End();

    core.engine_logs("Process Exit Signal");

    self.deinitShared();
    self.destroySyncs();
    self.deinitCommandBuffers();
    self.displayTarget.deinit(self);
    self.deinitExtras();

    self.exitConfirmed.store(true, .seq_cst);
}

pub fn acquireNextFrame(self: *@This()) !u32 {
    var z1 = tracy.ZoneNC(@src(), "Waiting for frame", 0x111111);
    defer z1.End();

    while (self.framesInFlight.load(.seq_cst) >= maxFramesInFlight()) {}

    const nextFrameIndex = try self.getNextSwapImage();

    _ = try vkd.waitForFences(
        self.dev,
        1,
        @as([*]const vk.Fence, @ptrCast(&self.frameSync[nextFrameIndex].cmdFence)),
        1,
        vk_constants.FrameTimeout,
    );
    try vkd.resetFences(self.dev, 1, @as([*]const vk.Fence, @ptrCast(&self.frameSync[nextFrameIndex].cmdFence)));
    return nextFrameIndex;
}

// can be called from any thread.
// queues up a render job for the next frame
pub fn dispatchNextFrame(self: *@This(), deltaTime: f64, frameIndex: u32) !void {
    var z2 = tracy.ZoneN(@src(), "rendering job request");
    defer z2.End();

    if (self.exitSignal.load(.seq_cst)) {
        if (self.framesInFlight.load(.acquire) > 0) {
            return;
        }

        try vkd.deviceWaitIdle(self.dev);
        self.processExitSignal();
        return;
    }

    const L = struct {
        r: *RenderThread,
        dt: f64,
        frameIndex: u32,

        pub fn func(ctx: *@This(), _: *core.JobContext) void {
            ctx.r.draw(ctx.dt, ctx.frameIndex) catch unreachable;
            // ctx.r.dynamicMeshManager.finishUpload() catch unreachable;
            // lets think about this one later.
            _ = ctx.r.framesInFlight.fetchSub(1, .seq_cst);
        }
    };

    _ = self.framesInFlight.fetchAdd(1, .seq_cst);

    try core.dispatchJob(L{
        .r = self,
        .dt = deltaTime,
        .frameIndex = frameIndex,
    });
}

pub fn getFrameData(self: *@This(), index: u32) *NeonVkFrameData {
    return &self.frameData[index];
}

pub fn getShared(self: *@This(), index: u32) *SharedData {
    return &self.sharedData[index];
}

pub fn pad_uniform_buffer_size(self: @This(), originalSize: usize) usize {
    const alignment = @as(usize, @intCast(self.pdevProperties.limits.min_uniform_buffer_offset_alignment));

    var alignedSize: usize = originalSize;
    if (alignment > 0) {
        alignedSize = (alignedSize + alignment - 1) & ~(alignment - 1);
    }

    return alignedSize;
}

pub fn renderMeshes(self: *@This(), cmd: vk.CommandBuffer, fi: u32) void {
    const shared = self.getShared(fi);

    const offset: vk.DeviceSize = 0;
    const paddedSceneSize = @as(u32, @intCast(self.pad_uniform_buffer_size(@sizeOf(NeonVkSceneDataGpu))));
    const startOffset: u32 = paddedSceneSize * fi;

    const frameData = self.getFrameData(fi);

    for (shared.objectData.items, 0..) |object, i| {
        const pipeline = object.pipeline;
        const layout = object.pipelineLayout;
        const mesh = object.mesh;
        const textureSet = object.textureSet;
        const vertexCount = object.vertexCount;

        vkd.cmdBindPipeline(cmd, .graphics, pipeline);
        vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 0, 1, @ptrCast(&frameData.globalDescriptorSet), 1, @ptrCast(&startOffset));
        vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 1, 1, @ptrCast(&frameData.objectDescriptorSet), 0, undefined);
        vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 2, 1, @ptrCast(&textureSet), 0, undefined);
        vkd.cmdBindVertexBuffers(cmd, 0, 1, @ptrCast(&mesh), @ptrCast(&offset));

        vkd.cmdDraw(cmd, vertexCount, 1, 0, @intCast(i));
    }
}

// fi = frameIndex
pub fn draw(self: *@This(), deltaTime: f64, fi: u32) !void {
    _ = deltaTime;

    try self.preFrameUpdate(fi);
    const cmd = try self.startFrameCommands(fi);
    var z = tracy.ZoneNC(@src(), "Main RenderPass", 0x00FF1111);
    try self.beginMainRenderpass(cmd, fi);

    self.renderMeshes(cmd, fi);

    try self.finishMainRenderpass(cmd, fi);
    z.End();
    try vkd.endCommandBuffer(cmd);
    try self.finishFrame(fi);
}

fn finishMainRenderpass(self: *@This(), cmd: vk.CommandBuffer, fi: u32) !void {
    _ = self;
    _ = fi;
    vkd.cmdEndRenderPass(cmd);
}

fn preFrameUpdate(self: *@This(), fi: u32) !void {

    // upload camera data
    const shared = self.getShared(fi);
    shared.lock.lock();
    defer shared.lock.unlock();

    {
        const data = try self.vkAllocator.vmaAllocator.mapMemory(self.frameData[fi].cameraBuffer.allocation, u8);
        shared.cameraData.upload(data);
        self.vkAllocator.vmaAllocator.unmapMemory(self.frameData[fi].cameraBuffer.allocation);
    }

    // upload scene global data
    {
        const paddedSceneSize = self.padUniformBufferSize(@sizeOf(NeonVkSceneDataGpu));
        const startOffset = paddedSceneSize * fi;
        const data = try self.vkAllocator.vmaAllocator.mapMemory(self.sceneParameterBuffer.allocation, u8);

        var dataSlice: []u8 = undefined;
        dataSlice.ptr = data + startOffset;
        dataSlice.len = @sizeOf(@TypeOf(shared.sceneData));

        var inputSlice: []const u8 = undefined;
        inputSlice.ptr = @as([*]const u8, @ptrCast(&shared.sceneData));
        inputSlice.len = dataSlice.len;

        @memcpy(dataSlice, inputSlice);

        self.vkAllocator.vmaAllocator.unmapMemory(self.sceneParameterBuffer.allocation);
    }

    try self.uploadObjectData(shared, fi);
}

fn uploadObjectData(self: *@This(), shared: *SharedData, fi: u32) !void {
    var z1 = tracy.ZoneN(@src(), "uploading ssbo data");
    defer z1.End();
    const allocation = self.frameData[fi].objectBuffer.allocation;
    const data = try self.vkAllocator.vmaAllocator.mapMemory(allocation, NeonVkObjectDataGpu);
    var ssbo: []NeonVkObjectDataGpu = undefined;
    ssbo.ptr = @as([*]NeonVkObjectDataGpu, @ptrCast(data));
    ssbo.len = self.maxObjectCount;

    for (shared.models.items, 0..) |model, i| {
        ssbo[i] = model;
    }

    // var i: usize = 0;
    // while (i < self.maxobjectcount and i < self.renderobjectset.dense.len) : (i += 1) {
    //     const object = self.renderobjectset.dense.items(.renderobject)[i];
    //     if (object.mesh != null) {
    //         ssbo[i].modelmatrix = self.renderobjectset.dense.items(.renderobject)[i].transform;
    //     }
    // }

    // unmapping every frame might actually be quite unessecary.
    self.vkAllocator.vmaAllocator.unmapMemory(allocation);
}

fn padUniformBufferSize(self: @This(), originalSize: usize) usize {
    var alignedSize: usize = originalSize;
    if (self.minUniformBufferAlignment > 0) {
        alignedSize = (alignedSize + self.minUniformBufferAlignment - 1) & ~(self.minUniformBufferAlignment - 1);
    }

    return alignedSize;
}

fn startFrameCommands(self: *@This(), fi: u32) !vk.CommandBuffer {
    const cmd = self.commandBuffers[fi];

    try vkd.resetCommandBuffer(cmd, .{});

    var cbi = vk.CommandBufferBeginInfo{
        .p_inheritance_info = null,
        .flags = .{ .one_time_submit_bit = true },
    };

    try vkd.beginCommandBuffer(cmd, &cbi);

    return cmd;
}

fn beginMainRenderpass(self: *@This(), cmd: vk.CommandBuffer, fi: u32) !void {
    var z = tracy.ZoneNC(@src(), "Begin RenderPass", 0xFFBBBB);
    defer z.End();

    var clearValues = [2]vk.ClearValue{
        .{
            .color = .{ .float_32 = [4]f32{ 0.005, 0.005, 0.005, 1.0 } },
        },
        .{
            .depth_stencil = .{
                .depth = 1.0,
                .stencil = 0.0,
            },
        },
    };

    var rpbi = vk.RenderPassBeginInfo{
        .render_area = .{
            .extent = self.actual_extent,
            .offset = .{ .x = 0, .y = 0 },
        },
        .framebuffer = self.displayTarget.framebuffers[fi],
        .render_pass = self.renderPass,
        .clear_value_count = 2,
        .p_clear_values = @as([*]const vk.ClearValue, @ptrCast(&clearValues)),
    };

    vkd.cmdBeginRenderPass(cmd, &rpbi, .@"inline");

    vkd.cmdSetViewport(cmd, 0, 1, @ptrCast(&self.displayTarget.viewport));
    vkd.cmdSetScissor(cmd, 0, 1, @ptrCast(&self.displayTarget.scissor));
}

fn finishFrame(self: *@This(), frameIndex: u32) !void {
    var waitStage = vk.PipelineStageFlags{ .color_attachment_output_bit = true };

    var submit = vk.SubmitInfo{
        .p_wait_dst_stage_mask = @as([*]const vk.PipelineStageFlags, @ptrCast(&waitStage)),
        .wait_semaphore_count = 1,
        .p_wait_semaphores = @as([*]const vk.Semaphore, @ptrCast(&self.frameSync[frameIndex].acquire)),
        .signal_semaphore_count = 1,
        .p_signal_semaphores = @as([*]const vk.Semaphore, @ptrCast(&self.frameSync[frameIndex].renderComplete)),
        .command_buffer_count = 1,
        .p_command_buffers = @as([*]const vk.CommandBuffer, @ptrCast(&self.commandBuffers[frameIndex])),
    };

    try vkd.queueSubmit(
        self.graphicsQueue.handle,
        1,
        @as([*]const vk.SubmitInfo, @ptrCast(&submit)),
        self.frameSync[frameIndex].cmdFence,
    );

    var presentInfo = vk.PresentInfoKHR{
        .p_swapchains = @as([*]const vk.SwapchainKHR, @ptrCast(&self.displayTarget.swapchain)),
        .swapchain_count = 1,
        //.p_wait_semaphores = @as([*]const vk.Semaphore, @ptrCast(&self.renderCompleteSemaphores.items[frameIndex])),
        .p_wait_semaphores = @as([*]const vk.Semaphore, @ptrCast(&self.frameSync[frameIndex].renderComplete)),
        .wait_semaphore_count = 1,
        .p_image_indices = @as([*]const u32, @ptrCast(&frameIndex)),
        .p_results = null,
    };

    // todo re-implement handling out of date KHR
    var outOfDate: bool = false;
    _ = vkd.queuePresentKHR(self.graphicsQueue.handle, &presentInfo) catch |err| switch (err) {
        error.OutOfDateKHR => {
            outOfDate = true;
        },
        else => |narrow| return narrow,
    };
}

fn getNextSwapImage(self: *@This()) !u32 {
    const imageIndex = (try vkd.acquireNextImageKHR(
        self.dev,
        self.displayTarget.swapchain,
        1000000000,
        self.emptyAcquireSemaphore,
        .null_handle,
    )).image_index;

    // load the newly primed semaphore for the acquire operation into the next slot
    std.mem.swap(
        vk.Semaphore,
        &self.emptyAcquireSemaphore,
        &self.frameSync[imageIndex].acquire,
    );

    return imageIndex;
}

// -- initSyncs --
fn createSyncs(self: *@This()) !void {
    const semaphoreCreateInfo = vk.SemaphoreCreateInfo{
        .flags = .{},
    };

    var fci = vk.FenceCreateInfo{
        .flags = .{ .signaled_bit = true },
    };

    for (0..NumFrames) |i| {
        self.frameSync[i].acquire = try vkd.createSemaphore(self.dev, &semaphoreCreateInfo, null);
        self.frameSync[i].renderComplete = try vkd.createSemaphore(self.dev, &semaphoreCreateInfo, null);
        self.frameSync[i].cmdFence = try vkd.createFence(self.dev, &fci, null);
    }

    self.emptyAcquireSemaphore = try vkd.createSemaphore(self.dev, &semaphoreCreateInfo, null);
}

// -- init command buffers --
fn initCommandBuffers(self: *@This()) !void {
    var cbai = vk.CommandBufferAllocateInfo{
        .command_pool = self.cmdPool,
        .level = vk.CommandBufferLevel.primary,
        .command_buffer_count = NumFrames,
    };
    try vkd.allocateCommandBuffers(self.dev, &cbai, &self.commandBuffers);
}

// -- Swapchain initialization --
fn initOrRecycleSwapchain(self: *@This()) !void {
    self.caps = try vki.getPhysicalDeviceSurfaceCapabilitiesKHR(self.pdev, self.displayTarget.surface);

    self.displayTarget.presentMode = try vk_swapchain_helpers.findPresentMode(self.allocator, self.pdev, self.displayTarget.surface);

    self.actual_extent = try vk_swapchain_helpers.findActualExtent(self.extent, self.caps);

    if (self.actual_extent.width == 0 or self.actual_extent.height == 0) {
        return error.InvalidSurfaceDimensions;
    }

    var image_count = @as(u32, @intCast(NumFrames));
    if (self.caps.max_image_count > 0) {
        image_count = @min(image_count, self.caps.max_image_count);
    }

    const qfi = [_]u32{ self.graphicsQueue.family, self.presentQueue.family };

    const sharing_mode: vk.SharingMode = if (self.graphicsQueue.family != self.presentQueue.family)
        .concurrent
    else
        .exclusive;

    var scci = vk.SwapchainCreateInfoKHR{
        .flags = .{},
        .surface = self.displayTarget.surface,
        .min_image_count = image_count,
        .image_format = self.displayTarget.surfaceFormat.format,
        .image_color_space = self.displayTarget.surfaceFormat.color_space,
        .image_extent = self.actual_extent,
        .image_array_layers = 1,
        .image_usage = .{ .color_attachment_bit = true, .transfer_dst_bit = true },
        .image_sharing_mode = sharing_mode,
        .queue_family_index_count = qfi.len,
        .p_queue_family_indices = &qfi,
        .pre_transform = self.caps.current_transform,
        .composite_alpha = .{ .opaque_bit_khr = true },
        .present_mode = self.displayTarget.presentMode,
        .clipped = vk.TRUE,
        .old_swapchain = self.displayTarget.swapchain,
    };

    const newSwapchain = try vkd.createSwapchainKHR(self.dev, &scci, null);
    errdefer vkd.destroySwapchainKHR(self.dev, newSwapchain, null);

    if (self.displayTarget.swapchain != .null_handle) {
        vkd.destroySwapchainKHR(self.dev, self.displayTarget.swapchain, null);
    }

    self.displayTarget.swapchain = newSwapchain;
    try self.createSwapchainImagesAndViews();

    self.displayTarget.viewport = vk.Viewport{
        .x = 0,
        .y = 0,
        .width = @as(f32, @floatFromInt(self.actual_extent.width)),
        .height = @as(f32, @floatFromInt(self.actual_extent.height)),
        .min_depth = 0.0,
        .max_depth = 1.0,
    };

    self.displayTarget.scissor = .{
        .offset = .{ .x = 0, .y = 0 },
        .extent = self.actual_extent,
    };
}

fn createSwapchainImagesAndViews(self: *@This()) !void {
    var count: u32 = 0;
    _ = try vkd.getSwapchainImagesKHR(self.dev, self.displayTarget.swapchain, &count, null);
    if (count == 0) {
        core.engine_errs("No swap chain image found");
        return error.NoSwapchainImagesFound;
    }
    core.graphics_log("Creating {d} swap images", .{count});
    self.displayTarget.swapImages = try self.allocator.alloc(NeonVkSwapImage, count);

    const images = try self.allocator.alloc(vk.Image, count);
    defer self.allocator.free(images);

    _ = try vkd.getSwapchainImagesKHR(self.dev, self.displayTarget.swapchain, &count, images.ptr);

    for (0..NumFrames) |i| {
        const image = images[i];

        var ivci = vk.ImageViewCreateInfo{
            .flags = .{},
            .image = image,
            .view_type = .@"2d",
            .format = self.displayTarget.surfaceFormat.format,
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

        const imageView = try vkd.createImageView(self.dev, &ivci, null);

        const swapImage = NeonVkSwapImage{
            .image = image,
            .view = imageView,
            .imageIndex = i,
        };

        self.displayTarget.swapImages[i] = swapImage;
    }

    const depthImageExtent = vk.Extent3D{
        .width = self.actual_extent.width,
        .height = self.actual_extent.height,
        .depth = 1,
    };

    const dimg_ici = vk.ImageCreateInfo{
        .flags = .{},
        .sharing_mode = .exclusive,
        .queue_family_index_count = 0,
        .p_queue_family_indices = undefined,
        .initial_layout = .undefined,
        .image_type = .@"2d",
        .format = self.displayTarget.depthFormat,
        .extent = depthImageExtent,
        .mip_levels = 1,
        .array_layers = 1,
        .samples = .{
            .@"1_bit" = true,
        },
        .tiling = .optimal,
        .usage = .{ .depth_stencil_attachment_bit = true },
    };

    const dimg_aci = vma.AllocationCreateInfo{
        .requiredFlags = .{
            .device_local_bit = true,
        },
        .usage = .gpuOnly,
    };

    self.displayTarget.depthImage = try self.vkAllocator.createImage(dimg_ici, dimg_aci, @src().fn_name ++ " depth Image");

    var imageViewCreate = vk.ImageViewCreateInfo{
        .flags = .{},
        .image = self.displayTarget.depthImage.image,
        .view_type = .@"2d",
        .format = self.displayTarget.depthFormat,
        .components = .{ .r = .identity, .g = .identity, .b = .identity, .a = .identity },
        .subresource_range = .{
            .aspect_mask = .{
                .depth_bit = true,
            },
            .base_mip_level = 0,
            .level_count = 1,
            .base_array_layer = 0,
            .layer_count = 1,
        },
    };

    self.displayTarget.depthImageView = try vkd.createImageView(self.dev, &imageViewCreate, null);
}

fn initShared(self: *@This()) !void {
    for (&self.sharedData) |*s| {
        s.lock = .{};
        s.models = std.ArrayList(NeonVkObjectDataGpu).init(self.allocator);
        s.objectData = std.ArrayList(ObjectSharedData).init(self.allocator);
    }
}

// init framebuffers
fn initFramebuffers(self: *@This()) !void {
    self.displayTarget.framebuffers = try self.allocator.alloc(vk.Framebuffer, self.getImageCount());

    var attachments: [2]vk.ImageView = undefined;

    var fbci = vk.FramebufferCreateInfo{
        .flags = .{},
        .render_pass = self.renderPass,
        .attachment_count = 2,
        .p_attachments = &attachments,
        .width = self.actual_extent.width,
        .height = self.actual_extent.height,
        .layers = 1,
    };

    for (self.displayTarget.swapImages, 0..) |image, i| {
        attachments[0] = image.view;
        attachments[1] = self.displayTarget.depthImageView;
        self.displayTarget.framebuffers[i] = try vkd.createFramebuffer(self.dev, &fbci, null);
    }
}

inline fn getImageCount(self: @This()) usize {
    return self.displayTarget.swapImages.len;
}

inline fn maxFramesInFlight() u32 {
    return 1;
}

const RenderThread = @This();
const std = @import("std");
const vk = @import("vulkan");
const core = @import("core");
const platform = @import("platform");
const vma = @import("vma");
const tracy = core.tracy;

const vk_api = @import("../vk_api.zig");
const vk_constants = @import("../vk_constants.zig");
const vk_allocator = @import("../vk_allocator.zig");
const render_objects = @import("../render_objects.zig");

const vk_renderer_types = @import("vk_renderer_types.zig");
const vk_swapchain_helpers = @import("vk_swapchain_helpers.zig");
const vk_renderer_camera_gpu = @import("vk_renderer_camera_gpu.zig");

const NeonVkAllocator = vk_allocator.NeonVkAllocator;
const NeonVkBuffer = vk_allocator.NeonVkBuffer;
const NeonVkImage = vk_allocator.NeonVkImage;

const NumFrames = vk_constants.NUM_FRAMES;

const NeonVkQueue = vk_renderer_types.NeonVkQueue;
const NeonVkSwapImage = vk_renderer_types.NeonVkSwapImage;
const NeonVkFrameData = vk_renderer_types.NeonVkFrameData;
const NeonVkSceneDataGpu = vk_renderer_types.NeonVkSceneDataGpu;
const NeonVkObjectDataGpu = vk_renderer_types.NeonVkObjectDataGpu;
const NeonVkSwapchain = vk_renderer_types.NeonVkSwapchain;

// todo and documentation
//
// This struct is the root of the feature to have a seperate rendering thread for handling all vulkan IOs
// the way this will work is, instead of having all processing done on the main systems thread.
// the systems thread will send over a set of data required to render each given frame.
// this data is called sharedData.
//
// all plugins into the renderer will follow this arrangement as well.
// this includes the dynamicMeshManager and anything else.
// they will all have a similar setup to this.
//
