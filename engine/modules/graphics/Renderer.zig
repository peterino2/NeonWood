const std = @import("std");
const vk = @import("vulkan");
const c = @import("c.zig");
const core = @import("../core/core.zig");

const vulkan_constants = @import("vulkan_constants.zig");
// Aliases

const DeviceDispatch = vulkan_constants.DeviceDispatch;
const BaseDispatch = vulkan_constants.BaseDispatch;
const InstanceDispatch = vulkan_constants.InstanceDispatch;

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const CStr = core.CStr;

const required_device_extensions = [_]CStr{
    vk.extension_info.khr_swapchain.name,
};

pub const NeonVkQueue = struct {
    handle: vk.Queue,
    family: u32,

    fn init(vkd: DeviceDispatch, dev: vk.Device, family: u32) @This() {
        return .{
            .handle = vkd.getDeviceQueue(dev, family, 0),
            .familly = family,
        };
    }
};

pub const NeonVkPhysicalDeviceInfo = struct {
    pdev: vk.PhysicalDevice,
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
            .pdev = pdevice,
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

pub const NeonVkRenderer = struct {
    const Self = @This();
    // Quirks of the way the zig wrapper loads the functions for vulkan
    vkb: vulkan_constants.BaseDispatch,
    vki: vulkan_constants.InstanceDispatch,
    vkd: vulkan_constants.DeviceDispatch,

    instance: vk.Instance,
    surface: vk.SurfaceKHR,
    physicalDevice: vk.PhysicalDevice,
    physicalDeviceProperties: vk.PhysicalDeviceProperties,
    physicalDeviceMemoryProperties: vk.PhysicalDeviceMemoryProperties,

    enumeratedPhysicalDevices: ArrayList(NeonVkPhysicalDeviceInfo),

    graphicsFamilyIndex: usize,
    presentFamilyIndex: usize,

    dev: vk.Device,
    graphicsQueue: NeonVkQueue,
    presentQueue: NeonVkQueue,

    gpa: std.heap.GeneralPurposeAllocator(.{}),
    allocator: std.mem.Allocator,

    window: ?*c.GLFWwindow,
    windowName: [*c]const u8,
    extent: vk.Extent2D,

    acquireSemaphores: ArrayList(vk.Semaphore),
    renderCompleteSemaphores: ArrayList(vk.Semaphore),

    commandPool: vk.CommandPool,
    commandBuffers: ArrayList(vk.CommandBuffer),
    commandBufferFences: ArrayList(vk.Fence),

    pub fn create_object() !Self {
        var self: Self = undefined;

        try self.init_zig_allocators();
        try self.init_glfw();
        try self.init_api();
        try self.init_device();
        try self.init_syncs();
        try self.init_command_pools();
        try self.init_command_buffers();

        return self;
    }

    pub fn init_syncs(self: *Self) !void {
        self.acquireSemaphores = try ArrayList(vk.Semaphore).initCapacity(self.allocator, 2);
        self.renderCompleteSemaphores = try ArrayList(vk.Semaphore).initCapacity(self.allocator, 2);

        try self.acquireSemaphores.resize(2);
        try self.renderCompleteSemaphores.resize(2);

        var sci = vk.SemaphoreCreateInfo{
            .flags = .{},
        };

        for (self.acquireSemaphores.items) |_, i| {
            self.acquireSemaphores.items[i] = try self.vkd.createSemaphore(self.dev, &sci, null);
            self.renderCompleteSemaphores.items[i] = try self.vkd.createSemaphore(self.dev, &sci, null);
        }
    }

    pub fn init_command_buffers(self: *Self) !void {
        self.commandBuffers = ArrayList(vk.CommandBuffer).init(self.allocator);
        self.commandBufferFences = ArrayList(vk.Fence).init(self.allocator);
        try self.commandBuffers.resize(2);
        try self.commandBufferFences.resize(2);

        var cbai = vk.CommandBufferAllocateInfo{
            .command_pool = self.commandPool,
            .level = vk.CommandBufferLevel.primary,
            .command_buffer_count = 2,
        };

        try self.vkd.allocateCommandBuffers(self.dev, &cbai, self.commandBuffers.items.ptr);

        // then create fences for the command buffers
        //
        var fci = vk.FenceCreateInfo{
            .flags = .{},
        };

        for (core.count(2)) |_, i| {
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

    pub fn init_zig_allocators(self: *Self) !void {
        self.gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self.allocator = self.gpa.allocator();
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
        const ExtraLayers = [1]CStr{vulkan_constants.VK_KHRONOS_VALIDATION_LAYER_STRING};
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
        errdefer self.vkd.destroyDevice(self.dev, null);

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

        var deviceFeatures = vk.PhysicalDeviceFeatures{};
        deviceFeatures.texture_compression_bc = vk.TRUE;
        deviceFeatures.image_cube_array = vk.TRUE;
        deviceFeatures.depth_clamp = vk.TRUE;
        deviceFeatures.depth_bias_clamp = vk.TRUE;
        deviceFeatures.depth_bounds = vk.TRUE;
        deviceFeatures.fill_mode_non_solid = vk.TRUE;

        var dci = vk.DeviceCreateInfo{
            .flags = .{},
            .queue_create_info_count = @intCast(u32, createQueueInfoList.items.len),
            .p_queue_create_infos = createQueueInfoList.items.ptr,
            .enabled_layer_count = 0,
            .pp_enabled_layer_names = undefined,
            .enabled_extension_count = @intCast(u32, required_device_extensions.len),
            .pp_enabled_extension_names = @ptrCast([*]const [*:0]const u8, &required_device_extensions),
            .p_enabled_features = &deviceFeatures,
        };

        dci.enabled_layer_count = vulkan_constants.required_device_layers.len;
        dci.pp_enabled_layer_names = @ptrCast([*]const [*:0]const u8, &vulkan_constants.required_device_layers);

        self.dev = try self.vki.createDevice(self.physicalDevice, &dci, null);

        self.vkd = try DeviceDispatch.load(self.dev, self.vki.dispatch.vkGetDeviceProcAddr);
        errdefer self.vkd.destroyDevice(self.dev, null);

        core.graphics_logs("Successfully created device");
    }

    fn create_command_pool(self: *Self) !void {
        _ = self;
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
                }
            }

            //  find the present queue family

            for (pDeviceInfo.queueFamilyProperties.items) |props, i| {
                if (props.queue_count == 0)
                    continue;

                var supportsPresent = try self.vki.getPhysicalDeviceSurfaceSupportKHR(pDeviceInfo.pdev, @intCast(u32, i), self.surface);
                if (supportsPresent > 0) {
                    presentID = @intCast(isize, i);
                    break;
                }
            }

            if (graphicsID != -1 and presentID != -1) {
                self.physicalDevice = pDeviceInfo.pdev;
                self.physicalDeviceProperties = pDeviceInfo.deviceProperties;
                self.physicalDeviceMemoryProperties = pDeviceInfo.memoryProperties;
                self.graphicsFamilyIndex = @intCast(usize, graphicsID);
                self.presentFamilyIndex = @intCast(usize, presentID);
                core.graphics_log("Found graphics queue family with id {d} [ {d} available ]", .{ graphicsID, pDeviceInfo.queueFamilyProperties.items.len });
                core.graphics_log("Found present queue family with id {d} [ {d} available ]", .{ presentID, pDeviceInfo.queueFamilyProperties.items.len });
                return;
            }
        }

        core.engine_errs("Unable to find a physical device which fits.");
        return error.NoValidDevice;
    }

    fn check_extension_support(self: *Self, deviceInfo: NeonVkPhysicalDeviceInfo) !bool {
        var count: u32 = undefined;
        _ = try self.vki.enumerateDeviceExtensionProperties(deviceInfo.pdev, null, &count, null);

        const extension_list = try self.allocator.alloc(vk.ExtensionProperties, count);
        defer self.allocator.free(extension_list);

        _ = try self.vki.enumerateDeviceExtensionProperties(deviceInfo.pdev, null, &count, extension_list.ptr);

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
                if (c.strcmp(layerName, core.buf_to_cstr(vulkan_constants.VK_KHRONOS_VALIDATION_LAYER_STRING)) == 0) {
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
        self.window = c.glfwCreateWindow(
            @intCast(c_int, self.extent.width),
            @intCast(c_int, self.extent.height),
            self.windowName,
            null,
            null,
        ) orelse return error.WindowInitFailed;
    }
};
