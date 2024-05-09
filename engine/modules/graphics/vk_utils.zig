const std = @import("std");
const core = @import("../core.zig");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const obj_loader = @import("lib/objLoader/obj_loader.zig");
const vkinit = @import("vk_init.zig");
const vk_constants = @import("vk_constants.zig");
const tracy = core.tracy;
const Texture = @import("texture.zig").Texture;
const memory = @import("../memory.zig");
const vk_allocator = @import("vk_allocator.zig");

const NeonVkAllocator = vk_allocator.NeonVkAllocator;

const image = @import("../image.zig");
const PngContents = image.PngContents;

const ObjMesh = obj_loader.ObjMesh;
const ArrayList = std.ArrayList;
const Vectorf = core.Vectorf;
const NeonVkContext = vk_renderer.NeonVkContext;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;
const NeonVkImage = vk_renderer.NeonVkImage;
const NumFrames = vk_constants.NUM_FRAMES;

const NeonVkObjectDataGpu = vk_renderer.NeonVkObjectDataGpu;

const transitions = @import("vk_transitions.zig");

const NeonVkSpriteDataGpu = struct {
    // tl, tr, br, bl running clockwise
    position: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    size: core.Vector2f = .{ .x = 1.0, .y = 1.0 },
};

// Takes the contents of a png file and transfers the pixel contents to a staged buffer
pub fn stagePixels(self: PngContents, ctx: *NeonVkContext) !NeonVkBuffer {
    const stagingBuffer = try ctx.create_buffer(self.pixels.len, .{ .transfer_src_bit = true }, .cpuOnly, "Stage pixels staging buffer");
    const data = try ctx.vkAllocator.vmaAllocator.mapMemory(stagingBuffer.allocation, u8);
    var dataSlice: []u8 = undefined;
    dataSlice.ptr = data;
    dataSlice.len = self.pixels.len;
    @memcpy(dataSlice, self.pixels);
    ctx.vkAllocator.vmaAllocator.unmapMemory(stagingBuffer.allocation);
    return stagingBuffer;
}

pub const LoadAndStageImage = struct {
    stagingBuffer: NeonVkBuffer,
    image: NeonVkImage,
    mipLevel: u32 = 0,

    pub fn deinit(self: *@This(), vkAllocator: *NeonVkAllocator) void {
        vkAllocator.destroyBuffer(&self.stagingBuffer);
        vkAllocator.destroyImage(&self.image);
    }
};

pub fn stagePixelsRaw(pixels: []const u8, ctx: *NeonVkContext) !NeonVkBuffer {
    const stagingBuffer = try ctx.create_buffer(pixels.len, .{ .transfer_src_bit = true }, .cpuOnly, "Stage pixels staging buffer");
    const data = try ctx.vkAllocator.vmaAllocator.mapMemory(stagingBuffer.allocation, u8);
    var dataSlice: []u8 = undefined;
    dataSlice.ptr = data;
    dataSlice.len = pixels.len;
    @memcpy(dataSlice, pixels);
    ctx.vkAllocator.vmaAllocator.unmapMemory(stagingBuffer.allocation);
    return stagingBuffer;
}

pub fn newVkImage(size: core.Vector2i, ctx: *NeonVkContext, mipLevel: u32) !NeonVkImage {
    const imageExtent = vk.Extent3D{
        .width = @as(u32, @intCast(size.x)),
        .height = @as(u32, @intCast(size.y)),
        .depth = 1,
    };

    var imgCreateInfo = vkinit.imageCreateInfo(.r8g8b8a8_srgb, .{
        .sampled_bit = true,
        .transfer_dst_bit = true,
    }, imageExtent, mipLevel);

    if (mipLevel > 1) {
        core.graphics_log("creating image with mip level: {d} {d}x{d}", .{ mipLevel, size.x, size.y });
        imgCreateInfo.usage = .{
            .transfer_dst_bit = true,
            .transfer_src_bit = true,
            .sampled_bit = true,
        };
    }

    const imgAllocInfo = vma.AllocationCreateInfo{
        .requiredFlags = .{},
        .usage = .gpuOnly,
    };

    return try ctx.vkAllocator.createImage(imgCreateInfo, imgAllocInfo, @src().fn_name);
}

