// this implements the global texture list

const gTextureList: *TextureList = undefined;

pub const ArrayedTexture = struct {};

pub const TextureList = struct {
    allocator: std.mem.Allocator,
    textures: std.AutoHashMapUnmanaged(u32, *Texture),
    gc: *NeonVkContext,
    listSet: vk.DescriptorSet,

    const storageBinding = 0;
    const samplerBinding = 1;
    const imageBinding = 2;

    const descriptorPoolSizes = [_]vk.DescriptorPoolSize{
        .{ .type = .sampler, .descriptor_count = 1000 },
        .{ .type = .combined_image_sampler, .descriptor_count = 1000 },
        .{ .type = .sampled_image, .descriptor_count = 1000 },
        .{ .type = .storage_image, .descriptor_count = 1000 },
    };

    pub fn create(gc: *NeonVkContext) !*@This() {
        const self = try gc.allocator.create(@This());

        self.* = .{
            .allocator = gc.allocator,
            .gc = gc,
        };

        return self;
    }

    pub fn initTextureList(self: *@This()) void {
        var poolInfo = vk.DescriptorPoolCreateInfo{
            .flags = .{},
            .max_sets = 1000,
            .pool_size_count = @intCast(descriptorPoolSizes.len),
            .p_pool_sizes = &descriptorPoolSizes,
        };

        self.descriptorPool = try vkd.createDescriptorPool(self.gc, &poolInfo, null);
    }

    pub fn destroy(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

const graphics = @import("graphics");
const NeonVkContext = graphics.NeonVkContext;

const texture = @import("../texture.zig");
const Texture = texture.Texture;

const vk = @import("vulkan");

const std = @import("std");

const vk_api = @import("../vk_api.zig");
const vkd = vk_api.vkd;
