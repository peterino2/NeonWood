const std = @import("std");

// controls glfw and general windowing
// graphics depends on this one

pub usingnamespace @import("platform/windowing.zig");
pub const windowing = @import("platform/windowing.zig");

var gPlatformInstance: *windowing.PlatformInstance = undefined;

pub fn start_module(allocator: std.mem.Allocator, params: windowing.PlatformParams) !void {
    gPlatformInstance = try allocator.create(windowing.PlatformInstance);
    gPlatformInstance.* = try windowing.PlatformInstance.init(allocator, params);
    try gPlatformInstance.setup();
}

pub fn getInstance() *windowing.PlatformInstance {
    return gPlatformInstance;
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    gPlatformInstance.deinit();
    allocator.destroy(gPlatformInstance);
}

pub const vkLoadFunc = windowing.c.glfwGetInstanceProcAddress;