inline fn isPowerOfTwo(n: anytype) bool {
    return n != 0 and (n & (n - 1)) == 0;
}

pub fn getMiplevelFromSize(size: core.Vector2i) u32 {
    if (size.x != size.y)
        return 1;
    if (!isPowerOfTwo(size.x))
        return 1;
    return std.math.log2(@as(u32, @intCast(@max(size.x, size.y)))) + 1;
}

pub fn createTextureFromPixels(
    pixels: []const u8,
    size: core.Vector2i,
    ctx: *NeonVkContext,
    useBlocky: bool,
) !CreateTextureResults {
    // copy pixels into staging buffer
    const miplevel = getMiplevelFromSize(size);
    var stagingBuffer = try stagePixelsRaw(pixels, ctx);
    // create image memory resources
    const createdImage = try newVkImage(size, ctx, miplevel);

    // upload staging buffer
    try submit_copy_from_staging(ctx, stagingBuffer, createdImage, miplevel);

    stagingBuffer.deinit(ctx.vkAllocator);

    var imageViewCreate = vkinit.imageViewCreateInfo(
        .r8g8b8a8_srgb,
        createdImage.image,
        .{ .color_bit = true },
        miplevel,
    );

    const imageView = try ctx.vkd.createImageView(ctx.dev, &imageViewCreate, null);

    const newTexture = try ctx.allocator.create(Texture);

    newTexture.* = Texture{
        .image = createdImage,
        .imageView = imageView,
    };

    // create descriptors for
    const textureSet = ctx.create_mesh_image_for_texture(newTexture, .{
        .useBlocky = useBlocky,
    }) catch unreachable;

    return .{ .texture = newTexture, .descriptor = textureSet };
}

const CreateTextureResults = struct { texture: *Texture, descriptor: vk.DescriptorSet };

pub fn createAndInstallTextureFromPixels(
    textureName: core.Name,
    pixels: []const u8,
    size: core.Vector2i,
    ctx: *NeonVkContext,
    useBlocky: bool,
) !CreateTextureResults {
    const res = try createTextureFromPixels(pixels, size, ctx, useBlocky);

    ctx.install_texture_into_registry(textureName, res.texture, res.descriptor) catch return error.UnknownStatePanic;

    return res;
}

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

    const imageExtent = vk.Extent3D{
        .width = @as(u32, @intCast(pngContents.size.x)),
        .height = @as(u32, @intCast(pngContents.size.y)),
        .depth = 1,
    };
    const mipLevel = std.math.log2(@max(imageExtent.width, imageExtent.height)) + 1;

    var imgCreateInfo = vkinit.imageCreateInfo(.r8g8b8a8_srgb, .{
        .sampled_bit = true,
        .transfer_dst_bit = true,
    }, imageExtent, mipLevel);

    if (mipLevel > 1) {
        imgCreateInfo.usage.transfer_src_bit = true;
    }

    const imgAllocInfo = vma.AllocationCreateInfo{
        .requiredFlags = .{},
        .usage = .gpuOnly,
    };

    const newImage = try ctx.vkAllocator.createImage(imgCreateInfo, imgAllocInfo, @src().fn_name);
    const stagingBuffer = try stagePixels(pngContents, ctx);

    pngContents.deinit();

    return .{
        .stagingBuffer = stagingBuffer,
        .image = newImage,
        .mipLevel = mipLevel,
    };
}

