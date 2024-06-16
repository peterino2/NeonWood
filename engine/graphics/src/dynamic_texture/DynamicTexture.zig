// really simple.
// one persistently mapped staging buffer which is used as the cpu sided write. buffer
//

allocator: std.mem.Allocator,
stagingBuffer: NeonVkBuffer,
image: NeonVkImage,
descriptor: vk.DescriptorSet,

pub fn create(
    allocator: std.mem.Allocator,
    vkAllocator: *NeonVkAllocator,
    extents: vk.Extent2D,
) !*@This() {
    const imageExtent = vk.Extent3D{
        .width = extents.width,
        .height = extents.height,
        .depth = 1,
    };

    const imageCreateInfo = vkinit.imageCreateInfo(.r8g8b8a8_srgb, .{
        .sampled_bit = true,
        .transfer_dst_bit = true,
    }, imageExtent, 1);

    const image = try vkAllocator.createImage(imageCreateInfo, .{ .requiredFlags = .{}, .usage = .gpuOnly }, @src().fn_name ++ " - create image Dynamictexture");

    const bufferSize = extents.width * extents.height * 4;

    const cbi = vk.BufferCreateInfo{
        .size = bufferSize,
        .usage = .{ .transfer_src_bit = true },
        .flags = .{},
        .sharing_mode = .exclusive,
        .queue_family_index_count = 0,
        .p_queue_family_indices = undefined,
    };

    const stagingBuffer = try vkAllocator.createBuffer(cbi, .{ .usage = .cpuOnly }, " - create image Dynamictexture");

    // dynamic textures shall not support mips at this time.

    const self = try allocator.create(@This());
    self.* = .{
        .allocator = allocator,
        .image = image,
        .descriptor = undefined,
        //     .descriptor = undefined,
        .stagingBuffer = stagingBuffer,
    };

    return self;
}

pub fn destroy(self: *@This(), vkAllocator: *NeonVkAllocator) void {
    vkAllocator.destroyImage(&self.image);
    vkAllocator.destroyBuffer(&self.stagingBuffer);
    self.allocator.destroy(self);
}

const std = @import("std");
const vk = @import("vulkan");

const vkinit = @import("../vk_init.zig");

const vk_api = @import("../vk_api.zig");
const vkd = vk_api.vkd;
const vki = vk_api.vki;
const vkb = vk_api.vkb;

const vk_allocator = @import("../vk_allocator.zig");

const NeonVkBuffer = vk_allocator.NeonVkBuffer;
const NeonVkAllocator = vk_allocator.NeonVkAllocator;
const NeonVkImage = vk_allocator.NeonVkImage;
