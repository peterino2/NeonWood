pub fn MakeCubeMapList(
    comptime left: []const u8,
    comptime up: []const u8,
    comptime down: []const u8,
    comptime front: []const u8,
    comptime back: []const u8,
) []const []const u8 {
    return &.{
        left,
        up,
        down,
        front,
        back,
    };
}

pub const CubeMapDirs = enum(u8) {
    right,
    left,
    up,
    down,
    front,
    back,
};

const vk_utils = @import("../vk_utils.zig");
const LoadAndStageImage = vk_utils.LoadAndStageImage;

pub fn stageCubeTexture(list: []const []const u8) !LoadAndStageImage {
    try core.assert(list.len == 6);

    const gc = graphics.getContext();
    const allocator = gc.allocator;

    var pngs: [6]core.png.PngContents = undefined;

    for (0..6) |i| {
        pngs[i] = try core.png.PngContents.initFromPathSpec(list[i], allocator);
    }
    defer {
        for (&pngs) |*png| {
            png.deinit();
        }
    }

    const width = pngs[0].size.x;
    const height = pngs[0].size.y;
    try core.assert(width == height);
    core.engine_log("cubemap dimensionss {d}x{d}", .{ width, height });

    var totalLen: u32 = 0;
    for (pngs) |png| {
        try core.assertf(width == png.size.x, "inconsistent cubemap dimensions", .{});
        try core.assertf(height == png.size.y, "inconsistent cubemap dimensions", .{});
        totalLen += @intCast(png.pixels.len);
    }

    const stagingBuffer = try gc.vkAllocator.createStagingBuffer(totalLen, "cubemap creation staging texture map");
    const pixelBuffer = try gc.vkAllocator.mapBuffer(u8, stagingBuffer);

    var offset: u32 = 0;

    var bufferOffsets: [6]u32 = undefined;
    for (pngs, 0..) |png, i| {
        const dest = pixelBuffer[offset .. offset + png.pixels.len];
        bufferOffsets[i] = offset;
        offset += @intCast(png.pixels.len);
        @memcpy(dest, png.pixels);
    }

    const imageExtent = vk.Extent3D{
        .width = @as(u32, @intCast(width)),
        .height = @as(u32, @intCast(height)),
        .depth = 1,
    };
    //const mipLevel = std.math.log2(@max(imageExtent.width, imageExtent.height)) + 1;
    const mipLevel = 1;

    var imgCreateInfo = vkinit.imageCreateInfo(.r8g8b8a8_srgb, .{
        .sampled_bit = true,
        .transfer_dst_bit = true,
    }, imageExtent, mipLevel);
    imgCreateInfo.array_layers = 6;
    imgCreateInfo.flags.cube_compatible_bit = true;

    if (mipLevel > 1) {
        imgCreateInfo.usage.transfer_src_bit = true;
    }

    const imgAllocInfo = vma.AllocationCreateInfo{
        .requiredFlags = .{},
        .usage = .gpuOnly,
    };
    const newImage = try gc.vkAllocator.createImage(imgCreateInfo, imgAllocInfo, "cubemap creation image");

    gc.vkAllocator.unmapMemory(stagingBuffer);

    return .{
        .stagingBuffer = stagingBuffer,
        .image = newImage,
        .mipLevel = mipLevel,
        .cubeOffsets = bufferOffsets,
    };
}

pub fn submitTextureCube(uploader: *vk_utils.NeonVkUploader, state: *const LoadAndStageImage) !void {
    try core.assert(state.cubeOffsets != null);

    if (state.cubeOffsets) |cubeOffsets| {
        try uploader.startUploadContext();
        {
            const newImage = state.image;
            const mipLevel = state.mipLevel;
            const cmd = uploader.commandBuffer;
            transitions.into_transferDst(cmd, newImage.image, mipLevel, 0, 6);
            for (cubeOffsets, 0..) |offset, face| {
                var copyRegion = vk.BufferImageCopy{
                    .buffer_offset = offset,
                    .buffer_row_length = 0,
                    .buffer_image_height = 0,
                    .image_offset = std.mem.zeroes(vk.Offset3D),
                    .image_subresource = .{
                        .aspect_mask = .{ .color_bit = true },
                        .mip_level = 0,
                        .base_array_layer = @intCast(face),
                        .layer_count = 1,
                    },
                    .image_extent = .{
                        .width = newImage.pixelWidth,
                        .height = newImage.pixelHeight,
                        .depth = 1,
                    },
                };

                vkd.cmdCopyBufferToImage(
                    cmd,
                    state.stagingBuffer.buffer,
                    newImage.image,
                    .transfer_dst_optimal,
                    1,
                    @ptrCast(&copyRegion),
                );

                try vk_utils.generateMipMaps(cmd, newImage, mipLevel, 0);
            }

            transitions.transferDst_into_shaderReadOnly(cmd, newImage.image, mipLevel, 0, 6);
        }
        try uploader.finishUploadContext();
    }
}

pub fn createDescriptorSet(
    dev: vk.Device,
) struct {
    layout: vk.DescriptorSetLayout,
    descriptorSet: vk.DescriptorSet,
} {
    _ = dev;
}

const core = @import("core");
const vk_renderer = @import("../vk_renderer.zig");

const vma = @import("vma");
const graphics = @import("../graphics.zig");
const vk = @import("vulkan");
const vkinit = @import("../vk_init.zig");
const vk_constants = @import("../vk_constants.zig");
const std = @import("std");
const vkd = vk_api.vkd;
const vk_api = @import("../vk_api.zig");

const transitions = @import("../vk_transitions.zig");
