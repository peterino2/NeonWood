const vk = @import("vulkan");
const core = @import("../core.zig");

const p2a = core.p_to_a;

pub fn descriptorSetLayoutBinding(
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

pub fn writeDescriptorSet(
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

pub fn commandPoolCreateInfo(
    queueFamilyIndex: u32,
    flags: vk.CommandPoolCreateFlags,
) vk.CommandPoolCreateInfo {
    var self = vk.CommandPoolCreateInfo{
        .queue_family_index = queueFamilyIndex,
        .flags = flags,
    };

    return self;
}

pub fn submitInfo(cmd: *vk.CommandBuffer) vk.SubmitInfo {
    var info = vk.SubmitInfo{
        .wait_semaphore_count = 0,
        .signal_semaphore_count = 0,
        .command_buffer_count = 1,
        .p_command_buffers = @ptrCast([*]const vk.CommandBuffer, cmd),
        .p_wait_semaphores = undefined,
        .p_wait_dst_stage_mask = undefined,
        .p_signal_semaphores = undefined,
    };

    return info;
}

pub fn commandBufferBeginInfo(flags: vk.CommandBufferUsageFlags) vk.CommandBufferBeginInfo {
    var cbi = vk.CommandBufferBeginInfo{
        .p_inheritance_info = null,
        .flags = flags,
    };
    return cbi;
}

pub fn imageCreateInfo(
    format: vk.Format,
    usageFlags: vk.ImageUsageFlags,
    extent: vk.Extent3D,
    mipLevel: u32, // should default to 1
) vk.ImageCreateInfo {
    var img_create = vk.ImageCreateInfo{
        .flags = .{},
        .sharing_mode = .exclusive,
        .queue_family_index_count = 0,
        .p_queue_family_indices = undefined,
        .initial_layout = .undefined,
        .image_type = .@"2d",
        .format = format,
        .extent = extent,
        .mip_levels = mipLevel,
        .array_layers = 1,
        .samples = .{
            .@"1_bit" = true,
        },
        .tiling = .optimal,
        .usage = usageFlags,
    };
    return img_create;
}

pub fn imageViewCreateInfo(
    format: vk.Format,
    image: vk.Image,
    aspectFlags: vk.ImageAspectFlags,
    mipLevel: u32,
) vk.ImageViewCreateInfo {
    var ivci = vk.ImageViewCreateInfo{
        .flags = .{},
        .image = image,
        .view_type = .@"2d",
        .format = format,
        .components = .{ .r = .r, .g = .g, .b = .b, .a = .a },
        .subresource_range = .{
            .aspect_mask = aspectFlags,
            .base_mip_level = 0,
            .level_count = mipLevel,
            .base_array_layer = 0,
            .layer_count = 1,
        },
    };

    return ivci;
}

pub fn samplerCreateInfo(
    filters: vk.Filter,
    samplerAddressMode: ?vk.SamplerAddressMode,
) vk.SamplerCreateInfo {
    var addressMode = if (samplerAddressMode != null) samplerAddressMode.? else .repeat;

    var self = vk.SamplerCreateInfo{
        .flags = .{},
        .mag_filter = filters,
        .min_filter = .nearest,
        .address_mode_u = addressMode,
        .address_mode_v = addressMode,
        .address_mode_w = addressMode,
        .mipmap_mode = .nearest,
        .mip_lod_bias = 0.0,
        .anisotropy_enable = vk.FALSE,
        .max_anisotropy = 0.0,
        .compare_enable = vk.FALSE,
        .compare_op = .never,
        .min_lod = 0.0,
        .max_lod = 0.0,
        .border_color = .float_transparent_black,
        .unnormalized_coordinates = vk.FALSE,
    };

    if (filters == .linear) {
        self.max_lod = 4;
        self.mipmap_mode = .linear;
    }

    return self;
}

pub fn writeDescriptorImage(
    descriptorType: vk.DescriptorType,
    dstSet: vk.DescriptorSet,
    imageInfo: *vk.DescriptorImageInfo,
    binding: u32,
) vk.WriteDescriptorSet {
    var setWrite = vk.WriteDescriptorSet{
        .dst_binding = binding,
        .dst_set = dstSet,
        .descriptor_count = 1,
        .descriptor_type = descriptorType,
        .p_buffer_info = undefined,
        .dst_array_element = 0,
        .p_image_info = p2a(imageInfo),
        .p_texel_buffer_view = undefined,
    };

    return setWrite;
}
