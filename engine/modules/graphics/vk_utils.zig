const std = @import("std");
const core = @import("../core.zig");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const obj_loader = @import("lib/objLoader/obj_loader.zig");
const vkinit = @import("vk_init.zig");

const p2a = core.p_to_a;
const ObjMesh = obj_loader.ObjMesh;
const ArrayList = std.ArrayList;
const Vectorf = core.Vectorf;
const NeonVkContext = vk_renderer.NeonVkContext;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;
const NeonVkImage = vk_renderer.NeonVkImage;

pub fn load_image_from_file(ctx: *NeonVkContext, filePath: []const u8) !NeonVkImage {
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

    var newImage = NeonVkImage{
        .image = result.image,
        .allocation = result.allocation,
        .pixelWidth = imageExtent.width,
        .pixelHeight = imageExtent.height,
    };

    try ctx.start_upload_context(&ctx.uploadContext);
    {
        var cmd = ctx.uploadContext.commandBuffer;
        var range = vk.ImageSubresourceRange{
            .aspect_mask = .{ .color_bit = true },
            .base_mip_level = 0,
            .level_count = 1,
            .base_array_layer = 0,
            .layer_count = 1,
        };

        var imageBarrier_toTransfer = vk.ImageMemoryBarrier{
            .old_layout = .@"undefined",
            .new_layout = .transfer_dst_optimal,
            .image = newImage.image,
            .subresource_range = range,
            .src_access_mask = .{},
            .dst_access_mask = .{
                .transfer_write_bit = true,
            },
            .src_queue_family_index = 0,
            .dst_queue_family_index = 0,
        };
        ctx.vkd.cmdPipelineBarrier(
            cmd,
            .{ .top_of_pipe_bit = true },
            .{ .transfer_bit = true },
            .{},
            0,
            undefined,
            0,
            undefined,
            1,
            p2a(&imageBarrier_toTransfer),
        );

        var copyRegion = vk.BufferImageCopy{
            .buffer_offset = 0,
            .buffer_row_length = 0,
            .buffer_image_height = 0,
            .image_offset = std.mem.zeroes(vk.Offset3D),
            .image_subresource = .{
                .aspect_mask = .{ .color_bit = true },
                .mip_level = 0,
                .base_array_layer = 0,
                .layer_count = 1,
            },
            .image_extent = imageExtent,
        };

        ctx.vkd.cmdCopyBufferToImage(
            cmd,
            stagingBuffer.buffer,
            newImage.image,
            .transfer_dst_optimal,
            1,
            p2a(&copyRegion),
        );

        var imageBarrier_toReadable = vk.ImageMemoryBarrier{
            .old_layout = .transfer_dst_optimal,
            .new_layout = .shader_read_only_optimal,
            .image = newImage.image,
            .subresource_range = range,
            .src_access_mask = .{
                .transfer_write_bit = true,
            },
            .dst_access_mask = .{
                .shader_read_bit = false,
            },
            .src_queue_family_index = 0,
            .dst_queue_family_index = 0,
        };

        ctx.vkd.cmdPipelineBarrier(
            cmd,
            .{ .transfer_bit = true },
            .{ .fragment_shader_bit = true },
            .{},
            0,
            undefined,
            0,
            undefined,
            1,
            p2a(&imageBarrier_toReadable),
        );
    }
    try ctx.finish_upload_context(&ctx.uploadContext);

    return newImage;
}
