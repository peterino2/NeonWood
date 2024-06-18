// REEEEEEEEEEEEEE

const std = @import("std");
const core = @import("core");
const vk = @import("vulkan");
const vma = @import("vma");
const vk_constants = @import("vk_constants.zig");
const vk_api = @import("vk_api.zig");
const vkd = vk_api.vkd;

pub fn transferDst_into_shaderReadOnly(
    cmd: vk.CommandBuffer,
    image: vk.Image,
    mipLevel: u32,
) void {
    if (mipLevel == 0) {
        core.engine_logs("mipLevel 0 detected into_shaderReadOnly");
    }

    const range = vk.ImageSubresourceRange{
        .aspect_mask = .{ .color_bit = true },
        .base_mip_level = 0,
        .level_count = mipLevel,
        .base_array_layer = 0,
        .layer_count = 1,
    };

    var imageBarrier_toReadable = vk.ImageMemoryBarrier{
        .old_layout = .undefined,
        .new_layout = .shader_read_only_optimal,
        .image = image,
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
    vkd.cmdPipelineBarrier(
        cmd,
        .{ .transfer_bit = true },
        .{ .fragment_shader_bit = true },
        .{},
        0,
        undefined,
        0,
        undefined,
        1,
        @ptrCast(&imageBarrier_toReadable),
    );
}

pub fn into_transferDst(
    cmd: vk.CommandBuffer,
    image: vk.Image,
    mipLevel: u32,
) void {
    if (mipLevel == 0) {
        core.engine_logs("mipLevel 0 detected into_transferDst");
    }
    const range = vk.ImageSubresourceRange{
        .aspect_mask = .{ .color_bit = true },
        .base_mip_level = 0,
        .level_count = mipLevel,
        .base_array_layer = 0,
        .layer_count = 1,
    };

    var imageBarrier_toTransfer = vk.ImageMemoryBarrier{
        .old_layout = .undefined,
        .new_layout = .transfer_dst_optimal,
        .image = image,
        .subresource_range = range,
        .src_access_mask = .{},
        .dst_access_mask = .{
            .transfer_write_bit = true,
        },
        .src_queue_family_index = 0,
        .dst_queue_family_index = 0,
    };

    vkd.cmdPipelineBarrier(
        cmd,
        .{ .top_of_pipe_bit = true },
        .{ .transfer_bit = true },
        .{},
        0,
        undefined,
        0,
        undefined,
        1,
        @ptrCast(&imageBarrier_toTransfer),
    );
}
