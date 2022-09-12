const std = @import("std");
const vk = @import("vulkan");
const vk_renderer = @import("vk_renderer.zig");
const core = @import("../core.zig");
pub const c = @import("c.zig");

const NeonVkContext = vk_renderer.NeonVkContext;

// this data structure is invalid until you call setup
pub const NeonVkImGui = struct {
    const Self = @This();
    pub const NeonObjectTable = core.RttiData.from(Self);

    allocator: std.mem.Allocator,
    ctx: *NeonVkContext = undefined,
    descriptorPool: vk.DescriptorPool = undefined,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
        };

        return self;
    }

    pub fn setup(self: *Self, ctx: *NeonVkContext) !void {
        self.ctx = ctx;

        const descriptorPoolSizes = [_]vk.DescriptorPoolSize{
            .{ .@"type" = .sampler, .descriptor_count = 1000 },
            .{ .@"type" = .combined_image_sampler, .descriptor_count = 1000 },
            .{ .@"type" = .sampled_image, .descriptor_count = 1000 },
            .{ .@"type" = .storage_image, .descriptor_count = 1000 },
            .{ .@"type" = .uniform_texel_buffer, .descriptor_count = 1000 },
            .{ .@"type" = .storage_texel_buffer, .descriptor_count = 1000 },
            .{ .@"type" = .uniform_buffer, .descriptor_count = 1000 },
            .{ .@"type" = .storage_buffer, .descriptor_count = 1000 },
            .{ .@"type" = .uniform_buffer_dynamic, .descriptor_count = 1000 },
            .{ .@"type" = .storage_buffer_dynamic, .descriptor_count = 1000 },
            .{ .@"type" = .input_attachment, .descriptor_count = 1000 },
        };
        _ = descriptorPoolSizes;

        var poolInfo = vk.DescriptorPoolCreateInfo{
            .flags = .{},
            .max_sets = 1000,
            .pool_size_count = @intCast(u32, descriptorPoolSizes.len),
            .p_pool_sizes = &descriptorPoolSizes,
        };

        self.descriptorPool = try ctx.vkd.createDescriptorPool(ctx.dev, &poolInfo, null);

        _ = c.igCreateContext(null);
        var io: *c.ImGuiIO = c.igGetIO();
        io.*.ConfigFlags = c.ImGuiConfigFlags_NavEnableKeyboard;
        _ = c.ImGui_ImplGlfw_InitForVulkan(ctx.window, true);
    }

    pub fn deinit(self: *Self) void {
        const ctx = self.ctx;

        ctx.vkd.destroyDescriptorPool(ctx.dev, self.descriptorPool, null);
    }
};
