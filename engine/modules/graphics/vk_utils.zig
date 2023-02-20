const std = @import("std");
const core = @import("../core.zig");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const obj_loader = @import("lib/objLoader/obj_loader.zig");
const vkinit = @import("vk_init.zig");

const spng = core.spng;

const p2a = core.p_to_a;
const ObjMesh = obj_loader.ObjMesh;
const ArrayList = std.ArrayList;
const Vectorf = core.Vectorf;
const NeonVkContext = vk_renderer.NeonVkContext;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;
const NeonVkImage = vk_renderer.NeonVkImage;

pub const PngContents = struct {
    path: []const u8,
    pixels: []u8,
    size: core.Vector2u,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, filePath: []const u8) !@This() {
        var pngFileContents = try core.loadFileAlloc(filePath, 8, allocator);
        var decoder = try spng.SpngContext.newDecoder();
        defer decoder.deinit();

        try decoder.setBuffer(pngFileContents);
        const header = try decoder.getHeader();

        var imageSize = @intCast(usize, header.width * header.height * 4);
        var pixels: []u8 = try allocator.alloc(u8, imageSize);
        var len = try decoder.decode(pixels, spng.SPNG_FMT_RGBA8, spng.SPNG_DECODE_TRNS);
        try core.assertf(len == pixels.len, "decoded pixel size not buffer size {d} != {d}", .{ len, pixels.len });

        return PngContents{
            .path = try core.dupe(u8, allocator, filePath),
            .pixels = pixels,
            .size = .{ .x = header.width, .y = header.height },
            .allocator = allocator,
        };
    }

    pub fn stagePixels(self: @This(), ctx: *NeonVkContext) !NeonVkBuffer {
        var stagingBuffer = try ctx.create_buffer(self.pixels.len, .{ .transfer_src_bit = true }, .cpuOnly);
        const data = try ctx.vmaAllocator.mapMemory(stagingBuffer.allocation, u8);
        @memcpy(data, @ptrCast([*]const u8, self.pixels), self.pixels.len);
        ctx.vmaAllocator.unmapMemory(stagingBuffer.allocation);
        return stagingBuffer;
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.path);
        self.allocator.free(self.pixels);
    }
};

pub const LoadAndStageImage = struct {
    stagingBuffer: NeonVkBuffer,
    image: NeonVkImage,
};

pub fn load_and_stage_image_from_file(ctx: *NeonVkContext, filePath: []const u8) !LoadAndStageImage {
    // When you record command buffers, their command pools can only be used from
    // one thread at a time. While you can create multiple command buffers from a
    // command pool, you cant fill those commands from multiple threads. If you
    // want to record command buffers from multiple threads, then you will need
    // more command pools, one per thread.
    //
    // in other words... this will multithread our png loading... yes.
    //
    // and we can multithread constructing our command structures
    // but calling VkQueueSubmit is not going to be threadsafe unless we create a
    // seperate command pool for each thread.

    var pngContents = try PngContents.init(ctx.allocator, filePath);

    var stagingBuffer = try pngContents.stagePixels(ctx);

    var imageExtent = vk.Extent3D{
        .width = @intCast(u32, pngContents.size.x),
        .height = @intCast(u32, pngContents.size.y),
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

    pngContents.deinit();

    return .{
        .stagingBuffer = stagingBuffer,
        .image = newImage,
    };
}

pub fn submit_copy_from_staging(ctx: *NeonVkContext, stagingBuffer: NeonVkBuffer, newImage: NeonVkImage) !void {
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
            .old_layout = .undefined,
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
            .image_extent = .{ .width = newImage.pixelWidth, .height = newImage.pixelHeight, .depth = 1 },
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
}
