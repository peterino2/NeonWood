const std = @import("std");
const vk = @import("vulkan");

const triangle_mesh_vert = @import("triangle_mesh_vert");
const default_lit = @import("default_lit");

pub const c = @import("c.zig");
const memory = @import("../memory.zig");
const graphics = @import("../graphics.zig");
const vma = @import("vma");
const core = @import("../core.zig");
const assets = @import("../assets.zig");
const tracy = core.tracy;
const vk_constants = @import("vk_constants.zig");
const vk_assetLoaders = @import("vk_assetLoaders.zig");
const vk_pipeline = @import("vk_pipeline.zig");
pub const NeonVkPipelineBuilder = vk_pipeline.NeonVkPipelineBuilder;
const mesh = @import("mesh.zig");
const render_objects = @import("render_object.zig");
const vkinit = @import("vk_init.zig");
const vk_utils = @import("vk_utils.zig");
const texture = @import("texture.zig");
const materials = @import("materials.zig");
const build_opts = @import("game_build_opts");
const platform = @import("../platform.zig");
const vk_allocator = @import("vk_allocator.zig");
const vk_renderer_interface = @import("vk_renderer/vk_renderer_interface.zig");
pub usingnamespace @import("vk_renderer/vk_renderer_interface.zig");

const vk_renderer_camera_gpu = @import("vk_renderer/vk_renderer_camera_gpu.zig");
const NeonVkCameraDataGpu = vk_renderer_camera_gpu.NeonVkCameraDataGpu;

const RendererInterface = vk_renderer_interface.RendererInterface;
const RendererInterfaceRef = vk_renderer_interface.RendererInterfaceRef;

const NeonVkAllocator = vk_allocator.NeonVkAllocator;
const RingQueue = core.RingQueue;

const force_mailbox: bool = build_opts.force_mailbox;
const NeonVkSceneManager = @import("vk_sceneobject.zig").NeonVkSceneManager;

const SparseSet = core.SparseSet;
const MAX_OBJECTS = vk_constants.MAX_OBJECTS;

pub const NeonVkBuffer = vk_allocator.NeonVkBuffer;
pub const NeonVkImage = vk_allocator.NeonVkImage;

fn vkCast(comptime T: type, handle: anytype) T {
    return @as(T, @ptrCast(@as(?*anyopaque, @ptrFromInt(@as(usize, @intCast(@intFromEnum(handle)))))));
}

const ObjectHandle = core.ObjectHandle;

// Aliases
const Vector4f = core.Vector4f;
const Vectorf = core.Vectorf;
const Vector2 = core.Vector2;
const Vector2f = core.Vector2f;
const Quat = core.Quat;
const Mat = core.Mat;
const mul = core.zm.mul;
const Name = core.Name;
const Transform = core.Transform;
const EulerAngles = core.EulerAngles;

const DeviceDispatch = vk_constants.DeviceDispatch;
const BaseDispatch = vk_constants.BaseDispatch;
const InstanceDispatch = vk_constants.InstanceDispatch;

const RenderObject = render_objects.RenderObject;
const Material = materials.Material;
const Mesh = mesh.Mesh;
const Texture = texture.Texture;

const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const CStr = core.CStr;

const RenderObjectSet = core.SparseMultiSet(
    struct { renderObject: RenderObject },
);

const NeonVkUploadContext = vk_utils.NeonVkUploadContext;

pub const NeonVkSceneDataGpu = struct {
    fogColor: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    fogDistances: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    ambientColor: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    sunlightDirection: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    sunlightColor: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
};

pub const NeonVkFrameData = struct {
    // descriptors
    globalDescriptorSet: vk.DescriptorSet,
    objectDescriptorSet: vk.DescriptorSet,
    spriteDescriptorSet: vk.DescriptorSet,

    // buffers
    spriteBuffer: NeonVkBuffer,
    objectBuffer: NeonVkBuffer,
    cameraBuffer: NeonVkBuffer,
};

pub const NeonVkObjectDataGpu = struct {
    modelMatrix: Mat,
};

pub const CreateRenderObjectParams = struct {
    mesh_name: Name,
    material_name: Name,
    init_transform: Transform = core.zm.identity(),
};

const debug_struct = core.debug_struct;

