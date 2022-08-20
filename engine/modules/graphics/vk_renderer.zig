const std = @import("std");
const vk = @import("vulkan");
const resources = @import("resources");
const c = @import("c.zig");
const vma = @import("vma");
const core = @import("../core/core.zig");
const vk_constants = @import("vk_constants.zig");
const vk_pipeline = @import("vk_pipeline.zig");
const NeonVkPipelineBuilder = vk_pipeline.NeonVkPipelineBuilder;
const mesh = @import("mesh.zig");
const render_objects = @import("render_object.zig");
const vkinit = @import("vk_init.zig");
const vk_utils = @import("vk_utils.zig");

const MAX_OBJECTS = 100000;

// Aliases
const p2a = core.p_to_a;
const p2av = core.p_to_av;
const Vector4f = core.Vector4f;
const Vectorf = core.Vectorf;
const Vector2 = core.Vector2;
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
const Material = render_objects.Material;
const Mesh = mesh.Mesh;

const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const CStr = core.CStr;

pub const NeonVkUploadContext = struct {
    uploadFence: vk.Fence,
    commandPool: vk.CommandPool,
    commandBuffer: vk.CommandBuffer,
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

    // buffers
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

    pub fn deinit(self: *NeonVkImage, allocator: vma.Allocator) void {
        allocator.destroyImage(self.image, self.allocation);
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

    pub const maxMode = 3;
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
    depthImage: NeonVkImage,
    depthImageView: vk.ImageView,

    static_triangle_pipeline: vk.Pipeline,
    static_colored_triangle_pipeline: vk.Pipeline,

    mesh_pipeline: vk.Pipeline,

    vmaFunctions: vma.VulkanFunctions,
    vmaAllocator: vma.Allocator,

    testMesh: mesh.Mesh,
    monkeyMesh: mesh.Mesh,

    exitSignal: bool,
    mesh_pipeline_layout: vk.PipelineLayout,
    firstFrame: bool,
    shouldResize: bool,

    cameraMovement: Vectorf,
    renderObjects: ArrayListUnmanaged(RenderObject), // all future arraylists should be unmanaged
    materials: std.AutoHashMapUnmanaged(u32, Material), // all future arraylists should be unmanaged
    meshes: std.AutoHashMapUnmanaged(u32, Mesh), // all future arraylists should be unmanaged
    camera: render_objects.Camera,

    descriptorPool: vk.DescriptorPool,
    globalDescriptorLayout: vk.DescriptorSetLayout,
    objectDescriptorLayout: vk.DescriptorSetLayout,

    // camera controls
    panCamera: bool,
    panCameraCache: bool,
    mousePosition: Vector2,
    mousePositionPanStart: Vector2,
    cameraRotationStart: core.Quat,
    cameraHorizontalRotation: core.Quat,
    cameraHorizontalRotationMat: core.Mat,
    cameraHorizontalRotationStart: core.Quat,

    sensitivity: f64,

    frameData: [NumFrames]NeonVkFrameData,
    lastMaterial: ?*Material,

    sceneDataGpu: NeonVkSceneDataGpu,
    sceneParameterBuffer: NeonVkBuffer,

    rotating: bool,

    uploadContext: NeonVkUploadContext,

    pub fn init_zig_data(self: *Self) !void {
        core.graphics_log("VkContextStaticSize = {d}", .{@sizeOf(Self)});
        self.gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self.allocator = std.heap.c_allocator;
        self.swapchain = .null_handle;
        self.nextFrameIndex = 0;
        self.rendererTime = 0;
        self.exitSignal = false;
        self.mode = 0;
        self.firstFrame = true;
        self.renderObjects = .{};
        self.meshes = .{};
        self.materials = .{};
        self.panCamera = false;
        self.panCameraCache = false;
        self.mousePosition = .{ .x = 0, .y = 0 };
        self.mousePositionPanStart = .{ .x = 0, .y = 0 };
        self.cameraRotationStart = core.zm.quatFromRollPitchYaw(0.0, 0.0, 0.0);
        self.cameraHorizontalRotation = self.cameraRotationStart;
        self.cameraHorizontalRotationStart = self.cameraRotationStart;
        self.cameraHorizontalRotationMat = core.zm.identity();
        self.sensitivity = 0.005;
        self.lastMaterial = null;
        self.rotating = true;
    }

    pub fn start_upload_context(self: *Self, context: *NeonVkUploadContext) !void {
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
        context.active = false;
    }

    pub fn pad_uniform_buffer_size(self: Self, originalSize: usize) !usize {
        var alignment = self.physicalDeviceProperties.limits.min_uniform_buffer_offset_alignment;

        var alignedSize: usize = originalSize;
        if (alignment > 0) {
            alignedSize = (alignedSize + alignment - 1) & ~(alignment - 1);
        }

        return alignedSize;
    }

    pub fn create_object() !Self {
        var self: Self = undefined;

        try self.init_zig_data();
        try self.init_glfw();
        try self.init_api();
        try self.init_device();
        try self.init_vma();
        try self.init_command_pools();
        try self.init_command_buffers();
        try self.init_syncs();
        try self.init_or_recycle_swapchain();
        try self.init_rendertarget();
        try self.init_renderpasses();
        try self.init_framebuffers();

        try self.init_descriptors();
        try self.init_pipelines();
        try self.init_meshes();
        try self.init_renderobjects();
        var image = try vk_utils.load_image_from_file(&self, "assets/icon.png");
        image.deinit(self.vmaAllocator);

        return self;
    }

    pub fn init_descriptors(self: *Self) !void {
        const sizes = [_]vk.DescriptorPoolSize{
            .{ .@"type" = .uniform_buffer, .descriptor_count = 10 },
            .{ .@"type" = .uniform_buffer_dynamic, .descriptor_count = 10 },
            .{ .@"type" = .storage_buffer, .descriptor_count = 10 },
        };

        var poolInfo = vk.DescriptorPoolCreateInfo{
            .flags = .{},
            .max_sets = 10,
            .pool_size_count = @intCast(u32, sizes.len),
            .p_pool_sizes = &sizes,
        };

        self.descriptorPool = try self.vkd.createDescriptorPool(self.dev, &poolInfo, null);

        _ = poolInfo;
        _ = sizes;

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

        const paddedSceneSize = try self.pad_uniform_buffer_size(@sizeOf(NeonVkSceneDataGpu));
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
    }

    pub fn init_renderobjects(self: *Self) !void {
        try self.add_renderobject(.{
            .mesh_name = core.MakeName("mesh_monkey"),
            .material_name = core.MakeName("mat_monkey"),
        });

        try self.add_renderobject(
            .{
                .mesh_name = core.MakeName("mesh_monkey"),
                .material_name = core.MakeName("mat_monkey"),
                .init_transform = mul(core.zm.scaling(0.5, 0.5, 0.5), core.zm.translation(-2.0, -2.0, -1.0)),
            },
        );

        var i: u32 = 0;
        while (i < 1000) : (i += 1) {
            try self.add_renderobject(.{
                .mesh_name = core.MakeName("mesh_monkey"),
                .material_name = core.MakeName("mat_monkey"),
                .init_transform = mul(core.zm.scaling(0.1, 0.1, 0.1), core.zm.translation(
                    @intToFloat(f32, i % 10) * -4.0 * (0.1) + 2.0,
                    @intToFloat(f32, i / 100) * 4.0 * (0.1) - 1.0,
                    @intToFloat(f32, ((i % 100) / 10)) * -4.0 * (0.1) + 2.0,
                )),
            });
        }

        self.camera = render_objects.Camera.init();
        self.camera.translate(.{ .x = 0.0, .y = 0.0, .z = -2.0 });
        self.camera.updateCamera();
    }

    pub fn add_renderobject(self: *Self, params: CreateRenderObjectParams) !void {
        var renderObject = RenderObject{
            .mesh = null,
            .material = null,
            .transform = params.init_transform,
        };

        var findMesh = self.meshes.getEntry(params.mesh_name.hash);
        var findMat = self.materials.getEntry(params.material_name.hash);

        if (findMesh == null)
            return error.NoMeshFound;

        if (findMat == null)
            return error.NoMaterialFound;

        renderObject.material = findMat.?.value_ptr;
        renderObject.mesh = findMesh.?.value_ptr;

        try self.renderObjects.append(self.allocator, renderObject);
    }

    pub fn init_meshes(self: *Self) !void {
        self.testMesh = mesh.Mesh.init(self, self.allocator);
        try self.testMesh.vertices.resize(3);
        self.testMesh.vertices.items[0].position = .{ .x = 1.0, .y = 1.0, .z = 0.0 };
        self.testMesh.vertices.items[1].position = .{ .x = -1.0, .y = 1.0, .z = 0.0 };
        self.testMesh.vertices.items[2].position = .{ .x = 0.0, .y = -1.0, .z = 0.0 };

        self.testMesh.vertices.items[0].color = .{ .r = 1.0, .g = 0.0, .b = 0.0, .a = 1.0 }; //pure green
        self.testMesh.vertices.items[1].color = .{ .r = 0.0, .g = 1.0, .b = 0.0, .a = 1.0 }; //pure green
        self.testMesh.vertices.items[2].color = .{ .r = 0.0, .g = 0.0, .b = 1.0, .a = 1.0 }; //pure green

        try self.testMesh.upload(self);

        self.monkeyMesh = mesh.Mesh.init(self, self.allocator);
        try self.monkeyMesh.load_from_obj_file("modules/graphics/lib/objLoader/test/monkey.obj");
        try self.monkeyMesh.upload(self);

        {
            _ = try self.new_mesh_from_obj(core.MakeName("mesh_monkey"), "modules/graphics/lib/objLoader/test/monkey.obj");
        }
    }

    // we need a content filing system
    pub fn new_mesh_from_obj(self: *Self, meshName: core.Name, filename: []const u8) !mesh.Mesh {
        var newMesh = mesh.Mesh.init(self, self.allocator);
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
            const data = try self.vmaAllocator.mapMemory(allocatedBuffer.allocation, u8);
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

        const data = try self.vmaAllocator.mapMemory(buffer.allocation, u8);
        defer self.vmaAllocator.unmapMemory(buffer.allocation);

        @memcpy(data, @ptrCast([*]const u8, uploadedMesh.vertices.items.ptr), size);

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
        try static_tri_builder.add_depth_stencil();
        self.static_triangle_pipeline = (try static_tri_builder.build(self.renderPass)).?;
        self.vkd.destroyPipelineLayout(self.dev, static_tri_builder.pipelineLayout, null);
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
        try colored_tri_b.add_depth_stencil();
        self.static_colored_triangle_pipeline = (try colored_tri_b.build(self.renderPass)).?;
        self.vkd.destroyPipelineLayout(self.dev, colored_tri_b.pipelineLayout, null);
        defer colored_tri_b.deinit();

        {
            core.graphics_logs("Creating mesh pipeline");
            var mesh_pipeline_b = try NeonVkPipelineBuilder.init(
                self.dev,
                self.vkd,
                self.allocator,
                resources.triangle_mesh_vert.len,
                @ptrCast([*]const u32, resources.triangle_mesh_vert),
                //resources.triangle_mesh_frag.len,
                //@ptrCast([*]const u32, resources.triangle_mesh_frag),
                resources.default_lit_frag.len,
                @ptrCast([*]const u32, resources.default_lit_frag),
            );
            try mesh_pipeline_b.add_mesh_description();
            try mesh_pipeline_b.add_push_constant();
            try mesh_pipeline_b.add_layout(self.globalDescriptorLayout);
            try mesh_pipeline_b.add_layout(self.objectDescriptorLayout);
            try mesh_pipeline_b.add_depth_stencil();
            try mesh_pipeline_b.init_triangle_pipeline(self.actual_extent);
            self.mesh_pipeline = (try mesh_pipeline_b.build(self.renderPass)).?;
            self.mesh_pipeline_layout = mesh_pipeline_b.pipelineLayout;
            var material = render_objects.Material{
                .pipeline = self.mesh_pipeline,
                .layout = self.mesh_pipeline_layout,
            };
            try self.materials.put(self.allocator, core.MakeName("mat_monkey").hash, material);
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

    // todo:: gameplay code
    pub fn pollInput(self: *Self) void {
        c.glfwGetCursorPos(self.window, &self.mousePosition.x, &self.mousePosition.y);

        if (self.camera.isDirty()) {
            self.camera.updateCamera();
        }

        const state = c.glfwGetMouseButton(self.window, c.GLFW_MOUSE_BUTTON_RIGHT);
        if (state == c.GLFW_PRESS) {
            self.panCamera = true;
        }
        if (state == c.GLFW_RELEASE) {
            self.panCamera = false;
        }
    }

    fn handleCameraPan(self: *Self, deltaTime: f64) void {
        _ = deltaTime;
        if (self.panCameraCache == false and self.panCamera) {
            self.mousePositionPanStart = self.mousePosition;
            self.cameraRotationStart = self.camera.rotation;
            self.cameraHorizontalRotationStart = self.cameraHorizontalRotation;
        }
        if (self.panCamera) {
            var diff = self.mousePosition.sub(self.mousePositionPanStart);

            var horizontalRotation = core.zm.matFromRollPitchYaw(0.0, @floatCast(f32, diff.x * self.sensitivity), 0.0);
            horizontalRotation = mul(
                core.zm.matFromQuat(self.cameraHorizontalRotationStart),
                horizontalRotation,
            );
            self.cameraHorizontalRotationMat = horizontalRotation;
            self.cameraHorizontalRotation = core.zm.quatFromMat(horizontalRotation);

            // calculate the new roatation for the camera
            var offset = core.zm.matFromRollPitchYaw(core.clamp(@floatCast(f32, diff.y * self.sensitivity), core.radians(-90.0), core.radians(90.0)), 0.0, 0.0);
            var final = mul(core.zm.matFromQuat(self.cameraRotationStart), offset);
            self.camera.rotation = core.zm.quatFromMat(final);
        }

        self.panCameraCache = self.panCamera;
    }

    fn updateTime(self: *Self, deltaTime: f64) void {
        self.rendererTime += deltaTime;
    }

    // this is game code.
    pub fn updateGame(self: *Self, deltaTime: f64) !void {
        var movement = self.cameraMovement.normalize().fmul(@floatCast(f32, deltaTime));
        var movement_v = mul(core.zm.matFromQuat(self.cameraHorizontalRotation), movement.toZm());
        self.camera.translate(.{ .x = movement_v[0], .y = movement_v[1], .z = movement_v[2] });
        self.handleCameraPan(deltaTime);
        self.sceneDataGpu.ambientColor = .{
            std.math.sin(core.radians(180.0 * @floatCast(f32, self.rendererTime))),
            0.0,
            std.math.cos(180.0 * core.radians(@floatCast(f32, self.rendererTime))),
            1.0,
        };
    }

    // convert game state into some intermediate graphics data.
    pub fn pre_frame_update(self: *Self) !void {
        // ---- bind global descriptors ----
        const data = try self.vmaAllocator.mapMemory(self.frameData[self.nextFrameIndex].cameraBuffer.allocation, u8);

        // resolve the current state of the camera
        self.camera.resolve(self.cameraHorizontalRotationMat);
        var projection_matrix: Mat = self.camera.final;
        _ = projection_matrix;

        var cameraData = NeonVkCameraDataGpu{
            .proj = core.zm.identity(),
            .view = core.zm.identity(),
            .viewproj = projection_matrix,
        };

        @memcpy(data, @ptrCast([*]const u8, &cameraData), @sizeOf(NeonVkCameraDataGpu));

        self.vmaAllocator.unmapMemory(self.frameData[self.nextFrameIndex].cameraBuffer.allocation);
    }

    pub fn acquire_next_frame(self: *Self) !void {
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
        var clearValues = [2]vk.ClearValue{
            .{
                .color = .{ .float_32 = [4]f32{ 0.015, 0.015, 0.015, 1.0 } },
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
    }

    pub fn finish_main_renderpass(self: *Self, cmd: vk.CommandBuffer) !void {
        self.vkd.cmdEndRenderPass(cmd);
    }

    pub fn draw(self: *Self, deltaTime: f64) !void {
        self.updateTime(deltaTime);
        try self.acquire_next_frame();
        try self.pre_frame_update();

        // start the party.
        const cmd = try self.start_frame_command_buffer();

        try self.begin_main_renderpass(cmd);

        if (self.mode == 0) {
            try self.render_meshes(deltaTime);
        } else if (self.mode == 1) {
            self.vkd.cmdBindPipeline(cmd, .graphics, self.static_triangle_pipeline);
            self.vkd.cmdDraw(cmd, 3, 1, 0, 0);
        } else if (self.mode == 2) {
            self.vkd.cmdBindPipeline(cmd, .graphics, self.static_colored_triangle_pipeline);
            self.vkd.cmdDraw(cmd, 3, 1, 0, 0);
        }

        try self.finish_main_renderpass(cmd);
        try self.vkd.endCommandBuffer(cmd);
        try self.finish_frame();
    }

    fn draw_render_object(self: *Self, render_object: RenderObject, cmd: vk.CommandBuffer, index: u32, deltaTime: f64) void {
        _ = deltaTime;

        if (render_object.mesh == null)
            return;

        if (render_object.material == null)
            return;

        const pipeline = render_object.material.?.pipeline;
        const layout = render_object.material.?.layout;
        const object_mesh = render_object.mesh.?.*;

        var offset: vk.DeviceSize = 0;

        const paddedSceneSize = @intCast(u32, try self.pad_uniform_buffer_size(@sizeOf(NeonVkSceneDataGpu)));
        var startOffset: u32 = paddedSceneSize * self.nextFrameIndex;

        if (self.lastMaterial != render_object.material) {
            self.vkd.cmdBindPipeline(cmd, .graphics, pipeline);
            self.lastMaterial = render_object.material;
            self.vkd.cmdBindVertexBuffers(cmd, 0, 1, p2a(&object_mesh.buffer.buffer), p2a(&offset));
            self.vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 0, 1, p2a(&self.frameData[self.nextFrameIndex].globalDescriptorSet), 1, p2a(&startOffset));
            self.vkd.cmdBindDescriptorSets(cmd, .graphics, layout, 1, 1, p2a(&self.frameData[self.nextFrameIndex].objectDescriptorSet), 0, undefined);
        }

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
        const data = try self.vmaAllocator.mapMemory(self.sceneParameterBuffer.allocation, u8);
        const paddedSceneSize = try self.pad_uniform_buffer_size(@sizeOf(NeonVkSceneDataGpu));
        const startOffset = paddedSceneSize * self.nextFrameIndex;

        @memcpy(data + startOffset, @ptrCast([*]const u8, &self.sceneDataGpu), @sizeOf(@TypeOf(self.sceneDataGpu)));

        self.vmaAllocator.unmapMemory(self.sceneParameterBuffer.allocation);
    }

    fn upload_object_data(self: *Self) !void {
        const allocation = self.frameData[self.nextFrameIndex].objectBuffer.allocation;
        const data = try self.vmaAllocator.mapMemory(allocation, NeonVkObjectDataGpu);
        var ssbo: []NeonVkObjectDataGpu = undefined;
        ssbo.ptr = @ptrCast([*]NeonVkObjectDataGpu, data);
        ssbo.len = MAX_OBJECTS;

        var i: usize = 0;
        while (i < MAX_OBJECTS and i < self.renderObjects.items.len) : (i += 1) {
            ssbo[i].modelMatrix = self.renderObjects.items[i].transform;
        }

        self.vmaAllocator.unmapMemory(allocation);
    }

    fn render_meshes(self: *Self, deltaTime: f64) !void {
        _ = deltaTime;
        try self.upload_scene_global_data(deltaTime);
        try self.upload_object_data();

        var cmd = self.commandBuffers.items[self.nextFrameIndex];

        self.lastMaterial = null;

        // todo this is game code;
        for (self.renderObjects.items) |_, i| {
            var rate: f32 = if (i % 2 == 0) 180.0 else -180.0;
            _ = rate;
            if (self.rotating)
                self.renderObjects.items[i].applyRelativeRotationY(
                    core.radians(rate) * @floatCast(f32, deltaTime),
                );
        }

        for (self.renderObjects.items) |object, i| {
            self.draw_render_object(object, cmd, @intCast(u32, i), deltaTime);
        }
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
            self.shouldResize = false;

            try self.init_or_recycle_swapchain();
            try self.init_framebuffers();
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
            .load_op = .clear,
            .store_op = .store,
            .stencil_load_op = .clear, // equals to zero
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
            .initial_layout = .@"undefined",
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
        _ = dimg_create;

        var dimg_vma_alloc_info = vma.AllocationCreateInfo{
            .requiredFlags = .{
                .device_local_bit = true,
            },
            .usage = .gpuOnly,
        };

        _ = dimg_vma_alloc_info;
        var result = try self.vmaAllocator.createImage(dimg_create, dimg_vma_alloc_info);

        self.depthImage = .{
            .image = result.image,
            .allocation = result.allocation,
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

        var shaderDrawFeatures = vk.PhysicalDeviceShaderDrawParametersFeatures{
            .shader_draw_parameters = vk.TRUE,
        };

        var dci = vk.DeviceCreateInfo{
            .flags = .{},
            .p_next = &shaderDrawFeatures,
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

        self.extent = .{ .width = 1600, .height = 900 };
        self.windowName = "NeonWood Sample Application";

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
        self.vkd.destroyPipeline(self.dev, self.mesh_pipeline, null);
        self.vkd.destroyPipelineLayout(self.dev, self.mesh_pipeline_layout, null);
    }

    pub fn destroy_renderpass(self: *Self) !void {
        self.vkd.destroyRenderPass(self.dev, self.renderPass, null);
    }

    pub fn destroy_meshes(self: *Self) !void {
        self.testMesh.deinit(self);
        self.monkeyMesh.deinit(self);

        var iter = self.meshes.iterator();
        while (iter.next()) |i| {
            i.value_ptr.deinit(self);
        }
        self.meshes.deinit(self.allocator);
    }

    pub fn destroy_renderobjects(self: *Self) !void {
        self.renderObjects.deinit(self.allocator);
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

    pub fn destroy_descriptors(self: *Self) void {
        for (self.frameData) |_, i| {
            self.frameData[i].cameraBuffer.deinit(self.vmaAllocator);
            self.frameData[i].objectBuffer.deinit(self.vmaAllocator);
        }
        self.sceneParameterBuffer.deinit(self.vmaAllocator);

        self.vkd.destroyDescriptorSetLayout(self.dev, self.objectDescriptorLayout, null);
        self.vkd.destroyDescriptorSetLayout(self.dev, self.globalDescriptorLayout, null);
        self.vkd.destroyDescriptorPool(self.dev, self.descriptorPool, null);
    }

    pub fn deinit(self: *Self) void {
        self.vkd.deviceWaitIdle(self.dev) catch unreachable;

        self.destroy_pipelines() catch unreachable;
        self.destroy_renderpass() catch unreachable;
        self.destroy_syncs() catch unreachable;
        self.destroy_renderobjects() catch unreachable;
        self.destroy_meshes() catch unreachable;
        self.destroy_framebuffers() catch unreachable;
        self.destroy_upload_context(&self.uploadContext) catch unreachable;

        self.destroy_descriptors();

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

    if (action == c.GLFW_PRESS) {
        if (key == c.GLFW_KEY_SPACE) {
            gContext.mode = (gContext.mode + 1) % NeonVkContext.maxMode;
        }
        if (key == c.GLFW_KEY_R) {
            gContext.rotating = !gContext.rotating;
        }
        if (key == c.GLFW_KEY_W) {
            gContext.cameraMovement.z += 1.0;
        }
        if (key == c.GLFW_KEY_S) {
            gContext.cameraMovement.z += -1.0;
        }
        if (key == c.GLFW_KEY_D) {
            gContext.cameraMovement.x += -1.0;
        }
        if (key == c.GLFW_KEY_A) {
            gContext.cameraMovement.x += 1.0;
        }
        if (key == c.GLFW_KEY_Q) {
            gContext.cameraMovement.y += 1.0;
        }
        if (key == c.GLFW_KEY_E) {
            gContext.cameraMovement.y += -1.0;
        }
    }
    if (action == c.GLFW_RELEASE) {
        if (key == c.GLFW_KEY_W) {
            gContext.cameraMovement.z -= 1.0;
        }
        if (key == c.GLFW_KEY_S) {
            gContext.cameraMovement.z -= -1.0;
        }
        if (key == c.GLFW_KEY_D) {
            gContext.cameraMovement.x -= -1.0;
        }
        if (key == c.GLFW_KEY_A) {
            gContext.cameraMovement.x -= 1.0;
        }
        if (key == c.GLFW_KEY_Q) {
            gContext.cameraMovement.y -= 1.0;
        }
        if (key == c.GLFW_KEY_E) {
            gContext.cameraMovement.y -= -1.0;
        }
    }
}
