const std = @import("std");
const vk = @import("vulkan");

pub const VkCommand = union(enum(u8)) {
    image: struct {
        index: u32,
        imageSet: ?*vk.DescriptorSet,
    },
    text: struct {
        index: u32,
        small: bool,
        ssbo: u32,
    },
};