pub fn submit_copy_from_staging(ctx: *NeonVkContext, stagingBuffer: NeonVkBuffer, newImage: NeonVkImage, mipLevel: u32) !void {
    var z1 = tracy.ZoneN(@src(), "submitting copy from staging buffer");
    defer z1.End();
    //try ctx.start_upload_context(&ctx.uploadContext);
    try ctx.uploader.startUploadContext();
    {
        var z2 = tracy.ZoneN(@src(), "recording command buffer");
        const cmd = ctx.uploader.commandBuffer;

        transitions.into_transferDst(ctx.vkd, cmd, newImage.image, mipLevel);

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
            .image_extent = .{
                .width = newImage.pixelWidth,
                .height = newImage.pixelHeight,
                .depth = 1,
            },
        };

        ctx.vkd.cmdCopyBufferToImage(
            cmd,
            stagingBuffer.buffer,
            newImage.image,
            .transfer_dst_optimal,
            1,
            @ptrCast(&copyRegion),
        );

        core.graphics_log("miplevel count: {d}", .{mipLevel});
        try generateMipMaps(ctx, newImage, mipLevel);

        transitions.transferDst_into_shaderReadOnly(ctx.vkd, cmd, newImage.image, mipLevel);
        z2.End();
    }
    try ctx.uploader.finishUploadContext();
    //try ctx.finish_upload_context(&ctx.uploadContext);
}

fn generateMipMaps(ctx: *NeonVkContext, vkImage: NeonVkImage, mipLevels: u32) !void {
    core.assert(mipLevels > 0);
    const cmd = ctx.uploader.commandBuffer;
    const img = vkImage.image;

    const range: vk.ImageSubresourceRange = .{
        .aspect_mask = .{ .color_bit = true },
        .base_mip_level = 0,
        .level_count = 1,
        .base_array_layer = 0,
        .layer_count = 1,
    };

    var imb: vk.ImageMemoryBarrier = .{
        .old_layout = .undefined,
        .new_layout = .transfer_dst_optimal,
        .image = img,
        .src_access_mask = .{},
        .dst_access_mask = .{},
        .subresource_range = range,
        .src_queue_family_index = 0, // 0 == ignored
        .dst_queue_family_index = 0,
    };

    var width = @as(i32, @intCast(vkImage.pixelWidth));
    var height = @as(i32, @intCast(vkImage.pixelHeight));

    for (1..mipLevels) |i| {
        imb.subresource_range.base_mip_level = @as(u32, @intCast(i)) - 1;
        imb.old_layout = .undefined;
        imb.new_layout = .transfer_src_optimal;
        imb.src_access_mask = .{
            .transfer_write_bit = true,
        };
        imb.dst_access_mask = .{
            .transfer_read_bit = true,
        };

        ctx.vkd.cmdPipelineBarrier(cmd, .{
            .transfer_bit = true,
        }, .{
            .transfer_bit = true,
        }, .{}, 0, undefined, 0, undefined, 1, @ptrCast(&imb));

        var blit: vk.ImageBlit = undefined;
        blit.src_offsets[0] = .{ .x = 0, .y = 0, .z = 0 };
        blit.src_offsets[1] = .{ .x = width, .y = height, .z = 1 };
        blit.src_subresource = .{
            .aspect_mask = .{ .color_bit = true },
            .mip_level = @as(u32, @intCast(i)) - 1,
            .base_array_layer = 0,
            .layer_count = 1,
        };

        var dstWidth: i32 = 1;
        if (width > 1) {
            dstWidth = @divFloor(width, 2);
        }
        var dstHeight: i32 = 1;
        if (height > 1) {
            dstHeight = @divFloor(height, 2);
        }

        blit.dst_offsets[0] = .{ .x = 0, .y = 0, .z = 0 };
        blit.dst_offsets[1] = .{ .x = dstWidth, .y = dstHeight, .z = 1 };
        blit.dst_subresource = .{
            .aspect_mask = .{ .color_bit = true },
            .mip_level = @as(u32, @intCast(i)),
            .base_array_layer = 0,
            .layer_count = 1,
        };

        ctx.vkd.cmdBlitImage(
            cmd,
            img,
            .transfer_src_optimal,
            img,
            .transfer_dst_optimal,
            1,
            @ptrCast(&blit),
            .linear,
        );

        width = dstWidth;
        height = dstHeight;
    }
}

