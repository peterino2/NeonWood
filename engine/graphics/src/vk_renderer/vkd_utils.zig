const vk_constants = @import("../vk_constants.zig");
const vk_api = @import("../vk_api.zig");
const vkd = vk_api.vkd;
const vki = vk_api.vki;
const vkb = vk_api.vkb;
const vk = @import("vulkan");

const graphics = @import("../graphics.zig");
const NeonVkBuffer = graphics.NeonVkBuffer;

pub fn copyStagingSlice(
    comptime Element: type,
    cmd: vk.CommandBuffer,
    params: struct {
        src: *NeonVkBuffer,
        dst: *NeonVkBuffer,
        size: u32, // in element count
        src_offset: u32 = 0, // in element counts
        dst_offset: u32 = 0, // in element counts
    },
) void {
    const elementSize = @sizeOf(Element);
    var copy = vk.BufferCopy{
        .dst_offset = params.dst_offset * elementSize,
        .src_offset = params.src_offset * elementSize,
        .size = params.size * elementSize,
    };
    vkd.cmdCopyBuffer(
        cmd,
        params.src.buffer,
        params.dst.buffer,
        1,
        @as([*]const vk.BufferCopy, @ptrCast(&copy)),
    );
}
