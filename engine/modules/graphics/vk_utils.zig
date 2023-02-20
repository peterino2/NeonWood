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

pub fn load_image_from_file(ctx: *NeonVkContext, filePath: []const u8) !NeonVkImage {
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

    // var h: c_int = -1;
    // var w: c_int = -1;
    // var comp: c_int = -1;
    // var pixels: ?*u8 = core.stbi_load(
    //     filePath.ptr,
    //     &w,
    //     &h,
    //     &comp,
    //     core.STBI_rgb_alpha,
    // );
    // if (pixels == null) {
    //     core.engine_log("Unable to load file from path {s}", .{filePath});
    //     return error.UnableToLoadFile;
    // }

    // ctx.stbiLoaderMutex.unlock();

    var pngFileContents = try core.loadFileAlloc(filePath, 8, ctx.allocator);
    var decoder = try spng.SpngContext.newDecoder();
    try decoder.setBuffer(pngFileContents);
    const header = try decoder.getHeader();

    var imageSize = @intCast(usize, header.width * header.height * 4);
    var pixels: []u8 = try ctx.allocator.alloc(u8, header.width * header.height * 4);
    var len = try decoder.decode(pixels, spng.SPNG_FMT_RGBA8, spng.SPNG_DECODE_TRNS);

    try core.assertf(len == pixels.len, "Expected length of pixels is not length of allocated buffer allocated = {d} decoded = {d}", .{ pixels.len, len });

    var stagingBuffer = try ctx.create_buffer(imageSize, .{ .transfer_src_bit = true }, .cpuOnly);

    const data = try ctx.vmaAllocator.mapMemory(stagingBuffer.allocation, u8);

    defer stagingBuffer.deinit(ctx.vmaAllocator);
    @memcpy(data, @ptrCast([*]const u8, pixels), imageSize);

    ctx.vmaAllocator.unmapMemory(stagingBuffer.allocation);

    decoder.deinit();
    ctx.allocator.free(pixels);

    ctx.allocator.free(pngFileContents);

    var imageExtent = vk.Extent3D{
        .width = @intCast(u32, header.width),
        .height = @intCast(u32, header.height),
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

    // try ctx.start_upload_context(&ctx.uploadContext);
    // var newImage = NeonVkImage{
    //     .image = result.image,
    //     .allocation = result.allocation,
    //     .pixelWidth = imageExtent.width,
    //     .pixelHeight = imageExtent.height,
    // };
    // {
    //     var cmd = ctx.uploadContext.commandBuffer;
    //     var range = vk.ImageSubresourceRange{
    //         .aspect_mask = .{ .color_bit = true },
    //         .base_mip_level = 0,
    //         .level_count = 1,
    //         .base_array_layer = 0,
    //         .layer_count = 1,
    //     };

    //     var imageBarrier_toTransfer = vk.ImageMemoryBarrier{
    //         .old_layout = .undefined,
    //         .new_layout = .transfer_dst_optimal,
    //         .image = newImage.image,
    //         .subresource_range = range,
    //         .src_access_mask = .{},
    //         .dst_access_mask = .{
    //             .transfer_write_bit = true,
    //         },
    //         .src_queue_family_index = 0,
    //         .dst_queue_family_index = 0,
    //     };
    //     ctx.vkd.cmdPipelineBarrier(
    //         cmd,
    //         .{ .top_of_pipe_bit = true },
    //         .{ .transfer_bit = true },
    //         .{},
    //         0,
    //         undefined,
    //         0,
    //         undefined,
    //         1,
    //         p2a(&imageBarrier_toTransfer),
    //     );

    //     var copyRegion = vk.BufferImageCopy{
    //         .buffer_offset = 0,
    //         .buffer_row_length = 0,
    //         .buffer_image_height = 0,
    //         .image_offset = std.mem.zeroes(vk.Offset3D),
    //         .image_subresource = .{
    //             .aspect_mask = .{ .color_bit = true },
    //             .mip_level = 0,
    //             .base_array_layer = 0,
    //             .layer_count = 1,
    //         },
    //         .image_extent = imageExtent,
    //     };

    //     ctx.vkd.cmdCopyBufferToImage(
    //         cmd,
    //         stagingBuffer.buffer,
    //         newImage.image,
    //         .transfer_dst_optimal,
    //         1,
    //         p2a(&copyRegion),
    //     );

    //     var imageBarrier_toReadable = vk.ImageMemoryBarrier{
    //         .old_layout = .transfer_dst_optimal,
    //         .new_layout = .shader_read_only_optimal,
    //         .image = newImage.image,
    //         .subresource_range = range,
    //         .src_access_mask = .{
    //             .transfer_write_bit = true,
    //         },
    //         .dst_access_mask = .{
    //             .shader_read_bit = false,
    //         },
    //         .src_queue_family_index = 0,
    //         .dst_queue_family_index = 0,
    //     };

    //     ctx.vkd.cmdPipelineBarrier(
    //         cmd,
    //         .{ .transfer_bit = true },
    //         .{ .fragment_shader_bit = true },
    //         .{},
    //         0,
    //         undefined,
    //         0,
    //         undefined,
    //         1,
    //         p2a(&imageBarrier_toReadable),
    //     );
    // }
    // try ctx.finish_upload_context(&ctx.uploadContext);

    return newImage;
}
