const std = @import("std");
const vk = @import("vulkan");
const resources = @import("resources");
pub const c = @import("c.zig");
const graphics = @import("../graphics.zig");
const vma = @import("vma");
const core = @import("../core.zig");
const assets = @import("../assets.zig");
const tracy = core.tracy;
const vk_constants = @import("vk_constants.zig");
const vk_pipeline = @import("vk_pipeline.zig");
pub const NeonVkPipelineBuilder = vk_pipeline.NeonVkPipelineBuilder;
const mesh = @import("mesh.zig");
const render_objects = @import("render_object.zig");
const vkinit = @import("vk_init.zig");
const vk_utils = @import("vk_utils.zig");
const texture = @import("texture.zig");
const materials = @import("materials.zig");
const build_opts = @import("game_build_opts");
const RingQueue = core.RingQueue;

const enable_validation_layers: bool = build_opts.validation_layers;
// const enable_validation_layers: bool = false;
const NeonVkSceneManager = @import("vk_sceneobject.zig").NeonVkSceneManager;

const SparseSet = core.SparseSet;

pub const PixelPos = struct {
    x: u32,
    y: u32,

    /// returns y/x of the pixel position
    pub fn ratio(self: @This()) f32 {
        return @intToFloat(f32, self.y) / @intToFloat(f32, self.x);
    }
};

const MAX_OBJECTS = vk_constants.MAX_OBJECTS;

fn vkCast(comptime T: type, handle: anytype) T {
    return @ptrCast(T, @intToPtr(?*anyopaque, @intCast(usize, @enumToInt(handle))));
}

const ObjectHandle = core.ObjectHandle;
const MakeTypeName = core.MakeTypeName;

pub const RendererInterfaceRef = core.InterfaceRef(RendererInterface);

// RendererInterfaceVTable
pub const RendererInterface = struct {
    typeName: Name,
    typeSize: usize,
    typeAlign: usize,

    preDraw: *const fn (*anyopaque, frameId: usize) void,
    onBindObject: *const fn (*anyopaque, ObjectHandle, usize, vk.CommandBuffer, usize) void,
    postDraw: ?*const fn (*anyopaque, vk.CommandBuffer, usize, f64) void,

    pub fn from(comptime TargetType: type) @This() {
        const wrappedFuncs = struct {
            pub fn preDraw(pointer: *anyopaque, frameId: usize) void {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                ptr.preDraw(frameId);
            }

            pub fn onBindObject(pointer: *anyopaque, objectHandle: ObjectHandle, objectIndex: usize, cmd: vk.CommandBuffer, frameIndex: usize) void {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                ptr.onBindObject(objectHandle, objectIndex, cmd, frameIndex);
            }

            pub fn postDraw(pointer: *anyopaque, cmd: vk.CommandBuffer, frameIndex: usize, deltaTime: f64) void {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                ptr.postDraw(cmd, frameIndex, deltaTime);
            }
        };

        inline for (.{ "preDraw", "onBindObject" }) |declName| {
            if (!@hasDecl(TargetType, declName)) {
                @compileError(
                    std.fmt.comptimePrint(
                        "Tried to Generate {s} for type {s} but it's missing {s}",
                        .{ @typeName(@This()), @typeName(TargetType), declName },
                    ),
                );
            }
        }

        var self = @This(){
            .typeName = MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .preDraw = wrappedFuncs.preDraw,
            .onBindObject = wrappedFuncs.onBindObject,
            .postDraw = null,
        };

        if (@hasDecl(TargetType, "postDraw")) {
            self.postDraw = wrappedFuncs.postDraw;
        }

        return self;
    }
};

// Aliases
const p2a = core.p_to_a;
const p2av = core.p_to_av;
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

const NeonVkSpriteDataGpu = struct {
    // tl, tr, br, bl running clockwise
    position: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    size: Vector2f = .{ .x = 1.0, .y = 1.0 },
};

pub const NeonVkUploadContext = struct {
    uploadFence: vk.Fence,
    commandPool: vk.CommandPool,
    commandBuffer: vk.CommandBuffer,
    mutex: std.Thread.Mutex,
    active: bool,
};

pub const NeonVkCameraDataGpu = struct {
    view: Mat,
    proj: Mat,
    viewproj: Mat,
};

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

pub const NeonVkBuffer = struct {
    buffer: vk.Buffer,
    allocation: vma.Allocation,

    pub fn deinit(self: *NeonVkBuffer, allocator: vma.Allocator) void {
        allocator.destroyBuffer(self.buffer, self.allocation);
    }
};

