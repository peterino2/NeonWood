// this implements the global texture list

const gTextureList: *TextureList = undefined;

pub const ArrayedTexture = struct {};

pub const TextureList = struct {
    allocator: std.mem.Allocator,
    textures: std.AutoHashMapUnmanaged(u32, *Texture),
    gc: *NeonVkContext,
    listSet: vk.DescriptorSet = undefined,
    dsl: vk.DescriptorSetLayout = undefined,
    descriptorPool: vk.DescriptorPool = undefined,

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
            .textures = .{},
            .gc = gc,
        };

        try self.initTextureList();

        return self;
    }

    pub fn initTextureList(self: *@This()) !void {
        var poolInfo = vk.DescriptorPoolCreateInfo{
            .flags = .{},
            .max_sets = 1000,
            .pool_size_count = @intCast(descriptorPoolSizes.len),
            .p_pool_sizes = &descriptorPoolSizes,
        };

        self.descriptorPool = try vkd.createDescriptorPool(self.gc.dev, &poolInfo, null);

        const bindings = [_]vk.DescriptorSetLayoutBinding{
            .{
                .binding = 0,
                .descriptor_type = .storage_buffer,
                .descriptor_count = 1000,
                .stage_flags = .{
                    .vertex_bit = true,
                    .geometry_bit = true,
                    .compute_bit = true,
                    .fragment_bit = true,
                },
                .p_immutable_samplers = null,
            },
            .{
                .binding = 1,
                .descriptor_type = .combined_image_sampler,
                .descriptor_count = 1000,
                .stage_flags = .{
                    .vertex_bit = true,
                    .geometry_bit = true,
                    .compute_bit = true,
                    .fragment_bit = true,
                },
                .p_immutable_samplers = null,
            },
            .{
                .binding = 2,
                .descriptor_type = .storage_image,
                .descriptor_count = 1000,
                .stage_flags = .{
                    .vertex_bit = true,
                    .geometry_bit = true,
                    .compute_bit = true,
                    .fragment_bit = true,
                },
                .p_immutable_samplers = null,
            },
        };
        const flags = [_]vk.DescriptorBindingFlags{
            .{ .partially_bound_bit = true },
            .{ .partially_bound_bit = true },
            .{ .partially_bound_bit = true },
        };
        const fci = vk.DescriptorSetLayoutBindingFlagsCreateInfo{ .binding_count = 3, .p_binding_flags = @ptrCast(&flags) };

        const dsci = vk.DescriptorSetLayoutCreateInfo{
            .flags = .{},
            .binding_count = bindings.len,
            .p_bindings = @ptrCast(&bindings),
            .p_next = &fci,
        };

        self.dsl = try vkd.createDescriptorSetLayout(self.gc.dev, &dsci, null);

        const dsai = vk.DescriptorSetAllocateInfo{
            .descriptor_pool = self.descriptorPool,
            .descriptor_set_count = 1,
            .p_set_layouts = @ptrCast(&self.dsl),
        };

        try vkd.allocateDescriptorSets(self.gc.dev, &dsai, @ptrCast(&self.listSet));
    }

    pub fn destroy(self: *@This()) void {
        vkd.destroyDescriptorSetLayout(self.gc.dev, self.dsl, null);
        vkd.destroyDescriptorPool(self.gc.dev, self.descriptorPool, null);
        self.textures.deinit(self.allocator);
        self.allocator.destroy(self);
    }
};

const graphics = @import("../graphics.zig");
const NeonVkContext = graphics.NeonVkContext;

const texture = @import("../texture.zig");
const Texture = texture.Texture;

const vk = @import("vulkan");

const std = @import("std");

const vk_api = @import("../vk_api.zig");
const vkd = vk_api.vkd;
