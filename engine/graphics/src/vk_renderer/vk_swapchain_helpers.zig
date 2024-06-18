const std = @import("std");
const vk = @import("vulkan");
const core = @import("core");
const vk_constants = @import("../vk_constants.zig");
const vk_renderer_types = @import("vk_renderer_types.zig");

const vk_api = @import("../vk_api.zig");
const vkd = vk_api.vkd;
const vki = vk_api.vki;
const vkb = vk_api.vkb;

const force_mailbox = core.BuildOption("force_mailbox");

pub fn findSurfaceFormat(
    allocator: std.mem.Allocator,
    pdev: vk.PhysicalDevice,
    surface: vk.SurfaceKHR,
) !vk.SurfaceFormatKHR {
    const preferred = vk.SurfaceFormatKHR{
        .format = .b8g8r8a8_srgb,
        .color_space = .srgb_nonlinear_khr,
    };

    var count: u32 = 0;

    _ = try vki.getPhysicalDeviceSurfaceFormatsKHR(pdev, surface, &count, null);

    const surface_formats = try allocator.alloc(vk.SurfaceFormatKHR, count);
    defer allocator.free(surface_formats);

    _ = try vki.getPhysicalDeviceSurfaceFormatsKHR(pdev, surface, &count, surface_formats.ptr);

    for (surface_formats) |sfmt| {
        if (std.meta.eql(sfmt, preferred)) {
            return preferred;
        }
    }

    const rv = surface_formats[0];

    core.graphics_log("Selected surface format\n   {any}", .{rv});
    return rv;
}

pub fn findPresentMode(
    allocator: std.mem.Allocator,
    pdev: vk.PhysicalDevice,
    surface: vk.SurfaceKHR,
) !vk.PresentModeKHR {
    var count: u32 = undefined;
    _ = try vki.getPhysicalDeviceSurfacePresentModesKHR(pdev, surface, &count, null);
    const present_modes = try allocator.alloc(vk.PresentModeKHR, count);
    defer allocator.free(present_modes);
    _ = try vki.getPhysicalDeviceSurfacePresentModesKHR(pdev, surface, &count, present_modes.ptr);

    const preferred = [_]vk.PresentModeKHR{
        .fifo_khr,
        .mailbox_khr,
        .immediate_khr,
    };

    if (force_mailbox) {
        return .mailbox_khr;
    }

    for (preferred) |mode| {
        if (std.mem.indexOfScalar(vk.PresentModeKHR, present_modes, mode) != null) {
            return mode;
        }
    }

    return error.UnableToFindPresentMode;
}

pub fn findActualExtent(
    extent: vk.Extent2D,
    caps: vk.SurfaceCapabilitiesKHR,
) !vk.Extent2D {
    if (caps.current_extent.width != 0xFFFF_FFFF) {
        return caps.current_extent;
    } else {
        return .{
            .width = std.math.clamp(extent.width, caps.min_image_extent.width, caps.max_image_extent.width),
            .height = std.math.clamp(extent.height, caps.min_image_extent.height, caps.max_image_extent.height),
        };
    }
}
