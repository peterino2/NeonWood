const vk = @import("vulkan");
const core = @import("../core/core.zig");

const p2a = core.p_to_a;

pub fn DescriptorSetLayoutBinding(
    descriptorType: vk.DescriptorType,
    stageFlags: vk.ShaderStageFlags,
    binding: u32,
) vk.DescriptorSetLayoutBinding {
    return vk.DescriptorSetLayoutBinding{
        .binding = binding,
        .descriptor_count = 1,
        .descriptor_type = descriptorType,
        .stage_flags = stageFlags,
        .p_immutable_samplers = null,
    };
}

pub fn WriteDescriptorSet(
    descriptorType: vk.DescriptorType,
    dst_set: vk.DescriptorSet,
    bufferInfo: *vk.DescriptorBufferInfo,
    binding: u32,
) vk.WriteDescriptorSet {
    var setWrite = vk.WriteDescriptorSet{
        .dst_binding = binding,
        .dst_set = dst_set,
        .descriptor_count = 1,
        .descriptor_type = descriptorType,
        .p_buffer_info = p2a(bufferInfo),
        .dst_array_element = 0,
        .p_image_info = undefined,
        .p_texel_buffer_view = undefined,
    };

    return setWrite;
}
