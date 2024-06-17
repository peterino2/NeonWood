// really simple.
// one persistently mapped staging buffer which is used as the cpu sided write. buffer
//

allocator: std.mem.Allocator,
stagingBuffer: NeonVkBuffer,
image: NeonVkImage,
imageView: vk.ImageView,
descriptor: vk.DescriptorSet,
registered: bool = false,

pub fn create(
    gc: *NeonVkContext,
    extents: vk.Extent2D,
) !*@This() {
    const imageExtent = vk.Extent3D{
        .width = extents.width,
        .height = extents.height,
        .depth = 1,
    };

    const allocator = gc.allocator;

    const imageCreateInfo = vkinit.imageCreateInfo(.r8g8b8a8_srgb, .{
        .sampled_bit = true,
        .transfer_dst_bit = true,
    }, imageExtent, 1);

    const image = try gc.vkAllocator.createImage(imageCreateInfo, .{ .requiredFlags = .{}, .usage = .gpuOnly }, @src().fn_name ++ " - create image Dynamictexture");

    const bufferSize = extents.width * extents.height * 4;

    const cbi = vk.BufferCreateInfo{
        .size = bufferSize,
        .usage = .{ .transfer_src_bit = true },
        .flags = .{},
        .sharing_mode = .exclusive,
        .queue_family_index_count = 0,
        .p_queue_family_indices = undefined,
    };

    const stagingBuffer = try gc.vkAllocator.createBuffer(cbi, .{ .usage = .cpuOnly }, " - create image Dynamictexture");

    const data = try gc.vkAllocator.mapBuffer(core.colors.ColorRGBA8, stagingBuffer);
    for (data) |*d| {
        d.* = .{ .g = 0xff };
    }

    gc.vkAllocator.unmapMemory(stagingBuffer);

    var imageViewCreate = vkinit.imageViewCreateInfo(
        .r8g8b8a8_srgb,
        image.image,
        .{ .color_bit = true },
        1, // mip
    );

    const view = vkd.createImageView(gc.dev, &imageViewCreate, null) catch return error.UnknownStatePanic;

    // dynamic textures shall not support mips
    const self = try allocator.create(@This());
    self.* = .{
        .allocator = allocator,
        .image = image,
        .imageView = view,
        .descriptor = try gc.create_mesh_image_for_texture(.{ .image = image, .imageView = view }, .{ .useBlocky = true }),
        .stagingBuffer = stagingBuffer,
    };

    return self;
}

pub fn issueUpload(self: *@This(), cmd: vk.CommandBuffer) !void {
    const mipLevel = 1;
    const z1 = tracy.ZoneN(@src(), "submitting dynamic texture buffer");
    defer z1.End();

    transitions.into_transferDst(cmd, self.image.image, 1);

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
            .width = self.image.pixelWidth,
            .height = self.image.pixelHeight,
            .depth = 1,
        },
    };

    vkd.cmdCopyBufferToImage(
        cmd,
        self.stagingBuffer.buffer,
        self.image.image,
        .transfer_dst_optimal,
        1,
        @ptrCast(&copyRegion),
    );

    transitions.transferDst_into_shaderReadOnly(cmd, self.image.image, mipLevel);
}

pub fn debug_installToContext(self: *@This(), name: core.Name) !void {
    const gc = graphics.getContext();

    self.registered = true;

    const newTexture = try gc.allocator.create(texture.Texture);

    newTexture.* = texture.Texture{
        .image = self.image,
        .imageView = self.imageView,
    };

    try gc.install_texture_into_registry(name, newTexture, self.descriptor);
    try gc.dynamicTextures.append(self.allocator, self);
}

pub fn debug_getBufferMapping(self: *@This()) ![]core.colors.ColorRGBA8 {
    return try graphics.getContext().vkAllocator.mapBuffer(core.colors.ColorRGBA8, self.stagingBuffer);
}

pub fn debug_removeMapping(self: *@This()) void {
    graphics.getContext().vkAllocator.unmapMemory(self.stagingBuffer);
}

pub fn destroy(self: *@This(), vkAllocator: *NeonVkAllocator) void {
    if (!self.registered) {
        vkAllocator.destroyImage(&self.image);
    }

    vkAllocator.destroyBuffer(&self.stagingBuffer);
    self.allocator.destroy(self);
}

const transitions = @import("../vk_transitions.zig");
const std = @import("std");
const core = @import("core");
const tracy = core.tracy;
const graphics = @import("../graphics.zig");
const vk = @import("vulkan");

const vkinit = @import("../vk_init.zig");
const texture = @import("../texture.zig");

const vk_api = @import("../vk_api.zig");
const vkd = vk_api.vkd;
const vki = vk_api.vki;
const vkb = vk_api.vkb;

const vk_allocator = @import("../vk_allocator.zig");

const NeonVkContext = @import("../vk_renderer.zig").NeonVkContext;
const NeonVkBuffer = vk_allocator.NeonVkBuffer;
const NeonVkAllocator = vk_allocator.NeonVkAllocator;
const NeonVkImage = vk_allocator.NeonVkImage;
