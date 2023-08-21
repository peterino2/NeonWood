const std = @import("std");

// controls glfw and general windowing
// graphics depends on this one

pub usingnamespace @import("platform/windowing.zig");
const windowing = @import("platform/windowing.zig");

var gPlatformInstance: *windowing.PlatformInstance = undefined;

pub fn start_module(allocator: std.mem.Allocator, windowName: []const u8, iconPath: ?[]const u8) !void {
    var params: windowing.PlatformParams = .{};
    params.windowName = windowName;
    if (iconPath) |path| {
        params.icon = path;
    }

    gPlatformInstance = try allocator.create(windowing.PlatformInstance);
    gPlatformInstance.* = try windowing.PlatformInstance.init(allocator, params);
    try gPlatformInstance.setup();
}

pub fn getInstance() *windowing.PlatformInstance {
    return gPlatformInstance;
}