const NeonVkMeshPushConstant = vk_pipeline.NeonVkMeshPushConstant;
const required_device_extensions = [_]CStr{
    vk.extension_info.khr_swapchain.name,
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

        // load device properties
        self.deviceProperties = vki.getPhysicalDeviceProperties(pdevice);
        core.graphics_log(" device Name: {s}", .{@as([*:0]u8, @ptrCast(&self.deviceProperties.device_name))});

        core.graphics_log("  Found {d} family properties", .{count});
        if (count == 0)
            return error.NoPhysicalDeviceQueueFamilyProperties;
        try self.queueFamilyProperties.resize(@as(usize, @intCast(count)));
        vki.getPhysicalDeviceQueueFamilyProperties(pdevice, &count, self.queueFamilyProperties.items.ptr);

        // load supported extensions
        _ = try vki.enumerateDeviceExtensionProperties(pdevice, null, &count, null);
        core.graphics_log("  Found {d} extension properties", .{count});
        if (count > 0) {
            try self.supportedExtensions.resize(@as(usize, @intCast(count)));
            _ = try vki.enumerateDeviceExtensionProperties(pdevice, null, &count, self.supportedExtensions.items.ptr);
        }

        // load surface formats
        _ = try vki.getPhysicalDeviceSurfaceFormatsKHR(pdevice, surface, &count, null);
        core.graphics_log("  Found {d} surface formats", .{count});
        if (count > 0) {
            try self.surfaceFormats.resize(@as(usize, @intCast(count)));
            _ = try vki.getPhysicalDeviceSurfaceFormatsKHR(pdevice, surface, &count, self.surfaceFormats.items.ptr);
        }

        // load present modes
        _ = try vki.getPhysicalDeviceSurfacePresentModesKHR(pdevice, surface, &count, null);
        core.graphics_log("  Found {d} present modes", .{count});
        if (count > 0) {
            try self.presentModes.resize(@as(usize, @intCast(count)));
            _ = try vki.getPhysicalDeviceSurfacePresentModesKHR(pdevice, surface, &count, self.presentModes.items.ptr);
        }

        // load memory properties
        self.memoryProperties = vki.getPhysicalDeviceMemoryProperties(pdevice);
        // get surface capabilit00eies
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

pub const DestructionLambda = struct {
    func: *const fn (self: *NeonVkContext, ctx: ?*anyopaque) void,
    ctx: ?*anyopaque,

    pub fn exec(self: @This(), gc: *NeonVkContext) void {
        self.func(gc, self.ctx);
    }
};

pub const NeonVkContext = struct {
    const Self = @This();
    const NumFrames = vk_constants.NUM_FRAMES;
    pub var NeonObjectTable: core.RttiData = core.RttiData.from(Self);

    pub const maxMode = 3;

    const descriptorPoolSizes = [_]vk.DescriptorPoolSize{
        .{ .type = .uniform_buffer, .descriptor_count = 1000 },
        .{ .type = .uniform_buffer_dynamic, .descriptor_count = 1000 },
        .{ .type = .storage_buffer, .descriptor_count = 1000 },
        .{ .type = .combined_image_sampler, .descriptor_count = 1000 },
    };

    mode: u32,

    graph: core.FileLog,

    // Quirks of the way the zig wrapper loads the functions for vulkan, means i gotta maintain these
    vkb: vk_constants.BaseDispatch,
    vki: vk_constants.InstanceDispatch,
    vkd: vk_constants.DeviceDispatch,

    outstandingJobsCount: std.atomic.Atomic(u32),

    instance: vk.Instance,
    surface: vk.SurfaceKHR,
    physicalDevice: vk.PhysicalDevice,
    physicalDeviceProperties: vk.PhysicalDeviceProperties,
    physicalDeviceMemoryProperties: vk.PhysicalDeviceMemoryProperties,

    maxObjectCount: u32 = MAX_OBJECTS,

    enumeratedPhysicalDevices: ArrayList(NeonVkPhysicalDeviceInfo),
    showDemo: bool,

    graphicsFamilyIndex: u32,
    presentFamilyIndex: u32,

    dev: vk.Device,
    graphicsQueue: NeonVkQueue,
    presentQueue: NeonVkQueue,

    allocator: std.mem.Allocator,

    extent: vk.Extent2D,
    actual_extent: vk.Extent2D,
    scissor: vk.Rect2D,
    viewport: vk.Viewport,
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
    depthImage: NeonVkImage,
    depthImageView: vk.ImageView,

    vmaFunctions: vma.VulkanFunctions,
    // vmaAllocator: vma.Allocator,
    vkAllocator: *NeonVkAllocator,

    exitSignal: bool,
    firstFrame: bool,
    shouldResize: bool,
    isMinimized: bool,

    renderObjectsAreDirty: bool,
    cameraMovement: Vectorf,

    renderObjectsByMaterial: ArrayListUnmanaged(u32),
    renderObjectSet: RenderObjectSet,

    textureSets: std.AutoHashMapUnmanaged(u32, vk.DescriptorSet),

    materials: std.AutoHashMapUnmanaged(u32, *Material),
    meshes: std.AutoHashMapUnmanaged(u32, *Mesh),
    textures: std.AutoHashMapUnmanaged(u32, *Texture),
    cameraRef: ?*render_objects.Camera,

    deferredTextureDestroy: std.ArrayListUnmanaged(*Texture),
    deferredDescriptorsDestroy: std.ArrayListUnmanaged(vk.DescriptorSet),

    requiredExtensions: ArrayListUnmanaged(CStr),

    blockySampler: vk.Sampler,
    linearSampler: vk.Sampler,

    descriptorPool: vk.DescriptorPool,
    globalDescriptorLayout: vk.DescriptorSetLayout,
    objectDescriptorLayout: vk.DescriptorSetLayout,

    frameData: [NumFrames]NeonVkFrameData,
    lastMaterial: ?*Material,
    lastMesh: ?*Mesh,
    lastTextureSet: ?vk.DescriptorSet,

    sceneDataGpu: NeonVkSceneDataGpu,
    sceneParameterBuffer: NeonVkBuffer,
    rendererPlugins: ArrayListUnmanaged(RendererInterfaceRef),

    singleTextureSetLayout: vk.DescriptorSetLayout,
    sceneManager: NeonVkSceneManager,
    dynamicMeshManager: *mesh.DynamicMeshManager,
    shouldShowDebug: bool,
    platformInstance: *platform.PlatformInstance,
    uploader: vk_utils.NeonVkUploader,
    vulkanValidation: bool,

    msaaSettings: enum { none, msaa_2x, msaa_4x, msaa_8x, msaa_16x },

    destructionQueue: ArrayListUnmanaged(DestructionLambda),

    pub fn setRenderObjectMesh(self: *@This(), objectHandle: core.ObjectHandle, meshName: core.Name) void {
        var meshRef = self.meshes.get(meshName.handle()).?;
        self.renderObjectSet.get(objectHandle, .renderObject).?.*.mesh = meshRef;
        self.renderObjectSet.get(objectHandle, .renderObject).?.*.meshName = meshName;
    }

    pub fn setRenderObjectTexture(self: *@This(), objectHandle: core.ObjectHandle, textureName: core.Name) void {
        var textureSet = self.textureSets.get(textureName.handle()).?;
        self.renderObjectSet.get(objectHandle, .renderObject).?.texture = textureSet;
    }

    pub fn getNormRayFromActiveCamera(
        self: *@This(),
        camera: *const render_objects.Camera,
        screenPos: core.Vector2,
    ) core.Rayf {
        // this is completely wrong right now.
        var ray = core.Rayf{
            .start = core.Vectorf.new(0, 0, 0),
            .dir = core.Vectorf.new(0, 0, 0),
        };

        var s = core.Vector2f{
            .x = @as(f32, @floatCast(screenPos.x)),
            .y = @as(f32, @floatCast(screenPos.y)),
        };

        if (self.actual_extent.width == 0 or self.actual_extent.height == 0) {
            return ray;
        }

        const i = core.zm.inverse(camera.projection);
        const iview = core.zm.inverse(camera.transform);
        const width = (@as(f32, @floatFromInt(self.actual_extent.width)));
        const height = (@as(f32, @floatFromInt(self.actual_extent.height)));

        const sx = core.clamp(s.x, 0, width);
        const sy = core.clamp(s.y, 0, height);

        const vec = core.Vectorf{
            .x = ((2.0 / width) * sx) - 1.0,
            .y = ((2.0 / height) * sy) - 1.0,
            .z = 1.0,
        };
        //var zmvec = vec.toZm();

        var eye = core.Vectorf.fromZm(core.zm.mul(i, vec.toZm()));
        eye.z = -1;
        var iworld = core.zm.mul(iview, eye.toZm());
        iworld = core.zm.normalize4(iworld);
        iworld = core.zm.mul(core.zm.matFromQuat(camera.rotation), iworld);
        iworld = core.zm.mul(core.zm.matFromQuat(camera.rotation), iworld);
        ray.dir = core.Vectorf.fromZm(iworld).normalize();
        ray.start = camera.position;

        return ray;
    }

    pub fn activateCamera(self: *Self, camera: *render_objects.Camera) void {
        self.cameraRef = camera;
    }

    pub fn setObjectVisibility(self: *Self, handle: core.ObjectHandle, visible: bool) void {
        self.renderObjectSet.get(handle, .renderObject).?.*.visibility = visible;
    }

    pub fn init_zig_data(self: *Self, allocator: std.mem.Allocator) !void {
        core.graphics_log("NeonVkContext StaticSize = {d} bytes", .{@sizeOf(Self)});
        self.allocator = allocator;
        self.swapchain = .null_handle;
        self.nextFrameIndex = 0;
        self.rendererTime = 0;
        self.exitSignal = false;
        self.shouldShowDebug = false;
        self.mode = 0;
        self.firstFrame = true;
        self.textureSets = .{};
        self.rendererPlugins = .{};
        self.isMinimized = false;
        self.textures = .{};
        self.meshes = .{};
        self.materials = .{};
        self.deferredTextureDestroy = .{};
        self.deferredDescriptorsDestroy = .{};
        self.lastMaterial = null;
        self.cameraRef = null;
        self.maxObjectCount = gGraphicsStartupSettings.maxObjectCount;
        self.lastMesh = null;
        self.showDemo = true;
        self.renderObjectsByMaterial = .{};
        self.destructionQueue = .{};
        self.renderObjectSet = RenderObjectSet.init(self.allocator);
        self.sceneManager = NeonVkSceneManager.init(self.allocator);
        self.requiredExtensions = .{};

        for (required_device_extensions) |required| {
            try self.requiredExtensions.append(self.allocator, required);
        }

        self.outstandingJobsCount = std.atomic.Atomic(u32).init(0);

        self.platformInstance = platform.getInstance();
    }

    pub fn add_plugin(self: *Self, interface: RendererInterfaceRef) !void {
        try self.rendererPlugins.append(interface);
    }

    pub fn start_upload_context(self: *Self, context: *NeonVkUploadContext) !void {
        context.mutex.lock();
        var cmd = context.commandBuffer;
        var cbi = vkinit.commandBufferBeginInfo(.{ .one_time_submit_bit = true });
        try self.vkd.beginCommandBuffer(cmd, &cbi);

        context.active = true;
    }

    pub fn finish_upload_context(self: *Self, context: *NeonVkUploadContext) !void {
        try self.vkd.endCommandBuffer(context.commandBuffer);
        var submit = vkinit.submitInfo(&context.commandBuffer);
        try self.vkd.queueSubmit(
            self.graphicsQueue.handle,
            1,
            @as([*]const vk.SubmitInfo, @ptrCast(&submit)),
            context.uploadFence,
        );

        var z1 = tracy.ZoneN(@src(), "waiting for upload fence to complete");
        _ = try self.vkd.waitForFences(
            self.dev,
            1,
            @as([*]const vk.Fence, @ptrCast(&context.uploadFence)),
            1,
            1000000000,
        );
        z1.End();
        try self.vkd.resetFences(self.dev, 1, @as([*]const vk.Fence, @ptrCast(&context.uploadFence)));
        context.active = false; //  replace this thing with a lock
        context.mutex.unlock();
    }

    pub fn pad_uniform_buffer_size(self: Self, originalSize: usize) usize {
        var alignment = @as(usize, @intCast(self.physicalDeviceProperties.limits.min_uniform_buffer_offset_alignment));

        var alignedSize: usize = originalSize;
        if (alignment > 0) {
            alignedSize = (alignedSize + alignment - 1) & ~(alignment - 1);
        }

        return alignedSize;
    }

    pub fn init(allocator: std.mem.Allocator) !*Self {
        core.graphics_log("validation_layers: {any}", .{gGraphicsStartupSettings.vulkanValidation});
        core.graphics_log("release_build: {any}", .{build_opts.release_build});
        return create_object(allocator) catch unreachable;
    }

    pub fn pushDestruction(self: *@This(), comptime L: type, ctx: ?*anyopaque) !void {
        try self.destructionQueue.append(self.allocator, .{ .func = L.func, .ctx = ctx });
    }

    // this is the old version
    pub fn create_object(allocator: std.mem.Allocator) !*Self {
        var self: *Self = try allocator.create(Self);
        self.vulkanValidation = gGraphicsStartupSettings.vulkanValidation;
        try self.init_zig_data(allocator);

        try self.pushDestruction(struct {
            pub fn func(s: *NeonVkContext, ctx: ?*anyopaque) void {
                _ = ctx;
                _ = s;
                core.engine_logs("destruction finished");
            }
        }, null);

        self.graph = try core.FileLog.init(allocator);
        try self.graph.write("digraph G {{\n", .{});

        try self.graph.write("  root->init_api\n", .{});
        try self.init_api();

        try self.graph.write("  root->init_device\n", .{});
        try self.init_device();

        try self.graph.write("  root->init_vma\n", .{});
        try self.init_vma();

        try self.graph.write("  root->init_command_pools\n", .{});
        try self.init_command_pools();

        // command buffer initialization
        try self.graph.write("  root->init_command_buffers\n", .{});
        try self.init_command_buffers();

        try self.graph.write("  root->init_syncs\n", .{});
        try self.init_syncs();

        try self.graph.write("  root->init_or_recycle_swapchain\n", .{});
        try self.init_or_recycle_swapchain();

        try self.graph.write("  root->init_rendertarget\n", .{});
        try self.init_rendertarget();

        try self.graph.write("  root->init_renderpasses\n", .{});
        try self.init_renderpasses();

        try self.graph.write("  root->init_framebuffers\n", .{});
        try self.init_framebuffers();

        // resource initialization
        try self.init_uploader();
        try self.graph.write("  root->init_descriptors\n", .{});
        try self.init_descriptors();

        try self.graph.write("  root->init_texture_descriptor\n", .{});
        try self.init_texture_descriptor();

        try self.graph.write("  root->load_core_textures\n", .{});
        try self.load_core_textures();

        try self.graph.write("  root->init_pipelines\n", .{});
        try self.init_pipelines();

        try self.graph.write("  root->init_primitive_meshes\n", .{});
        try self.init_primitive_meshes();
        try self.create_white_material(.{ .x = 128, .y = 128 });

        try self.graph.write("}}\n", .{});
        try self.graph.writeOut("renderer_graph.viz");

        return self;
    }

    pub fn postInit(self: *@This()) core.RttiDataEventError!void {
        self.init_dynamic_mesh() catch return core.RttiDataEventError.UnknownStatePanic;
    }

    pub fn init_uploader(self: *@This()) !void {
        self.uploader = try vk_utils.NeonVkUploader.init(self);
    }

    pub fn init_dynamic_mesh(self: *@This()) !void {
        self.dynamicMeshManager = try mesh.DynamicMeshManager.init(self);
    }

    pub fn upload_texture_from_file(self: *@This(), texturePath: []const u8) !*Texture {
        var stagingResults = try vk_utils.load_and_stage_image_from_file(self, texturePath);
        defer stagingResults.stagingBuffer.deinit(self.vkAllocator);
        try vk_utils.submit_copy_from_staging(self, stagingResults.stagingBuffer, stagingResults.image, stagingResults.mipLevel);
        var image = stagingResults.image;

        var imageViewCreate = vkinit.imageViewCreateInfo(
            .r8g8b8a8_srgb,
            image.image,
            .{ .color_bit = true },
            stagingResults.mipLevel,
        );

        imageViewCreate.subresource_range.level_count = stagingResults.mipLevel;
        var imageView = try self.vkd.createImageView(self.dev, &imageViewCreate, null);
        var newTexture = try self.allocator.create(Texture);

        newTexture.* = Texture{
            .image = image,
            .imageView = imageView,
        };

        return newTexture;
    }

    pub fn create_mesh_image_for_texture(self: *@This(), inTexture: *Texture, params: struct { useBlocky: bool = true }) !vk.DescriptorSet {
        // var textureSet = try self.allocator.create(vk.DescriptorSet);
        var textureSet: vk.DescriptorSet = undefined;
        var allocInfo = vk.DescriptorSetAllocateInfo{
            .descriptor_pool = self.descriptorPool,
            .descriptor_set_count = 1,
            .p_set_layouts = @ptrCast(&self.singleTextureSetLayout),
        };

        try self.vkd.allocateDescriptorSets(self.dev, &allocInfo, @as([*]vk.DescriptorSet, @ptrCast(&textureSet)));

        var imageBufferInfo = vk.DescriptorImageInfo{
            //.sampler = self.blockySampler,
            .sampler = if (params.useBlocky) self.blockySampler else self.linearSampler,
            .image_view = inTexture.imageView,
            .image_layout = .shader_read_only_optimal,
        };

        var writeDescriptorSet = vkinit.writeDescriptorImage(
            .combined_image_sampler,
            textureSet,
            &imageBufferInfo,
            0,
        );

        self.vkd.updateDescriptorSets(self.dev, 1, @ptrCast(&writeDescriptorSet), 0, undefined);

        return textureSet;
    }

    pub fn destroyDeferredDestroyTextures(self: *@This()) void {
        for (self.deferredDescriptorsDestroy.items) |descriptor| {
            self.vkd.freeDescriptorSets(self.dev, self.descriptorPool, 1, @ptrCast(&descriptor)) catch {
                core.engine_errs("unable to free descriptor pool");
            };
        }

        for (self.deferredTextureDestroy.items) |tex| {
            tex.deinit(self);
            self.allocator.destroy(tex);
        }

        self.deferredDescriptorsDestroy.clearRetainingCapacity();
        self.deferredTextureDestroy.clearRetainingCapacity();
    }

    pub fn install_texture_into_registry(self: *@This(), name: core.Name, textureRef: *Texture, textureSet: vk.DescriptorSet) !void {
        try self.textures.put(self.allocator, name.handle(), textureRef);
        try self.textureSets.put(self.allocator, name.handle(), textureSet);
    }

    const PixelBufferRGBA8 = @import("PixelBufferRGBA8.zig");

    pub fn updateTextureFromPixelsSync(
        self: *@This(),
        textureToUpdate: core.Name,
        pixelBuffer: PixelBufferRGBA8,
        useBlockySampler: bool,
    ) !void {
        core.asserts(
            pixelBuffer.pixels.len == pixelBuffer.extent.x * pixelBuffer.extent.y * 4,
            "invalid pixel buffer length (expected:{d}, got:{d})",
            .{
                pixelBuffer.pixels.len,
                pixelBuffer.extent.x * pixelBuffer.extent.y,
            },
            @src().fn_name,
        );

        // todo, defer this texture's destruction by 2 frames.
        try self.deferredTextureDestroy.append(self.allocator, self.textures.get(textureToUpdate.handle()).?);
        try self.deferredDescriptorsDestroy.append(self.allocator, self.textureSets.get(textureToUpdate.handle()).?);
        var results = try vk_utils.createTextureFromPixels(pixelBuffer.pixels, pixelBuffer.extent, self, useBlockySampler);

        try self.textures.put(self.allocator, textureToUpdate.handle(), results.texture);
        try self.textureSets.put(self.allocator, textureToUpdate.handle(), results.descriptor);
    }

    pub fn create_standard_texture_from_file(self: *Self, textureName: core.Name, texturePath: []const u8) !*Texture {
        var newTexture = try self.upload_texture_from_file(texturePath);
        try self.textures.put(self.allocator, textureName.handle(), newTexture);
        return self.textures.getEntry(textureName.handle()).?.value_ptr.*;
    }

    pub fn load_core_textures(self: *Self) !void {
        _ = try self.create_standard_texture_from_file(core.MakeName("missing_texture"), "content/textures/texture_sample.png");
    }

    pub fn init_texture_descriptor(self: *Self) !void {
        var textureBinding = vkinit.descriptorSetLayoutBinding(.combined_image_sampler, .{ .fragment_bit = true }, 0);

        var singleTextureInfo = vk.DescriptorSetLayoutCreateInfo{
            .binding_count = 1,
            .flags = .{},
            .p_bindings = @ptrCast(&textureBinding),
        };
        self.singleTextureSetLayout = try self.vkd.createDescriptorSetLayout(self.dev, &singleTextureInfo, null);
    }

    pub fn init_descriptors(self: *Self) !void {
        var poolInfo = vk.DescriptorPoolCreateInfo{
            .flags = .{
                .free_descriptor_set_bit = true,
            },
            .max_sets = 100,
            .pool_size_count = @as(u32, @intCast(descriptorPoolSizes.len)),
            .p_pool_sizes = &descriptorPoolSizes,
        };

        self.descriptorPool = try self.vkd.createDescriptorPool(self.dev, &poolInfo, null);

        var cameraBufferBinding = vkinit.descriptorSetLayoutBinding(.uniform_buffer, .{ .vertex_bit = true, .fragment_bit = true }, 0);
        var sceneBinding = vkinit.descriptorSetLayoutBinding(.uniform_buffer_dynamic, .{ .vertex_bit = true, .fragment_bit = true }, 1);
        var bindings = [_]@TypeOf(sceneBinding){ cameraBufferBinding, sceneBinding };

        var setInfo = vk.DescriptorSetLayoutCreateInfo{
            .binding_count = 2,
            .flags = .{},
            .p_bindings = @as([*]const @TypeOf(sceneBinding), @ptrCast(&bindings)),
        };

        var objectBinding = vkinit.descriptorSetLayoutBinding(.storage_buffer, .{ .vertex_bit = true }, 0);
        var objectBindings = [_]@TypeOf(objectBinding){objectBinding};

        var objectSetInfo = vk.DescriptorSetLayoutCreateInfo{
            .binding_count = 1,
            .flags = .{},
            .p_bindings = @as([*]const @TypeOf(objectBinding), @ptrCast(&objectBindings)),
        };

        self.globalDescriptorLayout = try self.vkd.createDescriptorSetLayout(self.dev, &setInfo, null);
        self.objectDescriptorLayout = try self.vkd.createDescriptorSetLayout(self.dev, &objectSetInfo, null);

        const paddedSceneSize = self.pad_uniform_buffer_size(@sizeOf(NeonVkSceneDataGpu));
        core.graphics_log("padded scene size = {d}", .{paddedSceneSize});

        const sceneParamBufferSize = NumFrames * paddedSceneSize;
        core.graphics_log("NumFrames = {d}", .{NumFrames});

        self.sceneParameterBuffer = try self.create_buffer(
            sceneParamBufferSize,
            .{ .uniform_buffer_bit = true },
            .cpuToGpu,
            "Scene Parameter Buffer",
        );

        for (core.count(NumFrames), 0..) |_, i| {
            // detail the object descriptor set
            self.frameData[i].objectBuffer = try self.create_buffer(
                @sizeOf(NeonVkObjectDataGpu) * self.maxObjectCount,
                .{ .storage_buffer_bit = true },
                .cpuToGpu,
                "framedata object ssbo",
            );

            var objectDescriptorSetAllocInfo = vk.DescriptorSetAllocateInfo{
                .descriptor_pool = self.descriptorPool,
                .descriptor_set_count = 1,
                .p_set_layouts = @ptrCast(&self.objectDescriptorLayout),
            };

            try self.vkd.allocateDescriptorSets(self.dev, &objectDescriptorSetAllocInfo, @as([*]vk.DescriptorSet, @ptrCast(&self.frameData[i].objectDescriptorSet)));

            var objectInfo = vk.DescriptorBufferInfo{
                .buffer = self.frameData[i].objectBuffer.buffer,
                .offset = 0,
                .range = @sizeOf(NeonVkObjectDataGpu) * self.maxObjectCount,
            };

            var objectWrite = vkinit.writeDescriptorSet(
                .storage_buffer,
                self.frameData[i].objectDescriptorSet,
                &objectInfo,
                0,
            );

            var objectSetWrites = [_]@TypeOf(objectWrite){objectWrite};
            self.vkd.updateDescriptorSets(self.dev, 1, &objectSetWrites, 0, undefined);

            // detail the global descriptor set.
            self.frameData[i].cameraBuffer = try self.create_buffer(@sizeOf(NeonVkCameraDataGpu), .{ .uniform_buffer_bit = true }, .cpuToGpu, "Framedata camera buffer");

            var allocInfo = vk.DescriptorSetAllocateInfo{
                .descriptor_pool = self.descriptorPool,
                .descriptor_set_count = 1,
                .p_set_layouts = @ptrCast(&self.globalDescriptorLayout),
            };
            try self.vkd.allocateDescriptorSets(self.dev, &allocInfo, @as([*]vk.DescriptorSet, @ptrCast(&self.frameData[i].globalDescriptorSet)));

            var cameraInfo = vk.DescriptorBufferInfo{
                .buffer = self.frameData[i].cameraBuffer.buffer,
                .offset = 0,
                .range = @sizeOf(NeonVkCameraDataGpu),
            };

            var sceneInfo = vk.DescriptorBufferInfo{
                .buffer = self.sceneParameterBuffer.buffer,
                .offset = 0,
                .range = @sizeOf(NeonVkSceneDataGpu),
            };

            var cameraWrite = vkinit.writeDescriptorSet(
                .uniform_buffer,
                self.frameData[i].globalDescriptorSet,
                &cameraInfo,
                0,
            );
            var sceneWrite = vkinit.writeDescriptorSet(
                .uniform_buffer_dynamic,
                self.frameData[i].globalDescriptorSet,
                &sceneInfo,
                1,
            );

            var setWrites = [_]@TypeOf(sceneWrite){ cameraWrite, sceneWrite };

            self.vkd.updateDescriptorSets(self.dev, 2, &setWrites, 0, undefined);
        }
    }

    pub fn init_primitive_meshes(self: *Self) !void {
        var quadMesh = try self.allocator.create(mesh.Mesh);
        quadMesh.* = mesh.Mesh.init(self, self.allocator);

        try quadMesh.vertices.resize(6);
        quadMesh.*.vertices.items[0].position = .{ .x = 0.5, .y = 0.5, .z = 0.0 };
        quadMesh.*.vertices.items[1].position = .{ .x = 0.5, .y = -0.5, .z = 0.0 };
        quadMesh.*.vertices.items[2].position = .{ .x = -0.5, .y = -0.5, .z = 0.0 };

        quadMesh.*.vertices.items[3].position = .{ .x = -0.5, .y = -0.5, .z = 0.0 };
        quadMesh.*.vertices.items[4].position = .{ .x = -0.5, .y = 0.5, .z = 0.0 };
        quadMesh.*.vertices.items[5].position = .{ .x = 0.5, .y = 0.5, .z = 0.0 };

        quadMesh.*.vertices.items[0].uv = .{ .x = 1.0, .y = 0.0 };
        quadMesh.*.vertices.items[1].uv = .{ .x = 1.0, .y = 1.0 };
        quadMesh.*.vertices.items[2].uv = .{ .x = 0.0, .y = 1.0 };

        quadMesh.*.vertices.items[3].uv = .{ .x = 0.0, .y = 1.0 };
        quadMesh.*.vertices.items[4].uv = .{ .x = 0.0, .y = 0.0 };
        quadMesh.*.vertices.items[5].uv = .{ .x = 1.0, .y = 0.0 };

        try quadMesh.upload(self);
        try self.meshes.put(self.allocator, core.MakeName("mesh_quad").handle(), quadMesh);
    }

    // we need a content filing system
    pub fn new_mesh_from_obj(self: *Self, meshName: core.Name, filename: []const u8) !*mesh.Mesh {
        var newMesh = try self.allocator.create(mesh.Mesh);
        newMesh.* = mesh.Mesh.init(self, self.allocator);
        try newMesh.load_from_obj_file(filename);
        try newMesh.upload(self);
        try self.meshes.put(self.allocator, meshName.handle(), newMesh);
        return newMesh;
    }

    pub fn stage_and_push_mesh(self: *Self, uploadedMesh: *mesh.Mesh) !void {
        const bufferSize = uploadedMesh.vertices.items.len * @sizeOf(mesh.Vertex);
        var bci = vk.BufferCreateInfo{
            .flags = .{},
            .size = bufferSize,
            .usage = .{ .transfer_src_bit = true },
            .sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = undefined,
        };

        var vmaCreateInfo = vma.AllocationCreateInfo{
            .flags = .{},
            .usage = .cpuOnly,
        };

        var stagingBuffer = try self.vkAllocator.createBuffer(bci, vmaCreateInfo, @src().fn_name ++ "-- intermediate buffer");
        defer stagingBuffer.deinit(self.vkAllocator);

        {
            var data = try self.vkAllocator.vmaAllocator.mapMemory(stagingBuffer.allocation, u8);

            var dataSlice: []u8 = undefined;
            dataSlice.ptr = data;
            dataSlice.len = bufferSize;

            var inputSlice: []const u8 = undefined;
            inputSlice.ptr = @as([*]const u8, @ptrCast(uploadedMesh.vertices.items.ptr));
            inputSlice.len = bufferSize;

            @memcpy(data, inputSlice);
            self.vkAllocator.vmaAllocator.unmapMemory(stagingBuffer.allocation);
        }

        // Gpu sided buffer
        var gpuBci = vk.BufferCreateInfo{
            .flags = .{},
            .size = bufferSize,
            .usage = .{ .transfer_dst_bit = true, .vertex_buffer_bit = true },
            .sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = undefined,
        };

        var gpuVmaCreateInfo = vma.AllocationCreateInfo{
            .flags = .{},
            .usage = .gpuOnly,
        };

        uploadedMesh.buffer = try self.vkAllocator.createBuffer(gpuBci, gpuVmaCreateInfo, @src().fn_name ++ "-- mesh buffer");

        core.graphics_log("Staring upload context", .{});
        try self.uploader.startUploadContext();
        {
            var copy = vk.BufferCopy{
                .dst_offset = 0,
                .src_offset = 0,
                .size = bufferSize,
            };
            const cmd = self.uploader.commandBuffer;
            core.graphics_log("Starting command copy buffer", .{});
            self.vkd.cmdCopyBuffer(
                cmd,
                stagingBuffer.buffer,
                uploadedMesh.buffer.buffer,
                1,
                @as([*]const vk.BufferCopy, @ptrCast(&copy)),
            );
        }
        core.graphics_log("Finishing upload context", .{});
        try self.uploader.finishUploadContext();
    }

    pub fn upload_mesh(self: *Self, uploadedMesh: *mesh.Mesh) !NeonVkBuffer {
        const size = uploadedMesh.vertices.items.len * @sizeOf(mesh.Vertex);
        core.graphics_log("Uploading mesh size = {d} bytes {d} vertices", .{ size, uploadedMesh.vertices.items.len });
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

        var buffer = try self.vkAllocator.createBuffer(bci, vmaCreateInfo);

        var data = try self.vkAllocator.vmaAllocator.mapMemory(buffer.allocation, u8);
        defer self.vkAllocator.vmaAllocator.unmapMemory(buffer.allocation);

        var dataSlice: []u8 = undefined;
        dataSlice.ptr = data;
        dataSlice.len = size;

        var inputSlice: []const u8 = undefined;
        inputSlice.ptr = @as([*]const u8, @ptrCast(uploadedMesh.vertices.items.ptr));
        inputSlice.len = size;

        @memcpy(data, inputSlice);

        return buffer;
    }

    pub fn init_vma(self: *Self) !void {
        self.vmaFunctions = vma.VulkanFunctions.init(self.instance, self.dev, self.vkb.dispatch.vkGetInstanceProcAddr);

        self.vkAllocator = try NeonVkAllocator.create(
            .{
                .instance = self.instance,
                .physicalDevice = self.physicalDevice,
                .device = self.dev,
                .frameInUseCount = NumFrames,
                .pVulkanFunctions = &self.vmaFunctions,
            },
            self.allocator,
            self.vkb,
            self.vki,
            self.vkd,
        );
    }

    fn create_mesh_material(self: *Self) !void {
        // Creates the standard mesh pipeline, this pipeline is statically stored as
        core.graphics_logs("Creating mesh pipeline");

        // Initialize the pipeline with the default triangle mesh shader
        // and the default lighting shader
        var vert_spv = try graphics.loadSpv(self.allocator, "triangle_mesh_vert.spv");
        defer self.allocator.free(vert_spv);
        var frag_spv = try graphics.loadSpv(self.allocator, "default_lit.spv");
        defer self.allocator.free(frag_spv);

        var pipeline_builder = try NeonVkPipelineBuilder.init(
            self.dev,
            self.vkd,
            self.allocator,
            self.vkAllocator,
            vert_spv,
            frag_spv,
        );
        defer pipeline_builder.deinit();

        try pipeline_builder.add_mesh_description();
        try pipeline_builder.add_push_constant();
        try pipeline_builder.add_layout(self.globalDescriptorLayout);
        try pipeline_builder.add_layout(self.objectDescriptorLayout);
        try pipeline_builder.add_layout(self.singleTextureSetLayout);
        try pipeline_builder.add_depth_stencil();
        try pipeline_builder.init_triangle_pipeline(self.actual_extent);

        const materialName = core.MakeName("t_mesh");

        var material = try self.allocator.create(Material);
        material.* = Material{
            .materialName = materialName,
            .pipeline = (try pipeline_builder.build(self.renderPass)).?,
            .layout = pipeline_builder.pipelineLayout,
        };

        var allocInfo = vk.DescriptorSetAllocateInfo{
            .descriptor_pool = self.descriptorPool,
            .descriptor_set_count = 1,
            .p_set_layouts = @ptrCast(&self.singleTextureSetLayout),
        };
        try self.vkd.allocateDescriptorSets(
            self.dev,
            &allocInfo,
            @as([*]vk.DescriptorSet, @ptrCast(&material.textureSet)),
        );

        // --------- set up the image
        var imageBufferInfo = vk.DescriptorImageInfo{
            .sampler = self.blockySampler,
            .image_view = (self.textures.get(core.MakeName("missing_texture").handle())).?.imageView,
            .image_layout = .shader_read_only_optimal,
        };
        try self.materials.put(self.allocator, materialName.handle(), material);

        var descriptorSet = vkinit.writeDescriptorImage(
            .combined_image_sampler,
            self.materials.get(materialName.handle()).?.textureSet,
            &imageBufferInfo,
            0,
        );

        self.vkd.updateDescriptorSets(self.dev, 1, @ptrCast(&descriptorSet), 0, undefined);
        // ---------------
    }

    pub fn add_material(self: *@This(), material: *Material) !void {
        try self.materials.put(self.allocator, material.materialName.handle(), material);
    }

    pub fn create_white_material(self: *@This(), size: core.Vector2i) !void {
        // generate a white texture.
        var pixels = try self.allocator.alloc(u8, @as(usize, @intCast(size.x * size.y * 4)));
        defer self.allocator.free(pixels);

        for (0..@as(usize, @intCast(size.x * size.y * 4))) |i| {
            pixels[i] = 255;
        }

        _ = try vk_utils.createAndInstallTextureFromPixels(core.MakeName("t_white"), pixels, size, self, false);
    }

    pub fn init_pipelines(self: *Self) !void {
        var samplerCreateInfo = vkinit.samplerCreateInfo(.nearest, null);
        self.blockySampler = try self.vkd.createSampler(self.dev, &samplerCreateInfo, null);

        var linearCreateSample = vkinit.samplerCreateInfo(.linear, null);
        linearCreateSample.mipmap_mode = .linear;
        self.linearSampler = try self.vkd.createSampler(self.dev, &linearCreateSample, null);

        try self.create_mesh_material();

        core.graphics_logs("Finishing up pipeline creation");
    }

    pub fn shouldExit(self: Self) !bool {
        if (self.exitSignal)
            return true;

        return false;
    }

    pub fn getNextSwapImage(self: *Self) !u32 {
        var z1 = tracy.ZoneN(@src(), "Acquiring Next image");
        var image_index = (try self.vkd.acquireNextImageKHR(
            self.dev,
            self.swapchain,
            1000000000,
            self.extraSemaphore,
            .null_handle,
        )).image_index;
        z1.End();

        std.mem.swap(
            vk.Semaphore,
            &self.extraSemaphore,
            &self.acquireSemaphores.items[image_index],
        );
        return image_index;
    }

    fn updateTime(self: *Self, deltaTime: f64) void {
        self.rendererTime += deltaTime;
    }

    pub fn tick(self: *Self, dt: f64) void {
        self.updateTime(dt);

        core.gScene.updateTransforms();
        self.sceneManager.update(self) catch unreachable;
        // self.dynamicMeshManager.tickUpdates() catch unreachable;

        self.draw(dt) catch unreachable;
        // self.dynamicMeshManager.finishUpload() catch unreachable;

        if (self.shouldExit() catch unreachable) {
            core.gEngine.exit();
        }
    }

    // convert game state into some intermediate graphics data.
    pub fn pre_frame_update(self: *Self) !void {
        var z1 = tracy.ZoneN(@src(), "pre frame update");
        defer z1.End();

        if (self.renderObjectsAreDirty) {
            var z11 = tracy.ZoneN(@src(), "sorting renderObjects");
            try self.sortRenderObjects();
            self.renderObjectsAreDirty = false;
            z11.End();
        }

        // ---- bind global descriptors ----
        var z2 = tracy.ZoneN(@src(), "mapping memory");
        var data = try self.vkAllocator.vmaAllocator.mapMemory(self.frameData[self.nextFrameIndex].cameraBuffer.allocation, u8);
        z2.End();

        // ==== upload camera data ====
        if (self.cameraRef != null) {
            vk_renderer_camera_gpu.memcpyCameraDataToStagedBuffer(self.cameraRef.?, data);
        } else {
            vk_renderer_camera_gpu.uploadNullCameraToBuffer(data);
        }

        var z4 = tracy.ZoneN(@src(), "unmapping");
        self.vkAllocator.vmaAllocator.unmapMemory(self.frameData[self.nextFrameIndex].cameraBuffer.allocation);
        z4.End();
    }

    // resume here ---
    //
    // go through draw() step by step and filter out everything
    // needed in this thing to encode into vkrendererstate and vkrenderersystem
    //
    // also seperate a system such as papyrussystem and papyrus text renderer
    // into what they are right now, and split out all the vulkan
    // specific stuff into a seperate object type and double buffer vulkan
    // commands.
    //
    pub fn acquire_next_frame(self: *Self) !void {
        var z1 = tracy.Zone(@src());
        z1.Name("waiting for frame");
        defer z1.End();
        self.nextFrameIndex = try self.getNextSwapImage();

        _ = try self.vkd.waitForFences(
            self.dev,
            1,
            @as([*]const vk.Fence, @ptrCast(&self.commandBufferFences.items[self.nextFrameIndex])),
            1,
            1000000000,
        );
        try self.vkd.resetFences(self.dev, 1, @as([*]const vk.Fence, @ptrCast(&self.commandBufferFences.items[self.nextFrameIndex])));
    }

    pub fn start_frame_command_buffer(self: *Self) !vk.CommandBuffer {
        var cmd = self.commandBuffers.items[self.nextFrameIndex];
        try self.vkd.resetCommandBuffer(cmd, .{});

        var cbi = vk.CommandBufferBeginInfo{
            .p_inheritance_info = null,
            .flags = .{ .one_time_submit_bit = true },
        };
        try self.vkd.beginCommandBuffer(cmd, &cbi);

        return cmd;
    }

    pub fn begin_main_renderpass(self: *Self, cmd: vk.CommandBuffer) !void {
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
            .framebuffer = self.framebuffers.items[self.nextFrameIndex],
            .render_pass = self.renderPass,
            .clear_value_count = 2,
            .p_clear_values = @as([*]const vk.ClearValue, @ptrCast(&clearValues)),
        };

        self.vkd.cmdBeginRenderPass(cmd, &rpbi, .@"inline");

        self.vkd.cmdSetViewport(cmd, 0, 1, @ptrCast(&self.viewport));
        self.vkd.cmdSetScissor(cmd, 0, 1, @ptrCast(&self.scissor));
    }

    pub fn finish_main_renderpass(self: *Self, cmd: vk.CommandBuffer) !void {
        self.vkd.cmdEndRenderPass(cmd);
    }

    pub fn draw(self: *Self, deltaTime: f64) !void {
        if (!self.isMinimized) {
            try self.acquire_next_frame();

            try self.pre_frame_update();
            var z2 = tracy.ZoneNC(@src(), "Main RenderPass", 0x00FF1111);
            const cmd = try self.start_frame_command_buffer();

            try self.begin_main_renderpass(cmd);
            try self.render_meshes(deltaTime);

            for (self.rendererPlugins.items) |*interface| {
                if (interface.vtable.postDraw) |postDraw| {
                    postDraw(interface.ptr, cmd, self.nextFrameIndex, deltaTime);
                }
            }
            try self.finish_main_renderpass(cmd);
            try self.dynamicMeshManager.updateMeshes(cmd);
            try self.vkd.endCommandBuffer(cmd);
            z2.End();

            var x = tracy.ZoneN(@src(), "End of Frame");
            try self.finish_frame();
            x.End();

            self.destroyDeferredDestroyTextures();
        } else {
            var w: c_int = undefined;
            var h: c_int = undefined;
            platform.c.glfwGetWindowSize(self.platformInstance.window, &w, &h);

            if ((self.extent.width != @as(u32, @intCast(w)) or self.extent.height != @as(u32, @intCast(h))) and
                (w > 0 and h > 0))
            {
                self.extent = .{ .width = @as(u32, @intCast(w)), .height = @as(u32, @intCast(h)) };

                self.isMinimized = false;
                try self.vkd.deviceWaitIdle(self.dev);
                try self.destroy_framebuffers();
                self.shouldResize = false;

                try self.init_or_recycle_swapchain();
                try self.init_framebuffers();
                // c.setFontScale(@intCast(c_int, self.actual_extent.width), @intCast(c_int, self.actual_extent.height));
            }

            if (w <= 0 or h <= 0) {
                self.isMinimized = true;
                self.extent.width = @as(u32, @intCast(w));
                self.extent.height = @as(u32, @intCast(h));
            }

            self.firstFrame = false;

            std.time.sleep(1000 * 1000);
        }

        self.firstFrame = false;
    }

    fn draw_render_object(
        self: *Self,
        render_object: RenderObject,
        cmd: vk.CommandBuffer,
        index: u32,
        deltaTime: f64,
        objectHandle: core.ObjectHandle,
    ) void {
        _ = deltaTime;

        if (!render_object.visibility)
            return;

        if (render_object.mesh == null)
            return;

        if (render_object.material == null)
            return;

        var z = tracy.ZoneNC(@src(), "draw render object", 0xBB44BB);
        defer z.End();

        const pipeline = render_object.material.?.pipeline;
        const layout = render_object.material.?.layout;
        const object_mesh = render_object.mesh.?.*;

        var offset: vk.DeviceSize = 0;

        const paddedSceneSize = @as(u32, @intCast(self.pad_uniform_buffer_size(@sizeOf(NeonVkSceneDataGpu))));
        var startOffset: u32 = paddedSceneSize * self.nextFrameIndex;

        var z1 = tracy.ZoneNC(@src(), "draw render object", 0xBB44BB);
        if (self.lastMaterial != render_object.material) {
            self.vkd.cmdBindPipeline(cmd, .graphics, pipeline);
            self.lastMaterial = render_object.material;
            self.vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 0, 1, @ptrCast(&self.frameData[self.nextFrameIndex].globalDescriptorSet), 1, @ptrCast(&startOffset));
            self.vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 1, 1, @ptrCast(&self.frameData[self.nextFrameIndex].objectDescriptorSet), 0, undefined);
        }
        defer z1.End();

        // if the renderobject has a textureset as an override use that instead of the default one on the material.
        if (render_object.texture) |textureSet| {
            self.vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 2, 1, @ptrCast(&textureSet), 0, undefined);
        } else {
            self.vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 2, 1, @ptrCast(&render_object.material.?.textureSet), 0, undefined);
        }

        // let plugins bind the render object.
        for (self.rendererPlugins.items) |*plugin| {
            plugin.vtable.onBindObject(plugin.ptr, objectHandle, index, cmd, self.nextFrameIndex);
        }

        if (self.lastMesh != render_object.mesh) {
            self.lastMesh = render_object.mesh;
            self.vkd.cmdBindVertexBuffers(cmd, 0, 1, @ptrCast(&object_mesh.buffer.buffer), @ptrCast(&offset));
        }

        // if (self.lastMesh != render_object.mesh) {
        //     self.lastMesh = render_object.mesh;
        //     self.vkd.cmdBindVertexBuffers(cmd, 0, 1, @ptrCast(&object_mesh.buffer.buffer), @ptrCast(&offset));
        // }

        var final = render_object.transform;
        var constants = NeonVkMeshPushConstant{
            .data = .{ .x = 0, .y = 0, .z = 0, .w = 0 },
            .render_matrix = final,
        };

        self.vkd.cmdPushConstants(cmd, layout, .{ .vertex_bit = true }, 0, @sizeOf(NeonVkMeshPushConstant), &constants);

        self.vkd.cmdDraw(cmd, @as(u32, @intCast(object_mesh.vertices.items.len)), 1, 0, index);
    }

    fn upload_scene_global_data(self: *Self, deltaTime: f64) !void {
        _ = deltaTime;
        var data = try self.vkAllocator.vmaAllocator.mapMemory(self.sceneParameterBuffer.allocation, u8);
        const paddedSceneSize = self.pad_uniform_buffer_size(@sizeOf(NeonVkSceneDataGpu));
        const startOffset = paddedSceneSize * self.nextFrameIndex;

        self.sceneDataGpu.fogColor = [4]f32{ 0.005, 0.005, 0.005, 1.0 };

        var dataSlice: []u8 = undefined;
        dataSlice.ptr = data + startOffset;
        dataSlice.len = @sizeOf(@TypeOf(self.sceneDataGpu));

        var inputSlice: []const u8 = undefined;
        inputSlice.ptr = @as([*]const u8, @ptrCast(&self.sceneDataGpu));
        inputSlice.len = dataSlice.len;

        @memcpy(dataSlice, inputSlice);

        self.vkAllocator.vmaAllocator.unmapMemory(self.sceneParameterBuffer.allocation);
    }

    fn upload_object_data(self: *Self) !void {
        const allocation = self.frameData[self.nextFrameIndex].objectBuffer.allocation;
        var data = try self.vkAllocator.vmaAllocator.mapMemory(allocation, NeonVkObjectDataGpu);
        var ssbo: []NeonVkObjectDataGpu = undefined;
        ssbo.ptr = @as([*]NeonVkObjectDataGpu, @ptrCast(data));
        ssbo.len = self.maxObjectCount;

        var i: usize = 0;
        while (i < self.maxObjectCount and i < self.renderObjectSet.dense.len) : (i += 1) {
            var object = self.renderObjectSet.dense.items(.renderObject)[i];
            if (object.mesh != null) {
                ssbo[i].modelMatrix = self.renderObjectSet.dense.items(.renderObject)[i].transform;
            }
        }

        // unmapping every frame might actually be quite unessecary.
        self.vkAllocator.vmaAllocator.unmapMemory(allocation);
    }

    fn render_meshes(self: *Self, deltaTime: f64) !void {
        var z = tracy.ZoneNC(@src(), "render meshes", 0xAAFFFF);
        defer z.End();
        var z1 = tracy.ZoneNC(@src(), "uploading global and object data", 0xAAFFAA);
        try self.upload_scene_global_data(deltaTime);
        try self.upload_object_data();
        z1.End();

        // activate predraw plugins here.

        var z10 = tracy.ZoneNC(@src(), "renderer plugins - preDraw", 0xAAFFFF);
        for (self.rendererPlugins.items) |*interface| {
            interface.vtable.preDraw(interface.ptr, self.nextFrameIndex);
        }
        defer z10.End();

        var cmd = self.commandBuffers.items[self.nextFrameIndex];

        self.lastMaterial = null;
        self.lastMesh = null;

        var z2 = tracy.ZoneNC(@src(), "rendering objects", 0xBBAAFF);
        for (self.renderObjectSet.dense.items(.renderObject), 0..) |dense, i| {
            // holy moly i really should make a convenience function for this.
            // dense to sparse given a known dense index
            var sparseHandle = self.renderObjectSet.sparse[self.renderObjectSet.denseIndices.items[i].index];
            sparseHandle.index = self.renderObjectSet.denseIndices.items[i].index;
            self.draw_render_object(dense, cmd, @as(u32, @intCast(i)), deltaTime, sparseHandle);
        }
        z2.End();
    }

    fn finish_frame(self: *Self) !void {
        var waitStage = vk.PipelineStageFlags{ .color_attachment_output_bit = true };

        var submit = vk.SubmitInfo{
            .p_wait_dst_stage_mask = @as([*]const vk.PipelineStageFlags, @ptrCast(&waitStage)),
            .wait_semaphore_count = 1,
            .p_wait_semaphores = @as([*]const vk.Semaphore, @ptrCast(&self.acquireSemaphores.items[self.nextFrameIndex])),
            .signal_semaphore_count = 1,
            .p_signal_semaphores = @as([*]const vk.Semaphore, @ptrCast(&self.renderCompleteSemaphores.items[self.nextFrameIndex])),
            .command_buffer_count = 1,
            .p_command_buffers = @as([*]const vk.CommandBuffer, @ptrCast(&self.commandBuffers.items[self.nextFrameIndex])),
        };

        var z1 = tracy.ZoneNC(@src(), "submitting", 0xBBAAFF);
        try self.vkd.queueSubmit(
            self.graphicsQueue.handle,
            1,
            @as([*]const vk.SubmitInfo, @ptrCast(&submit)),
            self.commandBufferFences.items[self.nextFrameIndex],
        );
        z1.End();

        var presentInfo = vk.PresentInfoKHR{
            .p_swapchains = @as([*]const vk.SwapchainKHR, @ptrCast(&self.swapchain)),
            .swapchain_count = 1,
            .p_wait_semaphores = @as([*]const vk.Semaphore, @ptrCast(&self.renderCompleteSemaphores.items[self.nextFrameIndex])),
            .wait_semaphore_count = 1,
            .p_image_indices = @as([*]const u32, @ptrCast(&self.nextFrameIndex)),
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
        platform.c.glfwGetWindowSize(self.platformInstance.window, &w, &h);

        if ((outOfDate or self.extent.width != @as(u32, @intCast(w)) or self.extent.height != @as(u32, @intCast(h))) and
            (w > 0 and h > 0))
        {
            self.extent = .{ .width = @as(u32, @intCast(w)), .height = @as(u32, @intCast(h)) };
            platform.getInstance().extent = .{ .x = w, .y = h };

            self.isMinimized = false;
            try self.vkd.deviceWaitIdle(self.dev);
            try self.destroy_framebuffers();
            self.shouldResize = false;

            try self.init_or_recycle_swapchain();
            try self.init_framebuffers();
        }

        if (w <= 0 or h <= 0) {
            self.isMinimized = true;
        }

        self.firstFrame = false;
    }

    fn destroy_framebuffers(self: *Self) !void {
        self.vkd.destroyImageView(self.dev, self.depthImageView, null);
        self.depthImage.deinit(self.vkAllocator);
        for (self.framebuffers.items) |framebuffer| {
            self.vkd.destroyFramebuffer(self.dev, framebuffer, null);
        }
        self.framebuffers.deinit();
        for (self.swapImages.items, 0..) |_, i| {
            self.swapImages.items[i].deinit(self);
        }
        self.swapImages.deinit();
    }

    fn init_framebuffers(self: *Self) !void {
        self.framebuffers = ArrayList(vk.Framebuffer).init(self.allocator);
        try self.framebuffers.resize(self.swapImages.items.len);

        var attachments = try self.allocator.alloc(vk.ImageView, 2);
        defer self.allocator.free(attachments);
        attachments[1] = self.depthImageView; // slot 0 is going to be the current image view, slot 1 is the depth image view

        var fbci = vk.FramebufferCreateInfo{
            .flags = .{},
            .render_pass = self.renderPass,
            .attachment_count = 2,
            .p_attachments = attachments.ptr,
            .width = self.actual_extent.width,
            .height = self.actual_extent.height,
            .layers = 1,
        };

        core.graphics_log("swapImages count = {d}", .{self.swapImages.items.len});

        for (self.swapImages.items, 0..) |image, i| {
            attachments[0] = image.view;
            //debug_struct("fbci.p_attachment[0]", fbci.p_attachments[0]);
            self.framebuffers.items[i] = try self.vkd.createFramebuffer(self.dev, &fbci, null);
            core.graphics_logs("Created a framebuffer!");
        }
    }

    fn init_rendertarget(self: *Self) !void {
        var formats = [_]vk.Format{
            .d32_sfloat,
            .d24_unorm_s8_uint,
        };

        self.depthFormat = try self.find_supported_format(
            formats[0..],
            .optimal,
            .{ .depth_stencil_attachment_bit = true },
        );
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
            .initial_layout = .undefined,
            .final_layout = .present_src_khr,
        };

        var colorAttachmentRef = vk.AttachmentReference{
            .attachment = @as(u32, @intCast(attachments.items.len)),
            .layout = .color_attachment_optimal,
        };

        try attachments.append(colorAttachment);

        var depthAttachment = vk.AttachmentDescription{
            .flags = .{},
            .format = self.depthFormat,
            .samples = .{ .@"1_bit" = true },
            .load_op = .clear,
            .store_op = .store,
            .stencil_load_op = .clear, // equals to zero
            .stencil_store_op = .store, // equals to zero but we don't care
            .initial_layout = .undefined,
            .final_layout = .depth_stencil_attachment_optimal,
        };

        var depthAttachmentRef = vk.AttachmentReference{
            .attachment = @as(u32, @intCast(attachments.items.len)),
            .layout = .depth_stencil_attachment_optimal,
        };
        try attachments.append(depthAttachment);

        var subpass = std.mem.zeroes(vk.SubpassDescription);
        subpass.flags = .{};
        subpass.pipeline_bind_point = .graphics;
        subpass.input_attachment_count = 0;
        subpass.color_attachment_count = 1;
        subpass.p_color_attachments = @as([*]const vk.AttachmentReference, @ptrCast(&colorAttachmentRef));
        subpass.p_depth_stencil_attachment = &depthAttachmentRef; // disable the depth attachment for now
        //subpass.p_depth_stencil_attachment = null;

        var dependency = vk.SubpassDependency{
            .dependency_flags = .{},
            .src_subpass = vk.SUBPASS_EXTERNAL,
            .dst_subpass = 0,
            .src_stage_mask = .{ .color_attachment_output_bit = true },
            .src_access_mask = .{},
            .dst_stage_mask = .{ .color_attachment_output_bit = true },
            .dst_access_mask = .{ .color_attachment_write_bit = true },
        };

        var depthDependency = vk.SubpassDependency{
            .dependency_flags = .{},
            .src_subpass = vk.SUBPASS_EXTERNAL,
            .dst_subpass = 0,
            .src_stage_mask = .{
                .early_fragment_tests_bit = true,
                .late_fragment_tests_bit = true,
            },
            .src_access_mask = .{},
            .dst_stage_mask = .{
                .early_fragment_tests_bit = true,
                .late_fragment_tests_bit = true,
            },
            .dst_access_mask = .{ .depth_stencil_attachment_write_bit = true },
        };

        var dependencies = [2]vk.SubpassDependency{ dependency, depthDependency };

        var rpci = std.mem.zeroes(vk.RenderPassCreateInfo);
        rpci.s_type = .render_pass_create_info;
        rpci.flags = .{};
        rpci.attachment_count = @as(u32, @intCast(attachments.items.len));
        rpci.p_attachments = attachments.items.ptr;
        rpci.subpass_count = 1;
        rpci.p_subpasses = @as([*]const vk.SubpassDescription, @ptrCast(&subpass));
        rpci.dependency_count = 2;
        rpci.p_dependencies = &dependencies;
        // debug_struct("rpci", rpci);

        core.graphics_log("initializing renderpass", .{});
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
            if (imageTiling == .linear and (@as(u32, @bitCast(props.linear_tiling_features)) & @as(u32, @bitCast(features))) == @as(u32, @bitCast(features))) {
                return format;
            } else if (imageTiling == .optimal and (@as(u32, @bitCast(props.optimal_tiling_features)) & @as(u32, @bitCast(features))) == @as(u32, @bitCast(features))) {
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

        self.viewport = vk.Viewport{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(self.actual_extent.width)),
            .height = @as(f32, @floatFromInt(self.actual_extent.height)),
            .min_depth = 0.0,
            .max_depth = 1.0,
        };

        self.scissor = .{
            .offset = .{ .x = 0, .y = 0 },
            .extent = self.actual_extent,
        };
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

        for (core.count(NumFrames), 0..) |_, i| {
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

            var swapImage = NeonVkSwapImage{
                .image = image,
                .view = imageView,
                .imageIndex = i,
            };

            self.swapImages.items[i] = swapImage;
        }

        var depthImageExtent = vk.Extent3D{
            .width = self.actual_extent.width,
            .height = self.actual_extent.height,
            .depth = 1,
        };

        self.depthFormat = .d32_sfloat;

        var dimg_ici = vk.ImageCreateInfo{
            .flags = .{},
            .sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = undefined,
            .initial_layout = .undefined,
            .image_type = .@"2d",
            .format = self.depthFormat,
            .extent = depthImageExtent,
            .mip_levels = 1,
            .array_layers = 1,
            .samples = .{
                .@"1_bit" = true,
            },
            .tiling = .optimal,
            .usage = .{ .depth_stencil_attachment_bit = true },
        };

        var dimg_aci = vma.AllocationCreateInfo{
            .requiredFlags = .{
                .device_local_bit = true,
            },
            .usage = .gpuOnly,
        };

        // var result = try self.vmaAllocator.createImage(dimg_create, dimg_vma_alloc_info);
        // self.depthImage = .{
        //     .image = result.image,
        //     .allocation = result.allocation,
        //     .pixelWidth = self.actual_extent.width,
        //     .pixelHeight = self.actual_extent.height,
        // };

        self.depthImage = try self.vkAllocator.createImage(dimg_ici, dimg_aci, @src().fn_name);

        var imageViewCreate = vk.ImageViewCreateInfo{
            .flags = .{},
            .image = self.depthImage.image,
            .view_type = .@"2d",
            .format = self.depthFormat,
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

        self.depthImageView = try self.vkd.createImageView(self.dev, &imageViewCreate, null);
    }

    pub fn init_syncs(self: *Self) !void {
        self.acquireSemaphores = try ArrayList(vk.Semaphore).initCapacity(self.allocator, NumFrames);
        self.renderCompleteSemaphores = try ArrayList(vk.Semaphore).initCapacity(self.allocator, NumFrames);

        try self.acquireSemaphores.resize(NumFrames);
        try self.renderCompleteSemaphores.resize(NumFrames);

        var sci = vk.SemaphoreCreateInfo{
            .flags = .{},
        };

        for (core.count(NumFrames), 0..) |_, i| {
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

        for (core.count(NumFrames), 0..) |_, i| {
            self.commandBufferFences.items[i] = try self.vkd.createFence(self.dev, &fci, null);
        }
    }

    pub fn init_command_pools(self: *Self) !void {
        var cpci = vk.CommandPoolCreateInfo{ .flags = .{}, .queue_family_index = undefined };
        cpci.flags.reset_command_buffer_bit = true;
        cpci.queue_family_index = @as(u32, @intCast(self.graphicsFamilyIndex));

        self.commandPool = try self.vkd.createCommandPool(self.dev, &cpci, null);
    }

    fn init_api(self: *Self) !void {
        self.vkb = try BaseDispatch.load(platform.c.glfwGetInstanceProcAddress);

        try self.graph.write("  init_api->\"BaseDispatch@0x{x}\" [style=dotted]\n", .{@intFromPtr(&self.vkb)});
        try self.graph.write("  init_api->create_vulkan_instance\n", .{});
        try self.create_vulkan_instance();
        errdefer self.vki.destroyInstance(self.instance, null);

        // create KHR surface structure
        try self.graph.write("  init_api->create_surface\n", .{});
        try self.create_surface();
        errdefer self.vki.destroySurfaceKHR(self.instance, self.surface, null);
    }

    fn create_vulkan_instance(self: *Self) !void {
        var extensionsCount: u32 = 0;
        const extensions = platform.c.glfwGetRequiredInstanceExtensions(&extensionsCount);
        var requestedExtensions: [10][*:0]const u8 = undefined;

        if (extensionsCount > 0) {
            core.engine_logs("glfw has requested extensions:");
            var i: usize = 0;
            while (i < extensionsCount) : (i += 1) {
                var x = @as([*]const CStr, @ptrCast(extensions));
                core.engine_log("  glfw_extension: {s}", .{x[i]});
                requestedExtensions[i] = extensions[i];
            }
        }

        // if we are macos we need this one.
        requestedExtensions[extensionsCount] = "VK_KHR_portability_enumeration";

        // Make a request for vulkan layers
        const ExtraLayers = [1]CStr{
            vk_constants.VK_KHRONOS_VALIDATION_LAYER_STRING,
        };

        // setup vulkan application info
        const appInfo = vk.ApplicationInfo{
            .p_application_name = @as(?[*:0]const u8, @ptrCast(self.platformInstance.windowName.ptr)),
            .application_version = vk.makeApiVersion(0, 0, 0, 0),
            .p_engine_name = @as(?[*:0]const u8, @ptrCast(self.platformInstance.windowName.ptr)),
            .engine_version = vk.makeApiVersion(0, 0, 0, 0),
            .api_version = vk.makeApiVersion(0, 1, 3, 0),
        };

        var flagbits: u32 = 0x01;
        // instance create info struct
        const icis = vk.InstanceCreateInfo{
            .flags = @bitCast(flagbits),
            .p_application_info = &appInfo,
            .enabled_layer_count = if (gGraphicsStartupSettings.vulkanValidation) 1 else 0,
            .pp_enabled_layer_names = @as([*]const [*:0]const u8, @ptrCast(&ExtraLayers[0])),
            .enabled_extension_count = extensionsCount + 1,
            .pp_enabled_extension_names = @as(?[*]const [*:0]const u8, @ptrCast(&requestedExtensions)) orelse undefined,
        };

        core.graphics_logs("creating Instance");
        try self.graph.write("  create_vulkan_instance->\"vkb.createInstance\"\n", .{});
        self.instance = try self.vkb.createInstance(&icis, null);
        core.graphics_logs("instance created");

        try self.graph.write("  create_vulkan_instance->\"vki.load\"\n", .{});
        // load vulkan per instance functions
        self.vki = try InstanceDispatch.load(self.instance, platform.c.glfwGetInstanceProcAddress);
    }

    fn init_device(self: *Self) !void {
        core.graphics_logs(" init device");
        try self.graph.write("  init_device->create_physical_devices\n", .{});
        try self.create_physical_devices();

        var ids = ArrayList(u32).init(self.allocator);
        defer ids.deinit();

        try core.AppendToArrayListUnique(&ids, @as(u32, @intCast(self.graphicsFamilyIndex)));
        try core.AppendToArrayListUnique(&ids, @as(u32, @intCast(self.presentFamilyIndex)));

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
        // TODO: disable these features as they become unavailable on rpi
        //desiredFeatures.texture_compression_bc = vk.TRUE;
        // desiredFeatures.image_cube_array = vk.TRUE;
        // desiredFeatures.depth_clamp = vk.TRUE;
        // desiredFeatures.depth_bias_clamp = vk.TRUE;
        // desiredFeatures.fill_mode_non_solid = vk.TRUE;

        var shaderDrawFeatures = vk.PhysicalDeviceShaderDrawParametersFeatures{
            // .shader_draw_parameters = vk.TRUE,
        };

        for (self.requiredExtensions.items) |required| {
            core.graphics_log("required extension: {s}", .{required});
        }

        var dci = vk.DeviceCreateInfo{
            .flags = .{},
            .p_next = &shaderDrawFeatures,
            .queue_create_info_count = @as(u32, @intCast(createQueueInfoList.items.len)),
            .p_queue_create_infos = createQueueInfoList.items.ptr,
            .enabled_layer_count = 1,
            .pp_enabled_layer_names = undefined,
            .enabled_extension_count = @as(u32, @intCast(self.requiredExtensions.items.len)),
            .pp_enabled_extension_names = self.requiredExtensions.items.ptr,
            .p_enabled_features = &desiredFeatures,
        };

        dci.enabled_layer_count = vk_constants.required_device_layers.len;
        dci.pp_enabled_layer_names = @as([*]const [*:0]const u8, @ptrCast(&vk_constants.required_device_layers));

        self.dev = try self.vki.createDevice(self.physicalDevice, &dci, null);

        self.vkd = try DeviceDispatch.load(self.dev, self.vki.dispatch.vkGetDeviceProcAddr);
        errdefer self.vkd.destroyDevice(self.dev, null);

        self.graphicsQueue = NeonVkQueue.init(self.vkd, self.dev, self.graphicsFamilyIndex);
        self.presentQueue = NeonVkQueue.init(self.vkd, self.dev, self.presentFamilyIndex);

        core.graphics_logs("Successfully created device");
    }

    fn create_physical_devices(self: *Self) !void {
        try self.graph.write("  create_physical_devices->enumerate_physical_devices\n", .{});
        try self.enumerate_physical_devices();

        try self.graph.write("  create_physical_devices->find_physical_devices\n", .{});
        try self.find_physical_device();
    }

    // sorts renderObjects by material
    fn sortRenderObjects(self: *Self) !void {
        self.renderObjectsByMaterial.clearRetainingCapacity();
        try self.renderObjectsByMaterial.resize(self.allocator, self.renderObjectSet.dense.len);

        var i: u32 = 0;
        while (i < self.renderObjectSet.dense.len) : (i += 1) {
            self.renderObjectsByMaterial.items[i] = i;
        }

        const X = struct {
            pub fn lessThan(ctx: *NeonVkContext, lhs: u32, rhs: u32) bool {
                return @intFromPtr(ctx.renderObjectSet.dense.items(.renderObject)[lhs].material) < @intFromPtr(ctx.renderObjectSet.dense.items(.renderObject)[rhs].material);
            }
        };

        std.sort.insertion(
            u32,
            self.renderObjectsByMaterial.items,
            self,
            X.lessThan,
        );
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

            for (pDeviceInfo.queueFamilyProperties.items, 0..) |props, i| {
                if (props.queue_count == 0)
                    continue;

                if (props.queue_flags.graphics_bit) {
                    core.graphics_log("Found suitable graphics device with queue id: {d}", .{i});
                    graphicsID = @as(isize, @intCast(i));
                    break;
                }
            }

            //  find the present queue family

            for (pDeviceInfo.queueFamilyProperties.items, 0..) |props, i| {
                if (props.queue_count == 0)
                    continue;

                var supportsPresent = try self.vki.getPhysicalDeviceSurfaceSupportKHR(pDeviceInfo.physicalDevice, @as(u32, @intCast(i)), self.surface);

                if (supportsPresent > 0) {
                    presentID = @as(isize, @intCast(i));
                    break;
                }
            }

            if ((graphicsID != -1) and (presentID != -1)) {
                self.physicalDevice = pDeviceInfo.physicalDevice;
                self.physicalDeviceProperties = pDeviceInfo.deviceProperties;
                self.physicalDeviceMemoryProperties = pDeviceInfo.memoryProperties;
                self.graphicsFamilyIndex = @as(u32, @intCast(graphicsID));
                self.presentFamilyIndex = @as(u32, @intCast(presentID));
                core.graphics_log("Found graphics queue family with id {d} [ {d} available ]", .{ graphicsID, pDeviceInfo.queueFamilyProperties.items.len });
                core.graphics_log("Found present queue family with id {d} [ {d} available ]", .{ presentID, pDeviceInfo.queueFamilyProperties.items.len });
                debug_struct("selected physical device:", self.physicalDevice);
                core.graphics_log("GPU minimum buffer alignment {d}", .{self.physicalDeviceProperties.limits.min_uniform_buffer_offset_alignment});

                for (pDeviceInfo.supportedExtensions.items) |item| {
                    const search: CStr = "VK_KHR_portability_subset";
                    const search2 = "VK_KHR_portability_subset";

                    if (std.mem.startsWith(u8, search2, item.extension_name[0..search2.len])) {
                        try self.requiredExtensions.append(self.allocator, search);
                    }
                }

                {
                    var sampleCounts: u32 = @bitCast(self.physicalDeviceProperties.limits.framebuffer_depth_sample_counts);
                    core.graphics_log("Sample counts available on device: 0x{x} {any}", .{ sampleCounts, self.getMsaaSampleCountFlag() });
                }
                return;
            }
        }

        core.engine_errs("Unable to find a physical device which fits.");
        return error.NoValidDevice;
    }

    pub fn getMsaaSampleCountFlag(self: *@This()) vk.SampleCountFlags {
        const sampleCounts = self.physicalDeviceProperties.limits.framebuffer_depth_sample_counts;

        // @"1_bit": bool = false,
        // @"2_bit": bool = false,
        // @"4_bit": bool = false,
        // @"8_bit": bool = false,
        // @"16_bit": bool = false,
        // @"32_bit": bool = false,
        // @"64_bit": bool = false,
        if (sampleCounts.@"64_bit") return .{ .@"64_bit" = true };
        if (sampleCounts.@"32_bit") return .{ .@"32_bit" = true };
        if (sampleCounts.@"16_bit") return .{ .@"16_bit" = true };
        if (sampleCounts.@"8_bit") return .{ .@"8_bit" = true };
        if (sampleCounts.@"4_bit") return .{ .@"4_bit" = true };
        if (sampleCounts.@"2_bit") return .{ .@"2_bit" = true };

        return .{ .@"1_bit" = true };
    }

    fn check_extension_support(self: *Self, deviceInfo: NeonVkPhysicalDeviceInfo) !bool {
        var count: u32 = undefined;
        _ = try self.vki.enumerateDeviceExtensionProperties(deviceInfo.physicalDevice, null, &count, null);

        const extension_list = try self.allocator.alloc(vk.ExtensionProperties, count);
        defer self.allocator.free(extension_list);

        _ = try self.vki.enumerateDeviceExtensionProperties(deviceInfo.physicalDevice, null, &count, extension_list.ptr);

        for (self.requiredExtensions.items) |required_extension| {
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

        self.enumeratedPhysicalDevices = try ArrayList(NeonVkPhysicalDeviceInfo).initCapacity(self.allocator, @as(usize, @intCast(numDevices)));
        core.graphics_log("Enumerating {d} devices...", .{numDevices});
        var i: usize = 0;
        while (i < numDevices) : (i += 1) {
            self.enumeratedPhysicalDevices.appendAssumeCapacity(try NeonVkPhysicalDeviceInfo.enumerateFrom(
                self.vki,
                devices[i],
                self.surface,
                self.allocator,
            ));

            try self.graph.write(
                "  enumerate_physical_devices->\"device:{s}:{*}\"\n",
                .{
                    @as([*:0]const u8, @ptrCast(&self.enumeratedPhysicalDevices.items[i].deviceProperties.device_name)),
                    devices.ptr,
                },
            );
        }
    }

    fn create_surface(self: *Self) !void {
        if (self.platformInstance.window == null)
            return error.WindowIsNullCantMakeSurface;

        if (platform.c.glfwCreateWindowSurface(self.instance, self.platformInstance.window.?, null, &self.surface) != .success) {
            core.engine_errs("Unable to create glfw surface");
            return error.SurfaceInitFailed;
        }

        core.graphics_logs("Suraface creation completed!");
    }

    fn check_required_vulkan_layers(self: *Self, requiredNames: []const CStr) !void {
        var layers = try self.get_layer_extensions();
        defer self.allocator.free(layers);
        for (layers, 0..) |layer, i| {
            core.graphics_log("  {d}: Layer name: {?s} \"{?s}\"", .{
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
            .fifo_khr,
            .mailbox_khr,
            .immediate_khr,
        };

        for (preferred) |mode| {
            if (std.mem.indexOfScalar(vk.PresentModeKHR, present_modes, mode) != null) {
                self.presentMode = mode;
                break;
            }
        }

        if (force_mailbox) {
            self.presentMode = .mailbox_khr;
        }
    }

    pub fn registerRendererPlugin(self: *@This(), value: anytype) !void {
        var ref = RendererInterfaceRef{
            .ptr = value,
            .vtable = &@TypeOf(value.*).RendererInterfaceVTable,
        };
        try self.rendererPlugins.append(self.allocator, ref);
    }

    pub fn get_layer_extensions(self: *Self) ![]const vk.LayerProperties {
        var count: u32 = 0;
        _ = try self.vkb.enumerateInstanceLayerProperties(&count, null);

        var data = try self.allocator.alloc(vk.LayerProperties, count);
        core.graphics_log("layers found : {d}", .{count});
        _ = try self.vkb.enumerateInstanceLayerProperties(&count, data.ptr);

        return data;
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

    pub fn destroy_renderpass(self: *Self) !void {
        self.vkd.destroyRenderPass(self.dev, self.renderPass, null);
    }

    pub fn destroy_meshes(self: *Self) !void {
        var iter = self.meshes.iterator();
        while (iter.next()) |i| {
            i.value_ptr.*.deinit(self);
            self.allocator.destroy(i.value_ptr.*);
        }
        self.meshes.deinit(self.allocator);

        self.dynamicMeshManager.deinit();
    }

    pub fn destroy_renderobjects(self: *Self) !void {
        self.renderObjectSet.deinit();
    }

    pub fn create_buffer(
        self: *Self,
        allocSize: usize,
        usage: vk.BufferUsageFlags,
        memoryUsageFlags: vma.MemoryUsage,
        comptime tag: []const u8,
    ) !NeonVkBuffer {
        var cbi = vk.BufferCreateInfo{
            .size = allocSize,
            .usage = usage,
            .flags = .{},
            .sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = undefined,
        };

        var vma_alloc_info = vma.AllocationCreateInfo{
            .usage = memoryUsageFlags,
        };

        return try self.vkAllocator.createBuffer(cbi, vma_alloc_info, tag);
    }

    pub fn destroy_materials(self: *Self) void {
        var iter = self.materials.iterator();
        while (iter.next()) |i| {
            i.value_ptr.*.deinit(self);
            self.allocator.destroy(i.value_ptr.*);
        }
    }

    pub fn destroy_descriptors(self: *Self) void {
        for (self.frameData, 0..) |_, i| {
            self.frameData[i].cameraBuffer.deinit(self.vkAllocator);
            // self.frameData[i].spriteBuffer.deinit(self.vmaAllocator);
            self.frameData[i].objectBuffer.deinit(self.vkAllocator);
        }
        self.sceneParameterBuffer.deinit(self.vkAllocator);

        self.vkd.destroyDescriptorSetLayout(self.dev, self.objectDescriptorLayout, null);
        self.vkd.destroyDescriptorSetLayout(self.dev, self.globalDescriptorLayout, null);
        self.vkd.destroyDescriptorSetLayout(self.dev, self.singleTextureSetLayout, null);
        self.vkd.destroySampler(self.dev, self.blockySampler, null);
        self.vkd.destroySampler(self.dev, self.linearSampler, null);
        self.vkd.destroyDescriptorPool(self.dev, self.descriptorPool, null);
    }

    pub fn destroy_textures(self: *Self) !void {
        {
            var iter = self.textures.iterator();

            while (iter.next()) |i| {
                i.value_ptr.*.deinit(self);
                self.allocator.destroy(i.value_ptr.*);
            }
            self.textures.deinit(self.allocator);
        }

        self.textureSets.deinit(self.allocator);
    }

    fn destroy_uploaders(self: *@This()) void {
        self.uploader.deinit();
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn shutdown(self: *Self) void {
        core.engine_logs("Tearing down renderer");
        core.forceFlush();

        while (self.outstandingJobsCount.load(.SeqCst) > 0) {
            std.debug.print("outstanding jobs: count = {d}\r", .{self.outstandingJobsCount.load(.SeqCst)});
            std.time.sleep(1000 * 1000 * 25);
        }

        std.debug.print("\n", .{});

        // clean out any existing assets in the assets ready queue
        vk_assetLoaders.discardAll();

        var i: isize = @intCast(self.destructionQueue.items.len - 1);
        while (i >= 0) : (i -= 1) {
            var dlambda = self.destructionQueue.items[@intCast(i)];
            dlambda.exec(self);
        }

        self.vkd.deviceWaitIdle(self.dev) catch unreachable;

        self.destroy_textures() catch {
            core.engine_errs("unable to destroy textures");
        };
        self.destroy_meshes() catch {
            core.engine_errs("unable to destroy meshes");
        };
        self.destroy_materials();
        self.destroy_descriptors();

        self.destroy_renderpass() catch {
            core.engine_errs("unable to destroy renderpass");
        };
        self.destroy_syncs() catch {
            core.engine_errs("unable to destroy syncs");
        };
        self.destroy_renderobjects() catch {
            core.engine_errs("unable to destroy renderObjects");
        };
        self.destroy_framebuffers() catch {
            core.engine_errs("unable to destroy framebuffers");
        };

        self.vkd.destroySwapchainKHR(self.dev, self.swapchain, null);

        self.destroy_uploaders();

        self.vkd.destroyCommandPool(self.dev, self.commandPool, null);

        if (self.vkAllocator.areAllocationsOutstanding()) {
            self.vkAllocator.printOutStandingAllocations();
        }

        self.vkAllocator.destroy();

        self.vkd.destroyDevice(self.dev, null);
        self.vki.destroySurfaceKHR(self.instance, self.surface, null);
        self.vki.destroyInstance(self.instance, null);

        for (self.enumeratedPhysicalDevices.items) |*enumerated| {
            enumerated.deinit();
        }
        self.enumeratedPhysicalDevices.deinit();
        self.graph.deinit();
        self.requiredExtensions.deinit(self.allocator);

        self.rendererPlugins.deinit(self.allocator);

        self.renderObjectsByMaterial.deinit(self.allocator);
        self.commandBuffers.deinit();
        self.destructionQueue.deinit(self.allocator);
        self.materials.deinit(self.allocator);
    }

    /// ---------- renderObject functions

    // this one treats the renderer like any other subsystem

    fn initRenderObject(self: *@This(), params: CreateRenderObjectParams) !RenderObject {
        var renderObject = RenderObject.fromTransform(params.init_transform);

        var findMesh = self.meshes.getEntry(params.mesh_name.handle());
        var findMat = self.materials.getEntry(params.material_name.handle());

        if (findMesh == null)
            return error.NoMeshFound;

        if (findMat == null)
            return error.NoMaterialFound;

        renderObject.material = findMat.?.value_ptr.*;
        renderObject.mesh = findMesh.?.value_ptr.*;
        renderObject.meshName = params.mesh_name;
        return renderObject;
    }

    pub fn addRenderObject(self: *Self, objectHandle: core.ObjectHandle, params: CreateRenderObjectParams) !ObjectHandle {
        var renderObject = try self.initRenderObject(params);

        var rv = try self.renderObjectSet.createWithHandle(objectHandle, .{ .renderObject = renderObject });
        self.renderObjectsAreDirty = true;

        return rv;
    }

    pub fn add_renderobject(self: *Self, params: CreateRenderObjectParams) !ObjectHandle {
        var renderObject = try self.initRenderObject(params);

        var rv = try self.renderObjectSet.createObject(.{ .renderObject = renderObject });
        self.renderObjectsAreDirty = true;

        return rv;
    }

    pub fn onExitSignal(self: @This()) core.RttiDataEventError!void {
        core.engine_logs("Renderer exit signaled");
        self.vkd.deviceWaitIdle(self.dev) catch return error.UnknownStatePanic;
    }
};

pub var gWindowName: []const u8 = "NeonWood Sample Application";

// must be called before graphics.start_module();
pub fn setWindowName(newWindowName: []const u8) void {
    gWindowName = newWindowName;
}

pub var gContext: *NeonVkContext = undefined;
pub var gGraphicsStartupSettings: struct {
    maxObjectCount: u32 = MAX_OBJECTS,
    consoleEnabled: bool = true,
    vulkanValidation: bool = true,
} = .{};
