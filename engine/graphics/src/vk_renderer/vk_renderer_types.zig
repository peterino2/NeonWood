const std = @import("std");
const vk = @import("vulkan");

const core = @import("core");

const vk_renderer = @import("../vk_renderer.zig");
const NeonVkContext = vk_renderer.NeonVkContext;

const vk_allocator = @import("../vk_allocator.zig");
const vk_constants = @import("../vk_constants.zig");

pub const NeonVkSwapImage = struct {
    image: vk.Image,
    view: vk.ImageView,
    imageIndex: usize,

    pub fn deinit(self: *NeonVkSwapImage, ctx: *NeonVkContext) void {
        ctx.vkd.destroyImageView(ctx.dev, self.view, null);
    }
};

pub const NeonVkQueue = struct {
    handle: vk.Queue,
    family: u32,

    pub fn init(vkd: vk_constants.DeviceDispatch, dev: vk.Device, family: u32) @This() {
        return .{
            .handle = vkd.getDeviceQueue(dev, family, 0),
            .family = family,
        };
    }
};

pub const NeonVkFrameData = struct {
    // descriptors
    globalDescriptorSet: vk.DescriptorSet,
    objectDescriptorSet: vk.DescriptorSet,
    spriteDescriptorSet: vk.DescriptorSet,

    // buffers
    spriteBuffer: vk_allocator.NeonVkBuffer,
    objectBuffer: vk_allocator.NeonVkBuffer,
    cameraBuffer: vk_allocator.NeonVkBuffer,
};

pub const NeonVkObjectDataGpu = struct {
    modelMatrix: core.Mat,
};

pub const NeonVkSceneDataGpu = struct {
    fogColor: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    fogDistances: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    ambientColor: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    sunlightDirection: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
    sunlightColor: core.zm.Vec = .{ 0.0, 0.0, 0.0, 0.0 },
};

pub const descriptorPoolSizes = [_]vk.DescriptorPoolSize{
    .{ .type = .uniform_buffer, .descriptor_count = 1000 },
    .{ .type = .uniform_buffer_dynamic, .descriptor_count = 1000 },
    .{ .type = .storage_buffer, .descriptor_count = 1000 },
    .{ .type = .combined_image_sampler, .descriptor_count = 1000 },
};
