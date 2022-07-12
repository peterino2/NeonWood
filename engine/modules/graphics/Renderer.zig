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

const required_device_extensions = [_]core.CString{
    vk.extension_info.khr_swapchain.name,
};

pub const VkQueue = struct {
    handle: vk.Queue,
    family: u32,

    fn init(vkd: DeviceDispatch, dev: vk.Device, family: u32) @This() {
        return .{
            .handle = vkd.getDeviceQueue(dev, family, 0),
            .familly = family,
        };
    }
};

pub const Renderer = struct {
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

    dev: vk.Device,
    graphicsQueue: VkQueue,
    presentQueue: VkQueue,

    gpa: std.heap.GeneralPurposeAllocator(.{}),
    allocator: std.mem.Allocator,

    window: ?*c.GLFWwindow,
    windowName: [*c]const u8,
    extent: vk.Extent2D,

    pub fn create_object() !Self {
        var self: Self = undefined;

        try self.init_allocators();
        try self.init_glfw();
        try self.init_api();

        return self;
    }

    pub fn init_allocators(self: *Self) !void {
        self.gpa = std.heap.GeneralPurposeAllocator(.{}){};
        self.allocator = self.gpa.allocator();
    }

    pub fn init_api(self: *Self) !void {
        self.vkb = try BaseDispatch.load(c.glfwGetInstanceProcAddress);

        try self.createVulkanInstance();
        errdefer self.vki.destroyInstance(self.instance, null);

        // create KHR surface structure
        try self.createSurface();
        errdefer self.vki.destroySurfaceKHR(self.instance, self.surface, null);

        try self.pickPhysicalDevices();
        errdefer self.vkd.destroyDevice(self.dev, null);
    }

    fn createVulkanInstance(self: *Self) !void {
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
        try self.checkRequiredVulkanLayers(ExtraLayers[0..]);

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

    fn pickPhysicalDevices(self: *Self) !void {
        _ = self;
    }

    fn createSurface(self: *Self) !void {
        if (self.window == null)
            return error.WindowIsNullCantMakeSurface;

        var surface: vk.SurfaceKHR = undefined;

        if (c.glfwCreateWindowSurface(self.instance, self.window.?, null, &surface) != .success) {
            core.engine_errs("Unable to create glfw surface");
            return error.SurfaceInitFailed;
        }
    }

    fn checkRequiredVulkanLayers(self: *Self, requiredNames: []const CStr) !void {
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
