const std = @import("std");
const core = @import("../core.zig");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const obj_loader = @import("lib/objLoader/obj_loader.zig");
const vkinit = @import("vk_init.zig");
const vk_constants = @import("vk_constants.zig");
const tracy = core.tracy;

const image = @import("../image.zig");
const PngContents = image.PngContents;

const p2a = core.p_to_a;
const ObjMesh = obj_loader.ObjMesh;
const ArrayList = std.ArrayList;
const Vectorf = core.Vectorf;
const NeonVkContext = vk_renderer.NeonVkContext;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;
const NeonVkImage = vk_renderer.NeonVkImage;
const NumFrames = vk_constants.NUM_FRAMES;
const MAX_OBJECTS = vk_constants.MAX_OBJECTS;

const NeonVkObjectDataGpu = vk_renderer.NeonVkObjectDataGpu;

const transitions = @import("vk_transitions.zig");

const NeonVkSpriteDataGpu = struct {
    // tl, tr, br, bl running clockwise
    position: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    size: core.Vector2f = .{ .x = 1.0, .y = 1.0 },
};

// Takes the contents of a png file and transfers the pixel contents to a staged buffer
pub fn stagePixels(self: PngContents, ctx: *NeonVkContext) !NeonVkBuffer {
    var stagingBuffer = try ctx.create_buffer(self.pixels.len, .{ .transfer_src_bit = true }, .cpuOnly, "Stage pixels staging buffer");
    const data = try ctx.vkAllocator.vmaAllocator.mapMemory(stagingBuffer.allocation, u8);
    @memcpy(data, @ptrCast([*]const u8, self.pixels), self.pixels.len);
    ctx.vkAllocator.vmaAllocator.unmapMemory(stagingBuffer.allocation);
    return stagingBuffer;
}

pub const LoadAndStageImage = struct {
    stagingBuffer: NeonVkBuffer,
    image: NeonVkImage,
    mipLevel: u32,
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

    var stagingBuffer = try stagePixels(pngContents, ctx);

    var imageExtent = vk.Extent3D{
        .width = @intCast(u32, pngContents.size.x),
        .height = @intCast(u32, pngContents.size.y),
        .depth = 1,
    };

    var imgCreateInfo = vkinit.imageCreateInfo(.r8g8b8a8_srgb, .{
        .sampled_bit = true,
        .transfer_dst_bit = true,
    }, imageExtent, 1);

    var imgAllocInfo = vma.AllocationCreateInfo{
        .requiredFlags = .{},
        .usage = .gpuOnly,
    };

    var newImage = try ctx.vkAllocator.createImage(imgCreateInfo, imgAllocInfo, @src().fn_name);

    pngContents.deinit();

    return .{
        .stagingBuffer = stagingBuffer,
        .image = newImage,
        .mipLevel = std.math.log2(std.math.max(imageExtent.width, imageExtent.height)) + 1,
    };
}

pub fn submit_copy_from_staging(ctx: *NeonVkContext, stagingBuffer: NeonVkBuffer, newImage: NeonVkImage, mipLevel: u32) !void {
    var z1 = tracy.ZoneN(@src(), "submitting copy from staging buffer");
    defer z1.End();
    try ctx.start_upload_context(&ctx.uploadContext);
    {
        var z2 = tracy.ZoneN(@src(), "recording command buffer");
        var cmd = ctx.uploadContext.commandBuffer;

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
            p2a(&copyRegion),
        );

        transitions.transferDst_into_shaderReadOnly(ctx.vkd, cmd, newImage.image, mipLevel);
        z2.End();
    }
    try ctx.finish_upload_context(&ctx.uploadContext);
}

// this creates decriptors for sprites
pub fn create_sprite_descriptors(self: *NeonVkContext) !void {

    // 1. create bindings and set layout
    var bindings = [_]vk.DescriptorSetLayoutBinding{
        vkinit.descriptorSetLayoutBinding(.storage_buffer, .{ .vertex_bit = true }, 0),
    };

    var setLayoutCreateInfo = vk.DescriptorSetLayoutCreateInfo{
        .flags = .{},
        .binding_count = bindings.len,
        .p_bindings = @ptrCast([*]const vk.DescriptorSetLayoutBinding, &bindings),
    };

    self.spriteDescriptorLayout = try self.vkd.createDescriptorSetLayout(self.dev, &setLayoutCreateInfo, null);

    // create SSBOs for the actual type
    var i: usize = 0;
    while (i < NumFrames) : (i += 1) {
        self.frameData[i].spriteBuffer = try self.create_buffer(@sizeOf(NeonVkSpriteDataGpu) * vk_constants.MAX_OBJECTS, .{ .storage_buffer_bit = true }, .cpuToGpu, "Staging buffer");

        var spriteDescriptorSetAllocInfo = vk.DescriptorSetAllocateInfo{
            .descriptor_pool = self.descriptorPool,
            .descriptor_set_count = 1,
            .p_set_layouts = p2a(&self.spriteDescriptorLayout),
        };

        try self.vkd.allocateDescriptorSets(
            self.dev,
            &spriteDescriptorSetAllocInfo,
            @ptrCast([*]vk.DescriptorSet, &self.frameData[i].spriteDescriptorSet),
        );

        var spriteInfo = vk.DescriptorBufferInfo{
            .buffer = self.frameData[i].spriteBuffer.buffer,
            .offset = 0,
            .range = @sizeOf(NeonVkSpriteDataGpu) * vk_constants.MAX_OBJECTS,
        };

        var spriteWrite = vkinit.writeDescriptorSet(
            .storage_buffer,
            self.frameData[i].spriteDescriptorSet,
            &spriteInfo,
            0,
        );

        var spriteSetWrites = [_]@TypeOf(spriteWrite){spriteWrite};
        self.vkd.updateDescriptorSets(self.dev, 1, &spriteSetWrites, 0, undefined);
    }
}

pub fn upload_sprite_data(self: *NeonVkContext) !void {
    const allocation = self.frameData[self.nextFrameIndex].spriteBuffer.allocation;
    var data = try self.vkAllocator.vmaAllocator.mapMemory(allocation, NeonVkObjectDataGpu);
    var ssbo: []NeonVkSpriteDataGpu = undefined;
    ssbo.ptr = @ptrCast([*]NeonVkSpriteDataGpu, data);
    ssbo.len = MAX_OBJECTS;

    var i: usize = 0;
    while (i < MAX_OBJECTS and i < self.renderObjectSet.dense.len) : (i += 1) {
        ssbo[i].position = core.zm.mul(
            self.renderObjectSet.items(.renderObject)[i].transform,
            core.zm.Vec{ 0.0, 0.0, 0.0, 0.0 },
        );
        ssbo[i].size = .{ .x = 1.0, .y = 1.0 };
    }

    self.vkAllocator.vmaAllocator.unmapMemory(allocation);
}