// A better encapsulated version of the NeonVkUploadContext
pub const NeonVkUploader = struct {
    gc: *NeonVkContext,
    arena: std.heap.ArenaAllocator,
    allocator: std.mem.Allocator,
    uploadFence: vk.Fence = undefined,
    commandPool: vk.CommandPool = undefined,
    commandBuffer: vk.CommandBuffer = undefined,
    mutex: std.Thread.Mutex = .{},
    isActive: bool = false,

    pub fn init(gc: *NeonVkContext, comptime tag: []const u8) !@This() {
        var arena = std.heap.ArenaAllocator.init(gc.allocator);
        var self = @This(){
            .arena = arena,
            .allocator = arena.allocator(),
            .gc = gc,
        };

        // create the uploadFence
        var fci = vk.FenceCreateInfo{
            .flags = .{ .signaled_bit = false },
        };
        self.uploadFence = try self.gc.vkd.createFence(self.gc.dev, &fci, null);

        // create the command pool
        var cpci = vkinit.commandPoolCreateInfo(@as(u32, @intCast(self.gc.graphicsFamilyIndex)), .{ .reset_command_buffer_bit = true });

        self.commandPool = try self.gc.vkd.createCommandPool(self.gc.dev, &cpci, null);

        // create the command buffer
        var cbai = vk.CommandBufferAllocateInfo{
            .command_pool = self.commandPool,
            .level = vk.CommandBufferLevel.primary,
            .command_buffer_count = 1,
        };

        try self.gc.vkd.allocateCommandBuffers(
            self.gc.dev,
            &cbai,
            @as([*]vk.CommandBuffer, @ptrCast(&self.commandBuffer)),
        );

        core.graphics_log("command buffer created from uploader {any} with tag {s}", .{ self.commandBuffer, tag });

        return self;
    }

    pub fn startUploadContext(self: *@This()) !void {
        self.mutex.lock();
        var cbi = vkinit.commandBufferBeginInfo(.{ .one_time_submit_bit = true });
        try self.gc.vkd.beginCommandBuffer(self.commandBuffer, &cbi);
        self.isActive = true;
    }

    pub fn addBufferUpload(
        self: *@This(),
        stagingBuffer: NeonVkBuffer,
        targetBuffer: NeonVkBuffer,
        transferSize: u32,
    ) !void {
        core.assert(self.isActive);
        var copy = vk.BufferCopy{
            .dst_offset = 0,
            .src_offset = 0,
            .size = transferSize,
        };

        const cmd = self.commandBuffer;

        self.gc.vkd.cmdCopyBuffer(
            cmd,
            stagingBuffer.buffer,
            targetBuffer.buffer,
            1,
            @as([*]const vk.BufferCopy, @ptrCast(&copy)),
        );
    }

    pub fn waitForFences(self: *@This()) !void {
        _ = try self.gc.vkd.waitForFences(
            self.gc.dev,
            1,
            @as([*]const vk.Fence, @ptrCast(&self.uploadFence)),
            1,
            1000000000,
        );

        try self.gc.vkd.resetFences(self.gc.dev, 1, @as([*]const vk.Fence, @ptrCast(&self.uploadFence)));
        self.isActive = false;
        self.mutex.unlock();
    }

    pub fn submitUploads(self: *@This()) !void {
        try self.gc.vkd.endCommandBuffer(self.commandBuffer);
        var submit = vkinit.submitInfo(&self.commandBuffer);
        try self.gc.vkd.queueSubmit(
            self.gc.graphicsQueue.handle,
            1,
            @as([*]const vk.SubmitInfo, @ptrCast(&submit)),
            self.uploadFence,
        );
    }

    pub fn finishUploadContext(self: *@This()) !void {
        try self.submitUploads();
        try self.waitForFences();
    }

    pub fn deinit(self: *@This()) void {
        self.gc.vkd.destroyCommandPool(self.gc.dev, self.commandPool, null);
        self.gc.vkd.destroyFence(self.gc.dev, self.uploadFence, null);
    }
};

pub const NeonVkUploadContext = struct {
    uploadFence: vk.Fence,
    commandPool: vk.CommandPool,
    commandBuffer: vk.CommandBuffer,
    mutex: std.Thread.Mutex = .{},
    active: bool = false,
};