pub const NeonVkImage = struct {
    image: vk.Image,
    allocation: vma.Allocation,
    pixelWidth: u32,
    pixelHeight: u32,

    pub fn deinit(self: *NeonVkImage, allocator: vma.Allocator) void {
        allocator.destroyImage(self.image, self.allocation);
    }

    /// returns the image ratio of the height over width
    pub inline fn getImageRatioFloat(self: @This()) f32 {
        return @intToFloat(f32, self.pixelHeight) / @intToFloat(f32, self.pixelWidth);
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

        // load device properties
        self.deviceProperties = vki.getPhysicalDeviceProperties(pdevice);
        core.graphics_log(" device Name: {s}", .{@ptrCast([*:0]u8, &self.deviceProperties.device_name)});

        core.graphics_log("  Found {d} family properties", .{count});
        if (count == 0)
            return error.NoPhysicalDeviceQueueFamilyProperties;
        try self.queueFamilyProperties.resize(@intCast(usize, count));
        vki.getPhysicalDeviceQueueFamilyProperties(pdevice, &count, self.queueFamilyProperties.items.ptr);

        // load supported extensions
        _ = try vki.enumerateDeviceExtensionProperties(pdevice, null, &count, null);
        core.graphics_log("  Found {d} extension properties", .{count});
        if (count > 0) {
            try self.supportedExtensions.resize(@intCast(usize, count));
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

pub const NeonVkContext = struct {
    const Self = @This();
    const NumFrames = vk_constants.NUM_FRAMES;
    pub const NeonObjectTable = core.RttiData.from(Self);

    const vertices = [_]Vertex{
        .{ .pos = .{ 0, -0.5 }, .color = .{ 1, 0, 0 } },
        .{ .pos = .{ 0.5, 0.5 }, .color = .{ 0, 1, 0 } },
        .{ .pos = .{ -0.5, 0.5 }, .color = .{ 0, 0, 1 } },
    };

    pub const maxMode = 3;

    const descriptorPoolSizes = [_]vk.DescriptorPoolSize{
        .{ .type = .uniform_buffer, .descriptor_count = 100 },
        .{ .type = .uniform_buffer_dynamic, .descriptor_count = 100 },
        .{ .type = .storage_buffer, .descriptor_count = 100 },
        .{ .type = .combined_image_sampler, .descriptor_count = 100 },
    };

    mode: u32,

    graph: core.FileLog,

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
    showDemo: bool,

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

    static_triangle_pipeline: vk.Pipeline,
    static_colored_triangle_pipeline: vk.Pipeline,

    vmaFunctions: vma.VulkanFunctions,
    vmaAllocator: vma.Allocator,

    exitSignal: bool,
    firstFrame: bool,
    shouldResize: bool,
    isMinimized: bool,

    renderObjectsAreDirty: bool,
    cameraMovement: Vectorf,

    renderObjectsByMaterial: ArrayListUnmanaged(u32),
    renderObjectSet: RenderObjectSet,

    textureSets: std.AutoHashMapUnmanaged(u32, *vk.DescriptorSet),

    materials: std.AutoHashMapUnmanaged(u32, *Material),
    meshes: std.AutoHashMapUnmanaged(u32, *Mesh),
    textures: std.AutoHashMapUnmanaged(u32, *Texture),
    cameraRef: ?*render_objects.Camera,

    blockySampler: vk.Sampler,
    linearSampler: vk.Sampler,

    descriptorPool: vk.DescriptorPool,
    globalDescriptorLayout: vk.DescriptorSetLayout,
    objectDescriptorLayout: vk.DescriptorSetLayout,
    spriteDescriptorLayout: vk.DescriptorSetLayout,

    frameData: [NumFrames]NeonVkFrameData,
    lastMaterial: ?*Material,
    lastMesh: ?*Mesh,
    lastTextureSet: ?*vk.DescriptorSet,

    sceneDataGpu: NeonVkSceneDataGpu,
    sceneParameterBuffer: NeonVkBuffer,
    uiObjects: ArrayListUnmanaged(core.UiObjectRef),
    rendererPlugins: ArrayListUnmanaged(RendererInterfaceRef),
    uploadContext: NeonVkUploadContext,

    singleTextureSetLayout: vk.DescriptorSetLayout,
    sceneManager: NeonVkSceneManager,

    shouldShowDebug: bool,

    pub fn setRenderObjectMesh(self: *@This(), objectHandle: core.ObjectHandle, meshName: core.Name) void {
        var meshRef = self.meshes.get(meshName.hash).?;
        self.renderObjectSet.get(objectHandle, .renderObject).?.*.mesh = meshRef;
        self.renderObjectSet.get(objectHandle, .renderObject).?.*.meshName = meshName;
    }

    pub fn setRenderObjectTexture(self: *@This(), objectHandle: core.ObjectHandle, textureName: core.Name) void {
        var textureSet = self.textureSets.get(textureName.hash).?;
        self.renderObjectSet.get(objectHandle, .renderObject).?.*.texture = textureSet;
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
            .x = @floatCast(f32, screenPos.x),
            .y = @floatCast(f32, screenPos.y),
        };

        if (self.actual_extent.width == 0 or self.actual_extent.height == 0) {
            return ray;
        }

        const i = core.zm.inverse(camera.projection);
        const iview = core.zm.inverse(camera.transform);
        const width = (@intToFloat(f32, self.actual_extent.width));
        const height = (@intToFloat(f32, self.actual_extent.height));

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

    pub fn init_zig_data(self: *Self) !void {
        core.graphics_log("NeonVkContext StaticSize = {d} bytes", .{@sizeOf(Self)});
        self.gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self.allocator = std.heap.c_allocator;
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
        self.uiObjects = .{};
        self.lastMaterial = null;
        self.cameraRef = null;
        self.lastMesh = null;
        self.showDemo = true;
        self.renderObjectsByMaterial = .{};
        self.renderObjectSet = RenderObjectSet.init(self.allocator);
        self.sceneManager = NeonVkSceneManager.init(self.allocator);
        self.uploadContext.mutex = .{};
    }

    pub fn add_plugin(self: *Self, interface: core.RendererInterfaceRef) !void {
        try self.rendererPlugins.append(interface);
    }

    pub fn add_ui_object(self: *Self, interface: core.UiObjectRef) !void {
        try self.uiObjects.append(self.allocator, interface);
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
            @ptrCast([*]const vk.SubmitInfo, &submit),
            context.uploadFence,
        );

        _ = try self.vkd.waitForFences(
            self.dev,
            1,
            @ptrCast([*]const vk.Fence, &context.uploadFence),
            1,
            1000000000,
        );
        try self.vkd.resetFences(self.dev, 1, @ptrCast([*]const vk.Fence, &context.uploadFence));
        context.active = false; //  replace this thing with a lock
        context.mutex.unlock();
    }

    pub fn pad_uniform_buffer_size(self: Self, originalSize: usize) usize {
        var alignment = @intCast(usize, self.physicalDeviceProperties.limits.min_uniform_buffer_offset_alignment);

        var alignedSize: usize = originalSize;
        if (alignment > 0) {
            alignedSize = (alignedSize + alignment - 1) & ~(alignment - 1);
        }

        return alignedSize;
    }

    pub fn init(allocator: std.mem.Allocator) Self {
        core.graphics_log("validation_layers: {any}", .{enable_validation_layers});
        core.graphics_log("release_build: {any}", .{build_opts.release_build});
        _ = allocator;
        return create_object() catch unreachable;
    }

    // this is the old version
    pub fn create_object() !Self {
        var self: Self = undefined;
        self.graph = try core.FileLog.init(std.heap.c_allocator, "renderer_graph.viz");
        try self.graph.write("digraph G {{\n", .{});

        try self.graph.write("  root->init_zig_data\n", .{});
        try self.init_zig_data();

        try self.graph.write("  root->init_glfw\n", .{});
        try self.init_glfw();

        try self.graph.write("  root->init_api\n", .{});
        try self.init_api();

        try self.graph.write("  root->init_device\n", .{});
        try self.init_device();

        try self.graph.write("  root->init_vma\n", .{});
        try self.init_vma();

        try self.graph.write("  root->init_command_pools\n", .{});
        try self.init_command_pools();

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

        try self.graph.write("}}\n", .{});
        try self.graph.writeOut();

        var childProc = std.ChildProcess.init(&.{ "dot", "-Tpng", "Saved/renderer_graph.viz", "-o", "Saved/renderer_graph.png" }, std.heap.c_allocator);
        try childProc.spawn();

        return self;
    }

    pub fn upload_texture_from_file(self: *@This(), texturePath: []const u8) !*Texture {
        var stagingResults = try vk_utils.load_and_stage_image_from_file(self, texturePath);
        try vk_utils.submit_copy_from_staging(self, stagingResults.stagingBuffer, stagingResults.image);
        var image = stagingResults.image;

        var imageViewCreate = vkinit.imageViewCreateInfo(.r8g8b8a8_srgb, image.image, .{ .color_bit = true });
        var imageView = try self.vkd.createImageView(self.dev, &imageViewCreate, null);
        var newTexture = try self.allocator.create(Texture);

        newTexture.* = Texture{
            .image = image,
            .imageView = imageView,
        };

        return newTexture;
    }

    pub fn create_mesh_image_for_texture(self: *@This(), inTexture: *Texture, params: struct { useBlocky: bool = true }) !*vk.DescriptorSet {
        var textureSet = try self.allocator.create(vk.DescriptorSet);
        var allocInfo = vk.DescriptorSetAllocateInfo{
            .descriptor_pool = self.descriptorPool,
            .descriptor_set_count = 1,
            .p_set_layouts = p2a(&self.singleTextureSetLayout),
        };

        try self.vkd.allocateDescriptorSets(self.dev, &allocInfo, @ptrCast([*]vk.DescriptorSet, textureSet));

        var imageBufferInfo = vk.DescriptorImageInfo{
            //.sampler = self.blockySampler,
            .sampler = if (params.useBlocky) self.blockySampler else self.linearSampler,
            .image_view = inTexture.imageView,
            .image_layout = .shader_read_only_optimal,
        };

        var writeDescriptorSet = vkinit.writeDescriptorImage(
            .combined_image_sampler,
            textureSet.*,
            &imageBufferInfo,
            0,
        );

        self.vkd.updateDescriptorSets(self.dev, 1, p2a(&writeDescriptorSet), 0, undefined);

        return textureSet;
    }

    pub fn install_texture_into_registry(self: *@This(), name: core.Name, textureRef: *Texture, textureSet: *vk.DescriptorSet) !void {
        try self.textures.put(self.allocator, name.hash, textureRef);
        try self.textureSets.put(self.allocator, name.hash, textureSet);
    }

    pub fn create_standard_texture_from_file(self: *Self, textureName: core.Name, texturePath: []const u8) !*Texture {
        var newTexture = try self.upload_texture_from_file(texturePath);
        try self.textures.put(self.allocator, textureName.hash, newTexture);
        return self.textures.getEntry(textureName.hash).?.value_ptr.*;
    }

    pub fn make_mesh_image_from_texture(self: *Self, name: core.Name, params: struct { useBlocky: bool = true }) !void {
        if (self.textureSets.contains(name.hash)) {
            return;
        }

        var textureSet = try self.allocator.create(vk.DescriptorSet);

        var allocInfo = vk.DescriptorSetAllocateInfo{
            .descriptor_pool = self.descriptorPool,
            .descriptor_set_count = 1,
            .p_set_layouts = p2a(&self.singleTextureSetLayout),
        };
        try self.vkd.allocateDescriptorSets(self.dev, &allocInfo, @ptrCast([*]vk.DescriptorSet, textureSet));

        var imageBufferInfo = vk.DescriptorImageInfo{
            //.sampler = self.blockySampler,
            .sampler = if (params.useBlocky) self.blockySampler else self.linearSampler,
            .image_view = (self.textures.get(name.hash)).?.imageView,
            .image_layout = .shader_read_only_optimal,
        };

        var writeDescriptorSet = vkinit.writeDescriptorImage(
            .combined_image_sampler,
            textureSet.*,
            &imageBufferInfo,
            0,
        );

        self.vkd.updateDescriptorSets(self.dev, 1, p2a(&writeDescriptorSet), 0, undefined);

        try self.textureSets.put(self.allocator, name.hash, textureSet);
    }

    pub fn load_core_textures(self: *Self) !void {
        _ = try self.create_standard_texture_from_file(core.MakeName("missing_texture"), "content/textures/texture_sample.png");
    }

    pub fn init_texture_descriptor(self: *Self) !void {
        var textureBinding = vkinit.descriptorSetLayoutBinding(.combined_image_sampler, .{ .fragment_bit = true }, 0);

        var singleTextureInfo = vk.DescriptorSetLayoutCreateInfo{
            .binding_count = 1,
            .flags = .{},
            .p_bindings = p2a(&textureBinding),
        };
        self.singleTextureSetLayout = try self.vkd.createDescriptorSetLayout(self.dev, &singleTextureInfo, null);
    }

    pub fn init_descriptors(self: *Self) !void {
        var poolInfo = vk.DescriptorPoolCreateInfo{
            .flags = .{},
            .max_sets = 100,
            .pool_size_count = @intCast(u32, descriptorPoolSizes.len),
            .p_pool_sizes = &descriptorPoolSizes,
        };

        self.descriptorPool = try self.vkd.createDescriptorPool(self.dev, &poolInfo, null);

        var cameraBufferBinding = vkinit.descriptorSetLayoutBinding(.uniform_buffer, .{ .vertex_bit = true }, 0);
        var sceneBinding = vkinit.descriptorSetLayoutBinding(.uniform_buffer_dynamic, .{ .vertex_bit = true, .fragment_bit = true }, 1);
        var bindings = [_]@TypeOf(sceneBinding){ cameraBufferBinding, sceneBinding };

        var setInfo = vk.DescriptorSetLayoutCreateInfo{
            .binding_count = 2,
            .flags = .{},
            .p_bindings = @ptrCast([*]const @TypeOf(sceneBinding), &bindings),
        };

        var objectBinding = vkinit.descriptorSetLayoutBinding(.storage_buffer, .{ .vertex_bit = true }, 0);
        var objectBindings = [_]@TypeOf(objectBinding){objectBinding};

        var objectSetInfo = vk.DescriptorSetLayoutCreateInfo{
            .binding_count = 1,
            .flags = .{},
            .p_bindings = @ptrCast([*]const @TypeOf(objectBinding), &objectBindings),
        };

        self.globalDescriptorLayout = try self.vkd.createDescriptorSetLayout(self.dev, &setInfo, null);
        self.objectDescriptorLayout = try self.vkd.createDescriptorSetLayout(self.dev, &objectSetInfo, null);

        const paddedSceneSize = self.pad_uniform_buffer_size(@sizeOf(NeonVkSceneDataGpu));
        core.graphics_log("padded scene size = {d}", .{paddedSceneSize});

        const sceneParamBufferSize = NumFrames * paddedSceneSize;
        core.graphics_log("NumFrames = {d}", .{NumFrames});

        self.sceneParameterBuffer = try self.create_buffer(sceneParamBufferSize, .{ .uniform_buffer_bit = true }, .cpuToGpu);

        for (core.count(NumFrames)) |_, i| {
            // detail the object descriptor set
            self.frameData[i].objectBuffer = try self.create_buffer(@sizeOf(NeonVkObjectDataGpu) * MAX_OBJECTS, .{ .storage_buffer_bit = true }, .cpuToGpu);

            var objectDescriptorSetAllocInfo = vk.DescriptorSetAllocateInfo{
                .descriptor_pool = self.descriptorPool,
                .descriptor_set_count = 1,
                .p_set_layouts = p2a(&self.objectDescriptorLayout),
            };

            try self.vkd.allocateDescriptorSets(self.dev, &objectDescriptorSetAllocInfo, @ptrCast([*]vk.DescriptorSet, &self.frameData[i].objectDescriptorSet));

            var objectInfo = vk.DescriptorBufferInfo{
                .buffer = self.frameData[i].objectBuffer.buffer,
                .offset = 0,
                .range = @sizeOf(NeonVkObjectDataGpu) * MAX_OBJECTS,
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
            self.frameData[i].cameraBuffer = try self.create_buffer(@sizeOf(NeonVkCameraDataGpu), .{ .uniform_buffer_bit = true }, .cpuToGpu);

            var allocInfo = vk.DescriptorSetAllocateInfo{
                .descriptor_pool = self.descriptorPool,
                .descriptor_set_count = 1,
                .p_set_layouts = p2a(&self.globalDescriptorLayout),
            };
            try self.vkd.allocateDescriptorSets(self.dev, &allocInfo, @ptrCast([*]vk.DescriptorSet, &self.frameData[i].globalDescriptorSet));

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

        // try self.create_sprite_descriptors();
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
        try self.meshes.put(self.allocator, core.MakeName("mesh_quad").hash, quadMesh);
    }

    // we need a content filing system
    pub fn new_mesh_from_obj(self: *Self, meshName: core.Name, filename: []const u8) !*mesh.Mesh {
        var newMesh = try self.allocator.create(mesh.Mesh);
        newMesh.* = mesh.Mesh.init(self, self.allocator);
        try newMesh.load_from_obj_file(filename);
        try newMesh.upload(self);
        try self.meshes.put(self.allocator, meshName.hash, newMesh);
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

        const results = try self.vmaAllocator.createBuffer(bci, vmaCreateInfo);

        var allocatedBuffer = NeonVkBuffer{
            .buffer = results.buffer,
            .allocation = results.allocation,
        };
        defer allocatedBuffer.deinit(self.vmaAllocator);

        {
            var data = try self.vmaAllocator.mapMemory(allocatedBuffer.allocation, u8);
            @memcpy(data, @ptrCast([*]const u8, uploadedMesh.vertices.items.ptr), bufferSize);
            self.vmaAllocator.unmapMemory(allocatedBuffer.allocation);
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

        const gpuBufferResults = try self.vmaAllocator.createBuffer(gpuBci, gpuVmaCreateInfo);

        uploadedMesh.buffer = NeonVkBuffer{
            .buffer = gpuBufferResults.buffer,
            .allocation = gpuBufferResults.allocation,
        };

        core.graphics_log("Staring upload context", .{});
        try self.start_upload_context(&self.uploadContext);
        {
            var copy = vk.BufferCopy{
                .dst_offset = 0,
                .src_offset = 0,
                .size = bufferSize,
            };
            const cmd = self.uploadContext.commandBuffer;
            core.graphics_log("Starting command copy buffer", .{});
            self.vkd.cmdCopyBuffer(
                cmd,
                allocatedBuffer.buffer,
                uploadedMesh.buffer.buffer,
                1,
                @ptrCast([*]const vk.BufferCopy, &copy),
            );
        }
        core.graphics_log("Finishing upload context", .{});
        try self.finish_upload_context(&self.uploadContext);
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

        const results = try self.vmaAllocator.createBuffer(bci, vmaCreateInfo);

        var buffer = NeonVkBuffer{
            .buffer = results.buffer,
            .allocation = results.allocation,
        };

        var data = try self.vmaAllocator.mapMemory(buffer.allocation, u8);
        defer self.vmaAllocator.unmapMemory(buffer.allocation);

        @memcpy(data, @ptrCast([*]const u8, uploadedMesh.vertices.items.ptr), size);

        return buffer;
    }

    pub fn init_vma(self: *Self) !void {
        self.vmaFunctions = vma.VulkanFunctions.init(self.instance, self.dev, self.vkb.dispatch.vkGetInstanceProcAddr);
        try self.graph.write("  init_vma->\"vma@0x{x}\"\n", .{@ptrToInt(&self.vmaAllocator)});

        self.vmaAllocator = try vma.Allocator.create(.{
            .instance = self.instance,
            .physicalDevice = self.physicalDevice,
            .device = self.dev,
            .frameInUseCount = NumFrames,
            .pVulkanFunctions = &self.vmaFunctions,
        });
    }

    fn create_mesh_material(self: *Self) !void {
        // Creates teh standard mesh pipeline, this pipeline is statically stored as
        // mat_mesh
        core.graphics_logs("Creating mesh pipeline");

        // Initialize the pipeline with the default triangle mesh shader
        // and the default lighting shader
        var pipeline_builder = try NeonVkPipelineBuilder.init(
            self.dev,
            self.vkd,
            self.allocator,
            resources.triangle_mesh_vert.len,
            @ptrCast([*]const u32, &resources.triangle_mesh_vert),
            resources.default_lit_frag.len,
            @ptrCast([*]const u32, &resources.default_lit_frag),
        );
        defer pipeline_builder.deinit();

        try pipeline_builder.add_mesh_description();
        try pipeline_builder.add_push_constant();
        try pipeline_builder.add_layout(self.globalDescriptorLayout);
        try pipeline_builder.add_layout(self.objectDescriptorLayout);
        try pipeline_builder.add_layout(self.singleTextureSetLayout);
        try pipeline_builder.add_depth_stencil();
        try pipeline_builder.init_triangle_pipeline(self.actual_extent);

        const materialName = core.MakeName("mat_mesh");

        var material = try self.allocator.create(Material);
        material.* = Material{
            .materialName = materialName,
            .pipeline = (try pipeline_builder.build(self.renderPass)).?,
            .layout = pipeline_builder.pipelineLayout,
        };

        var allocInfo = vk.DescriptorSetAllocateInfo{
            .descriptor_pool = self.descriptorPool,
            .descriptor_set_count = 1,
            .p_set_layouts = p2a(&self.singleTextureSetLayout),
        };
        try self.vkd.allocateDescriptorSets(self.dev, &allocInfo, @ptrCast([*]vk.DescriptorSet, &material.textureSet));

        // --------- set up the image
        var imageBufferInfo = vk.DescriptorImageInfo{
            .sampler = self.blockySampler,
            .image_view = (self.textures.get(core.MakeName("missing_texture").hash)).?.imageView,
            .image_layout = .shader_read_only_optimal,
        };
        try self.materials.put(self.allocator, materialName.hash, material);

        var descriptorSet = vkinit.writeDescriptorImage(
            .combined_image_sampler,
            self.materials.get(materialName.hash).?.textureSet,
            &imageBufferInfo,
            0,
        );

        self.vkd.updateDescriptorSets(self.dev, 1, p2a(&descriptorSet), 0, undefined);
        // ---------------
    }

    pub fn add_material(self: *@This(), material: *Material) !void {
        try self.materials.put(self.allocator, material.materialName.hash, material);
    }

    pub fn init_pipelines(self: *Self) !void {
        var static_tri_builder = try NeonVkPipelineBuilder.init(
            self.dev,
            self.vkd,
            self.allocator,
            resources.triangle_vert_static.len,
            @ptrCast([*]const u32, &resources.triangle_vert_static),
            resources.triangle_frag_static.len,
            @ptrCast([*]const u32, &resources.triangle_frag_static),
        );

        try static_tri_builder.init_triangle_pipeline(self.actual_extent);
        try static_tri_builder.add_depth_stencil();
        self.static_triangle_pipeline = (try static_tri_builder.build(self.renderPass)).?;
        self.vkd.destroyPipelineLayout(self.dev, static_tri_builder.pipelineLayout, null);
        defer static_tri_builder.deinit();

        var colored_tri_b = try NeonVkPipelineBuilder.init(
            self.dev,
            self.vkd,
            self.allocator,
            resources.triangle_vert_colored.len,
            @ptrCast([*]const u32, &resources.triangle_vert_colored),
            resources.triangle_frag_colored.len,
            @ptrCast([*]const u32, &resources.triangle_frag_colored),
        );
        try colored_tri_b.init_triangle_pipeline(self.actual_extent);
        try colored_tri_b.add_depth_stencil();
        self.static_colored_triangle_pipeline = (try colored_tri_b.build(self.renderPass)).?;
        self.vkd.destroyPipelineLayout(self.dev, colored_tri_b.pipelineLayout, null);
        defer colored_tri_b.deinit();

        var samplerCreateInfo = vkinit.samplerCreateInfo(.nearest, null);
        self.blockySampler = try self.vkd.createSampler(self.dev, &samplerCreateInfo, null);

        var linearCreateSample = vkinit.samplerCreateInfo(.linear, null);
        self.linearSampler = try self.vkd.createSampler(self.dev, &linearCreateSample, null);

        try self.create_mesh_material();
        // try self.create_sprite_material();

        core.graphics_logs("Finishing up pipeline creation");
    }

    // this creates decriptors for sprites
    pub fn create_sprite_descriptors(self: *Self) !void {
        var bindings = [_]vk.DescriptorSetLayoutBinding{
            vkinit.descriptorSetLayoutBinding(.storage_buffer, .{ .vertex_bit = true }, 0),
        };

        var setLayoutCreateInfo = vk.DescriptorSetLayoutCreateInfo{
            .flags = .{},
            .binding_count = bindings.len,
            .p_bindings = @ptrCast([*]const vk.DescriptorSetLayoutBinding, &bindings),
        };

        self.spriteDescriptorLayout = try self.vkd.createDescriptorSetLayout(self.dev, &setLayoutCreateInfo, null);

        var i: usize = 0;
        while (i < NumFrames) : (i += 1) {
            self.frameData[i].spriteBuffer = try self.create_buffer(@sizeOf(NeonVkSpriteDataGpu) * MAX_OBJECTS, .{ .storage_buffer_bit = true }, .cpuToGpu);

            var spriteDescriptorSetAllocInfo = vk.DescriptorSetAllocateInfo{
                .descriptor_pool = self.descriptorPool,
                .descriptor_set_count = 1,
                .p_set_layouts = p2a(&self.spriteDescriptorLayout),
            };

            try self.vkd.allocateDescriptorSets(
                self.dev,
                &spriteDescriptorSetAllocInfo,
                @ptrCast([*]vk.DescriptorSet, &self.frameData[i].spriteDescriptorSet),
            );

            var spriteInfo = vk.DescriptorBufferInfo{
                .buffer = self.frameData[i].spriteBuffer.buffer,
                .offset = 0,
                .range = @sizeOf(NeonVkSpriteDataGpu) * MAX_OBJECTS,
            };

            var spriteWrite = vkinit.writeDescriptorSet(
                .storage_buffer,
                self.frameData[i].spriteDescriptorSet,
                &spriteInfo,
                0,
            );

            var spriteSetWrites = [_]@TypeOf(spriteWrite){spriteWrite};
            self.vkd.updateDescriptorSets(self.dev, 1, &spriteSetWrites, 0, undefined);
        }
    }

    pub fn create_sprite_material(self: *Self) !void {

        // Create basically the same material as the mesh pipeline
        core.graphics_logs("creating sprite material");
        var spritePipelineBuilder = try NeonVkPipelineBuilder.init(
            self.dev,
            self.vkd,
            self.allocator,
            resources.triangle_mesh_vert.len,
            @ptrCast([*]const u32, resources.triangle_mesh_vert),
            resources.default_lit_frag.len,
            @ptrCast([*]const u32, resources.default_lit_frag),
        );
        defer spritePipelineBuilder.deinit();

        // leverages the same mesh desription
        try spritePipelineBuilder.add_mesh_description();
        try spritePipelineBuilder.init_triangle_pipeline(self.actual_extent);
        try spritePipelineBuilder.add_push_constant();
        try spritePipelineBuilder.add_layout(self.globalDescriptorLayout);
        try spritePipelineBuilder.add_layout(self.spriteObjectDescriptorLayout);
        try spritePipelineBuilder.add_layout(self.singleTextureSetLayout);
        try spritePipelineBuilder.add_depth_stencil();
        try spritePipelineBuilder.init_triangle_pipeline(self.actual_extent);

        var material = Material{
            .pipeline = (try spritePipelineBuilder.build(self.renderPass)).?,
            .layout = spritePipelineBuilder.pipelineLayout,
        };

        try self.materials.put(self.allocator, core.MakeName("mat_sprite"), material);
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

    fn updateTime(self: *Self, deltaTime: f64) void {
        self.rendererTime += deltaTime;
    }

    pub fn tick(self: *Self, dt: f64) void {
        self.draw(dt) catch unreachable;
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
        var data = try self.vmaAllocator.mapMemory(self.frameData[self.nextFrameIndex].cameraBuffer.allocation, u8);
        z2.End();

        // resolve the current state of the camera
        var projection_matrix: Mat = core.zm.identity();
        if (self.cameraRef != null) {
            projection_matrix = self.cameraRef.?.final;
        }

        var cameraData = NeonVkCameraDataGpu{
            .proj = core.zm.identity(),
            .view = core.zm.identity(),
            .viewproj = projection_matrix,
        };

        var z3 = tracy.ZoneN(@src(), "Uploading");
        @memcpy(data, @ptrCast([*]const u8, &cameraData), @sizeOf(NeonVkCameraDataGpu));
        z3.End();

        var z4 = tracy.ZoneN(@src(), "unmapping");
        self.vmaAllocator.unmapMemory(self.frameData[self.nextFrameIndex].cameraBuffer.allocation);
        z4.End();
    }

    pub fn acquire_next_frame(self: *Self) !void {
        var z1 = tracy.Zone(@src());
        z1.Name("waiting for frame");
        defer z1.End();
        self.nextFrameIndex = try self.getNextSwapImage();

        _ = try self.vkd.waitForFences(
            self.dev,
            1,
            @ptrCast([*]const vk.Fence, &self.commandBufferFences.items[self.nextFrameIndex]),
            1,
            1000000000,
        );
        try self.vkd.resetFences(self.dev, 1, @ptrCast([*]const vk.Fence, &self.commandBufferFences.items[self.nextFrameIndex]));
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
            .p_clear_values = @ptrCast([*]const vk.ClearValue, &clearValues),
        };

        self.vkd.cmdBeginRenderPass(cmd, &rpbi, .@"inline");

        self.vkd.cmdSetViewport(cmd, 0, 1, p2a(&self.viewport));
        self.vkd.cmdSetScissor(cmd, 0, 1, p2a(&self.scissor));
    }

    pub fn finish_main_renderpass(self: *Self, cmd: vk.CommandBuffer) !void {
        self.vkd.cmdEndRenderPass(cmd);
    }

    pub fn drawDebugUi(self: *Self) void {
        var windowVal = c.igBegin("Graphics Debug Ui", &self.shouldShowDebug, 0);
        defer c.igEnd();

        if (!windowVal) {
            self.shouldShowDebug = false;
            return;
        }

        c.igText("Materials List:");
        var iter = self.materials.iterator();
        while (iter.next()) |i| {
            c.igText(i.value_ptr.*.materialName.utf8.ptr);
        }
    }

    pub fn draw_ui(self: *Self, deltaTime: f64) !void {
        c.cImGui_vk_NewFrame();
        c.ImGui_ImplGlfw_NewFrame();
        c.igNewFrame();

        if (self.shouldShowDebug) {
            self.drawDebugUi();
        }

        for (self.uiObjects.items) |*uiObject| {
            uiObject.vtable.uiTick_func(uiObject.ptr, deltaTime);
        }

        c.igRender();
    }

    pub fn draw(self: *Self, deltaTime: f64) !void {
        self.updateTime(deltaTime);

        core.gScene.updateTransforms();
        try self.sceneManager.update(self);

        if (!self.isMinimized) {
            var z1 = tracy.Zone(@src());
            z1.Name("drawing UI");
            try self.draw_ui(deltaTime);
            z1.End();

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

            var z3 = tracy.ZoneNC(@src(), "Imgui Render", 0x0011FF11);
            c.cImGui_vk_RenderDrawData(c.igGetDrawData(), vkCast(c.VkCommandBuffer, cmd), vkCast(c.VkPipeline, vk.Pipeline.null_handle));
            z3.End();

            try self.finish_main_renderpass(cmd);
            try self.vkd.endCommandBuffer(cmd);
            z2.End();

            var z = tracy.ZoneN(@src(), "Imgui Finishing platform");
            c.igUpdatePlatformWindows();
            c.igRenderPlatformWindowsDefault(null, null);
            z.End();

            var x = tracy.ZoneN(@src(), "End of Frame");
            try self.finish_frame();
            x.End();
        } else {
            var w: c_int = undefined;
            var h: c_int = undefined;
            c.glfwGetWindowSize(self.window, &w, &h);

            if ((self.extent.width != @intCast(u32, w) or self.extent.height != @intCast(u32, h)) and
                (w > 0 and h > 0))
            {
                self.extent = .{ .width = @intCast(u32, w), .height = @intCast(u32, h) };

                self.isMinimized = false;
                try self.vkd.deviceWaitIdle(self.dev);
                try self.destroy_framebuffers();
                self.shouldResize = false;

                try self.init_or_recycle_swapchain();
                try self.init_framebuffers();
                c.setFontScale(@intCast(c_int, self.actual_extent.width), @intCast(c_int, self.actual_extent.height));
            }

            if (w <= 0 or h <= 0) {
                self.isMinimized = true;
                self.extent.width = @intCast(u32, w);
                self.extent.height = @intCast(u32, h);
            }

            c.glfwPollEvents();
            self.firstFrame = false;

            std.time.sleep(1000 * 1000);
        }
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

        const paddedSceneSize = @intCast(u32, self.pad_uniform_buffer_size(@sizeOf(NeonVkSceneDataGpu)));
        var startOffset: u32 = paddedSceneSize * self.nextFrameIndex;

        var z1 = tracy.ZoneNC(@src(), "draw render object", 0xBB44BB);
        if (self.lastMaterial != render_object.material) {
            self.vkd.cmdBindPipeline(cmd, .graphics, pipeline);
            self.lastMaterial = render_object.material;
            self.vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 0, 1, p2a(&self.frameData[self.nextFrameIndex].globalDescriptorSet), 1, p2a(&startOffset));
            self.vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 1, 1, p2a(&self.frameData[self.nextFrameIndex].objectDescriptorSet), 0, undefined);
        }
        defer z1.End();

        // if the renderobject has a textureset as an override use that instead of the default one on the material.
        if (render_object.texture) |textureSet| {
            self.vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 2, 1, p2a(textureSet), 0, undefined);
        } else {
            self.vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 2, 1, p2a(&render_object.material.?.textureSet), 0, undefined);
        }

        // let plugins bind the render object.
        for (self.rendererPlugins.items) |*plugin| {
            plugin.vtable.onBindObject(plugin.ptr, objectHandle, index, cmd, self.nextFrameIndex);
        }

        if (self.lastMesh != render_object.mesh) {
            self.lastMesh = render_object.mesh;
            self.vkd.cmdBindVertexBuffers(cmd, 0, 1, p2a(&object_mesh.buffer.buffer), p2a(&offset));
        }

        // if (self.lastMesh != render_object.mesh) {
        //     self.lastMesh = render_object.mesh;
        //     self.vkd.cmdBindVertexBuffers(cmd, 0, 1, p2a(&object_mesh.buffer.buffer), p2a(&offset));
        // }

        var final = render_object.transform;
        var constants = NeonVkMeshPushConstant{
            .data = .{ .x = 0, .y = 0, .z = 0, .w = 0 },
            .render_matrix = final,
        };

        self.vkd.cmdPushConstants(cmd, layout, .{ .vertex_bit = true }, 0, @sizeOf(NeonVkMeshPushConstant), &constants);

        self.vkd.cmdDraw(cmd, @intCast(u32, object_mesh.vertices.items.len), 1, 0, index);
    }

    fn upload_scene_global_data(self: *Self, deltaTime: f64) !void {
        _ = deltaTime;
        var data = try self.vmaAllocator.mapMemory(self.sceneParameterBuffer.allocation, u8);
        const paddedSceneSize = self.pad_uniform_buffer_size(@sizeOf(NeonVkSceneDataGpu));
        const startOffset = paddedSceneSize * self.nextFrameIndex;

        @memcpy(data + startOffset, @ptrCast([*]const u8, &self.sceneDataGpu), @sizeOf(@TypeOf(self.sceneDataGpu)));

        self.vmaAllocator.unmapMemory(self.sceneParameterBuffer.allocation);
    }

    fn upload_object_data(self: *Self) !void {
        const allocation = self.frameData[self.nextFrameIndex].objectBuffer.allocation;
        var data = try self.vmaAllocator.mapMemory(allocation, NeonVkObjectDataGpu);
        var ssbo: []NeonVkObjectDataGpu = undefined;
        ssbo.ptr = @ptrCast([*]NeonVkObjectDataGpu, data);
        ssbo.len = MAX_OBJECTS;

        var i: usize = 0;
        while (i < MAX_OBJECTS and i < self.renderObjectSet.dense.len) : (i += 1) {
            var object = self.renderObjectSet.dense.items(.renderObject)[i];
            if (object.mesh != null) {
                ssbo[i].modelMatrix = self.renderObjectSet.dense.items(.renderObject)[i].transform;
            }
        }

        // unmapping every frame might actually be quite unessecary.
        self.vmaAllocator.unmapMemory(allocation);
    }

    pub fn upload_sprite_data(self: *Self) !void {
        const allocation = self.frameData[self.nextFrameIndex].spriteBuffer.allocation;
        var data = try self.vmaAllocator.mapMemory(allocation, NeonVkObjectDataGpu);
        var ssbo: []NeonVkSpriteDataGpu = undefined;
        ssbo.ptr = @ptrCast([*]NeonVkSpriteDataGpu, data);
        ssbo.len = MAX_OBJECTS;

        var i: usize = 0;
        while (i < MAX_OBJECTS and i < self.renderObjectSet.dense.len) : (i += 1) {
            ssbo[i].position = mul(
                self.renderObjectSet.items(.renderObject)[i].transform,
                core.zm.Vec{ 0.0, 0.0, 0.0, 0.0 },
            );
            ssbo[i].size = .{ .x = 1.0, .y = 1.0 };
        }

        self.vmaAllocator.unmapMemory(allocation);
    }

    fn render_meshes(self: *Self, deltaTime: f64) !void {
        var z = tracy.ZoneNC(@src(), "render meshes", 0xAAFFFF);
        defer z.End();
        var z1 = tracy.ZoneNC(@src(), "uploading global and object data", 0xAAFFAA);
        try self.upload_scene_global_data(deltaTime);
        try self.upload_object_data();
        z1.End();
        // try self.upload_sprite_data();

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
        for (self.renderObjectSet.dense.items(.renderObject)) |dense, i| {
            // holy moly i really should make a convenience function for this.
            // dense to sparse given a known dense index
            var sparseHandle = self.renderObjectSet.sparse[self.renderObjectSet.denseIndices.items[i].index];
            sparseHandle.index = self.renderObjectSet.denseIndices.items[i].index;
            self.draw_render_object(dense, cmd, @intCast(u32, i), deltaTime, sparseHandle);
        }
        z2.End();
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

        if ((outOfDate or self.extent.width != @intCast(u32, w) or self.extent.height != @intCast(u32, h)) and
            (w > 0 and h > 0))
        {
            self.extent = .{ .width = @intCast(u32, w), .height = @intCast(u32, h) };

            self.isMinimized = false;
            try self.vkd.deviceWaitIdle(self.dev);
            try self.destroy_framebuffers();
            self.shouldResize = false;

            try self.init_or_recycle_swapchain();
            try self.init_framebuffers();
            c.setFontScale(@intCast(c_int, self.actual_extent.width), @intCast(c_int, self.actual_extent.height));
        }

        if (w <= 0 or h <= 0) {
            self.isMinimized = true;
        }

        c.glfwPollEvents();
        self.firstFrame = false;
    }

    fn destroy_framebuffers(self: *Self) !void {
        self.vkd.destroyImageView(self.dev, self.depthImageView, null);
        self.depthImage.deinit(self.vmaAllocator);
        for (self.framebuffers.items) |framebuffer| {
            self.vkd.destroyFramebuffer(self.dev, framebuffer, null);
        }
        self.framebuffers.deinit();
        for (self.swapImages.items) |_, i| {
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

        for (self.swapImages.items) |image, i| {
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
            .attachment = @intCast(u32, attachments.items.len),
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
            .attachment = @intCast(u32, attachments.items.len),
            .layout = .depth_stencil_attachment_optimal,
        };
        try attachments.append(depthAttachment);

        var subpass = std.mem.zeroes(vk.SubpassDescription);
        subpass.flags = .{};
        subpass.pipeline_bind_point = .graphics;
        subpass.input_attachment_count = 0;
        subpass.color_attachment_count = 1;
        subpass.p_color_attachments = @ptrCast([*]const vk.AttachmentReference, &colorAttachmentRef);
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
        rpci.attachment_count = @intCast(u32, attachments.items.len);
        rpci.p_attachments = attachments.items.ptr;
        rpci.subpass_count = 1;
        rpci.p_subpasses = @ptrCast([*]const vk.SubpassDescription, &subpass);
        rpci.dependency_count = 2;
        rpci.p_dependencies = &dependencies;
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

        self.viewport = vk.Viewport{
            .x = 0,
            .y = 0,
            .width = @intToFloat(f32, self.actual_extent.width),
            .height = @intToFloat(f32, self.actual_extent.height),
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

        var dimg_create = vk.ImageCreateInfo{
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

        var dimg_vma_alloc_info = vma.AllocationCreateInfo{
            .requiredFlags = .{
                .device_local_bit = true,
            },
            .usage = .gpuOnly,
        };

        var result = try self.vmaAllocator.createImage(dimg_create, dimg_vma_alloc_info);

        self.depthImage = .{
            .image = result.image,
            .allocation = result.allocation,
            .pixelWidth = self.actual_extent.width,
            .pixelHeight = self.actual_extent.height,
        };

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

        var upload_fci = fci;
        upload_fci.flags.signaled_bit = false;
        self.uploadContext.uploadFence = try self.vkd.createFence(self.dev, &upload_fci, null);

        var cbai2 = vk.CommandBufferAllocateInfo{
            .command_pool = self.uploadContext.commandPool,
            .level = vk.CommandBufferLevel.primary,
            .command_buffer_count = 1,
        };

        try self.vkd.allocateCommandBuffers(
            self.dev,
            &cbai2,
            @ptrCast([*]vk.CommandBuffer, &self.uploadContext.commandBuffer),
        );
    }

    pub fn init_command_pools(self: *Self) !void {
        var cpci = vk.CommandPoolCreateInfo{ .flags = .{}, .queue_family_index = undefined };
        cpci.flags.reset_command_buffer_bit = true;
        cpci.queue_family_index = @intCast(u32, self.graphicsFamilyIndex);

        self.commandPool = try self.vkd.createCommandPool(self.dev, &cpci, null);

        var cpci2 = vkinit.commandPoolCreateInfo(@intCast(u32, self.graphicsFamilyIndex), .{ .reset_command_buffer_bit = true });
        self.uploadContext.commandPool = try self.vkd.createCommandPool(self.dev, &cpci2, null);
    }

    fn init_api(self: *Self) !void {
        self.vkb = try BaseDispatch.load(c.glfwGetInstanceProcAddress);

        try self.graph.write("  init_api->\"BaseDispatch@0x{x}\" [style=dotted]\n", .{@ptrToInt(&self.vkb)});

        try self.graph.write("  init_api->create_vulkan_instance\n", .{});
        try self.create_vulkan_instance();
        errdefer self.vki.destroyInstance(self.instance, null);

        // create KHR surface structure
        try self.graph.write("  init_api->create_surface\n", .{});
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
        // _ = try self.check_required_vulkan_layers(ExtraLayers[0..]);

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
            .enabled_layer_count = if (enable_validation_layers) 1 else 0,
            .pp_enabled_layer_names = @ptrCast([*]const [*:0]const u8, &ExtraLayers[0]),
            .enabled_extension_count = glfwExtensionsCount,
            .pp_enabled_extension_names = @ptrCast([*]const [*:0]const u8, glfwExtensions),
        };

        try self.graph.write("  create_vulkan_instance->\"vkb.createInstance\"\n", .{});
        self.instance = try self.vkb.createInstance(&icis, null);

        try self.graph.write("  create_vulkan_instance->\"vki.load\"\n", .{});
        // load vulkan per instance functions
        self.vki = try InstanceDispatch.load(self.instance, c.glfwGetInstanceProcAddress);
    }

    fn init_device(self: *Self) !void {
        try self.graph.write("  init_device->create_physical_devices\n", .{});
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

        var shaderDrawFeatures = vk.PhysicalDeviceShaderDrawParametersFeatures{
            .shader_draw_parameters = vk.TRUE,
        };

        var dci = vk.DeviceCreateInfo{
            .flags = .{},
            .p_next = &shaderDrawFeatures,
            .queue_create_info_count = @intCast(u32, createQueueInfoList.items.len),
            .p_queue_create_infos = createQueueInfoList.items.ptr,
            .enabled_layer_count = 1,
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
                return @ptrToInt(ctx.renderObjectSet.dense.items(.renderObject)[lhs].material) < @ptrToInt(ctx.renderObjectSet.dense.items(.renderObject)[rhs].material);
            }
        };

        std.sort.sort(
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
                core.graphics_log("GPU minimum buffer alignment {d}", .{self.physicalDeviceProperties.limits.min_uniform_buffer_offset_alignment});
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

            try self.graph.write(
                "  enumerate_physical_devices->\"device:{s}:{*}\"\n",
                .{
                    @ptrCast([*:0]const u8, &self.enumeratedPhysicalDevices.items[i].deviceProperties.device_name),
                    devices.ptr,
                },
            );
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

        self.presentMode = .fifo_khr;
        //self.presentMode = .mailbox_khr;
    }

    pub fn get_layer_extensions(self: *Self) ![]const vk.LayerProperties {
        var count: u32 = 0;
        _ = try self.vkb.enumerateInstanceLayerProperties(&count, null);

        var data = try self.allocator.alloc(vk.LayerProperties, count);
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

        self.extent = .{ .width = 1600, .height = 900 };
        self.windowName = @ptrCast([*c]const u8, gWindowName);

        c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);

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
        var pixels: ?*u8 = core.stbi_load(graphics.icon.ptr, &w, &h, &comp, core.STBI_rgb_alpha);
        var iconImage = c.GLFWimage{
            .width = w,
            .height = h,
            .pixels = pixels,
        };
        debug_struct("loaded image: ", iconImage);
        c.glfwSetWindowIcon(self.window, 1, &iconImage);
        c.glfwSetWindowAspectRatio(self.window, 16, 9);
        defer core.stbi_image_free(pixels);
    }

    pub fn destroy_upload_context(self: *Self, context: *NeonVkUploadContext) !void {
        self.vkd.destroyCommandPool(self.dev, context.commandPool, null);
        self.vkd.destroyFence(self.dev, context.uploadFence, null);
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
    }

    pub fn destroy_renderobjects(self: *Self) !void {
        self.renderObjectSet.deinit();
    }

    pub fn create_buffer(
        self: Self,
        allocSize: usize,
        usage: vk.BufferUsageFlags,
        memoryUsageFlags: vma.MemoryUsage,
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

        var result = try self.vmaAllocator.createBuffer(cbi, vma_alloc_info);

        var rv = NeonVkBuffer{
            .buffer = result.buffer,
            .allocation = result.allocation,
        };

        return rv;
    }

    pub fn destroy_materials(self: *Self) void {
        var iter = self.materials.iterator();
        while (iter.next()) |i| {
            i.value_ptr.*.deinit(self);
            self.allocator.destroy(i.value_ptr.*);
        }
    }

    pub fn destroy_descriptors(self: *Self) void {
        for (self.frameData) |_, i| {
            self.frameData[i].cameraBuffer.deinit(self.vmaAllocator);
            // self.frameData[i].spriteBuffer.deinit(self.vmaAllocator);
            self.frameData[i].objectBuffer.deinit(self.vmaAllocator);
        }
        self.sceneParameterBuffer.deinit(self.vmaAllocator);

        self.vkd.destroyDescriptorSetLayout(self.dev, self.objectDescriptorLayout, null);
        self.vkd.destroyDescriptorSetLayout(self.dev, self.globalDescriptorLayout, null);
        self.vkd.destroyDescriptorSetLayout(self.dev, self.singleTextureSetLayout, null);
        self.vkd.destroySampler(self.dev, self.blockySampler, null);
        self.vkd.destroySampler(self.dev, self.linearSampler, null);
        self.vkd.destroyDescriptorPool(self.dev, self.descriptorPool, null);
    }

    pub fn destroy_textures(self: *Self) !void {
        var iter = self.textures.iterator();
        while (iter.next()) |i| {
            try i.value_ptr.*.deinit(self);
            self.allocator.destroy(i.value_ptr.*);
        }
    }

    pub fn shutdown_glfw(self: *Self) void {
        _ = self;
    }

    pub fn deinit(self: *Self) void {
        self.vkd.deviceWaitIdle(self.dev) catch unreachable;

        self.destroy_pipelines() catch unreachable;
        self.destroy_renderpass() catch unreachable;
        self.destroy_syncs() catch unreachable;
        self.destroy_renderobjects() catch unreachable;
        self.destroy_textures() catch unreachable;
        self.destroy_meshes() catch unreachable;
        self.destroy_framebuffers() catch unreachable;
        self.destroy_upload_context(&self.uploadContext) catch unreachable;

        self.destroy_materials();
        self.destroy_descriptors();

        self.uiObjects.deinit(self.allocator);

        self.vmaAllocator.destroy();

        self.vkd.destroyCommandPool(self.dev, self.commandPool, null);
        self.vkd.destroyDevice(self.dev, null);
        self.vki.destroySurfaceKHR(self.instance, self.surface, null);
        self.vki.destroyInstance(self.instance, null);
        self.shutdown_glfw();
    }

    /// ---------- renderObject functions

    // this one treats the renderer like any other subsystem

    fn initRenderObject(self: *@This(), params: CreateRenderObjectParams) !RenderObject {
        var renderObject = RenderObject.fromTransform(params.init_transform);

        var findMesh = self.meshes.getEntry(params.mesh_name.hash);
        var findMat = self.materials.getEntry(params.material_name.hash);

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
};

pub var gWindowName: []const u8 = "NeonWood Sample Application";

// must be called before graphics.start_module();
pub fn setWindowName(newWindowName: []const u8) void {
    gWindowName = newWindowName;
}

pub var gContext: *NeonVkContext = undefined;
