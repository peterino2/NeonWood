const std = @import("std");
const core = @import("core");

// controls glfw and general windowing
// graphics depends on this one

pub usingnamespace @import("windowing.zig");
pub const windowing = @import("windowing.zig");
pub const glfw_defs = @import("glfw_defs.zig");

pub const Module: core.ModuleDescription = .{
    .name = "platform",
    .enabledByDefault = true,
};

var gPlatformInstance: *windowing.PlatformInstance = undefined;

var gStartupParams: windowing.PlatformParams = .{};

pub fn setWindowSettings(params: windowing.PlatformParams) void {
    gStartupParams = params;
}

pub fn start_module(comptime programSpec: anytype, args: anytype, allocator: std.mem.Allocator) !void {
    _ = args;
    _ = programSpec;
    gPlatformInstance = try allocator.create(windowing.PlatformInstance);
    gPlatformInstance.* = try windowing.PlatformInstance.init(allocator, gStartupParams);
    try gPlatformInstance.setup();
}

pub fn getInstance() *windowing.PlatformInstance {
    return gPlatformInstance;
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    core.engine_logs("Shutting down platform");
    gPlatformInstance.deinit();

    // I have a bug somewhere. need to find out where it is
    allocator.destroy(gPlatformInstance);
}

pub const vkLoadFunc = windowing.c.glfwGetInstanceProcAddress;
