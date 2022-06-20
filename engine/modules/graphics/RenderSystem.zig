const std = @import("std");
const core = @import("../core/core.zig");
const ArrayList = std.ArrayList;

const vk = @import("vulkan");
const c = @import("c.zig");

const Self = @This();

bIsInitialized: bool = false,
gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined,

// names prefixed with underbars, are external API names.
_extent: vk.Extent2D = undefined,
_window: ?*c.GLFWwindow = null,
_windowName: [*c]const u8,

pub fn init(self: *Self) !void {
    _ = self;

    try self.init_window();
    try self.init_api();
    try self.init_device();
    try self.init_swapchain();
    try self.init_syncs();
    try self.init_renderpass();
    try self.init_pipelines();
    try self.init_load_engine_assets();

    self.bIsInitialized = true;
}

fn init_window(self: *Self) !void {
    _ = self;
    if (c.glfwInit() != c.GLFW_TRUE)
        return error.GlfwInitFailed;

    self._extent = vk.Extent2D{ .width = 800, .height = 600 };
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

fn init_api(self: *Self) !void {
    _ = self;
}

fn init_device(self: *Self) !void {
    _ = self;
}

fn init_swapchain(self: *Self) !void {
    _ = self;
}

fn init_syncs(self: *Self) !void {
    _ = self;
}

fn init_renderpass(self: *Self) !void {
    _ = self;
}

fn init_pipelines(self: *Self) !void {
    _ = self;
}

fn init_load_engine_assets(self: *Self) !void {
    _ = self;
}

pub fn create_object() @This() {
    return .{ ._windowName = "Hello NeonWood!" };
}

pub fn run(self: *Self) !void {
    _ = self;

    while (c.glfwWindowShouldClose(self._window) == c.GLFW_FALSE) {
        var w: c_int = undefined;
        var h: c_int = undefined;

        _ = w;
        _ = h;

        c.glfwGetWindowSize(self._window, &w, &h);
        c.glfwPollEvents();
    }
}

pub fn cleanup(self: *Self) !void {
    _ = self;
    if (!self.bIsInitialized)
        return error.RenderSystemNotInitialized;

    c.glfwTerminate();

    _ = self.gpa.deinit();
}
