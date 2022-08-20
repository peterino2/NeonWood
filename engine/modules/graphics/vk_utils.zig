const std = @import("std");
const core = @import("../core/core.zig");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const obj_loader = @import("lib/objLoader/obj_loader.zig");
const vkinit = @import("vk_init.zig");

const ObjMesh = obj_loader.ObjMesh;
const ArrayList = std.ArrayList;
const Vectorf = core.Vectorf;
const NeonVkContext = vk_renderer.NeonVkContext;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;
const NeonVkImage = vk_renderer.NeonVkImage;

pub fn load_image_from_file(ctx: NeonVkContext, filePath: []const u8) !NeonVkImage {
    var h: c_int = -1;
    var w: c_int = -1;
    var comp: c_int = -1;
    var pixels: ?*u8 = core.stbi_load(
        filePath.ptr,
        &w,
        &h,
        &comp,
        core.STBI_rgb_alpha,
    );

    if (pixels == null) {
        core.engine_log("Unable to load file from path {s}", .{filePath});
        return error.UnableToLoadFile;
    }

    var imageSize = @intCast(usize, h * w * 4);

    var stagingBuffer = try ctx.create_buffer(imageSize, .{ .transfer_src_bit = true }, .cpuOnly);

    const data = try ctx.vmaAllocator.mapMemory(stagingBuffer.allocation, u8);
    defer stagingBuffer.deinit(ctx.vmaAllocator);
    @memcpy(data, @ptrCast([*]const u8, pixels), imageSize);
    ctx.vmaAllocator.unmapMemory(stagingBuffer.allocation);

    core.stbi_image_free(pixels);

    var imageExtent = vk.Extent3D{
        .width = @intCast(u32, w),
        .height = @intCast(u32, h),
        .depth = 1,
    };

    var imgCreateInfo = vkinit.imageCreateInfo(.r8g8b8a8_srgb, .{
        .sampled_bit = true,
        .transfer_dst_bit = true,
    }, imageExtent);

    var imgAllocInfo = vma.AllocationCreateInfo{
        .requiredFlags = .{},
        .usage = .gpuOnly,
    };
    var result = try ctx.vmaAllocator.createImage(imgCreateInfo, imgAllocInfo);

    var rv = NeonVkImage{
        .image = result.image,
        .allocation = result.allocation,
    };

    return rv;
}
