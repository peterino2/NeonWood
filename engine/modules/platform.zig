const std = @import("std");
const memory = @import("memory.zig");
const core = @import("core.zig");

// controls glfw and general windowing
// graphics depends on this one

pub usingnamespace @import("platform/windowing.zig");
pub const windowing = @import("platform/windowing.zig");
pub const glfw = @import("platform/glfw_defs.zig");

var gPlatformInstance: *windowing.PlatformInstance = undefined;

pub fn start_module(allocator: std.mem.Allocator, params: windowing.PlatformParams) !void {
    gPlatformInstance = try allocator.create(windowing.PlatformInstance);
    gPlatformInstance.* = try windowing.PlatformInstance.init(allocator, params);
    try gPlatformInstance.setup();
    core.engine_log("platform start_module @ 0x{x}", .{@intFromPtr(gPlatformInstance)});
    memory.MTPrintStatsDelta();
}

pub fn getInstance() *windowing.PlatformInstance {
    return gPlatformInstance;
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    _ = allocator;
    core.engine_logs("destroying platform");
    gPlatformInstance.deinit();
    //allocator.destroy(gPlatformInstance);
}

pub fn shutdown_module2(allocator: std.mem.Allocator) void {
    core.engine_logs("destroying platform");
    gPlatformInstance.deinit();
    allocator.destroy(gPlatformInstance);
}

pub const vkLoadFunc = windowing.c.glfwGetInstanceProcAddress;
