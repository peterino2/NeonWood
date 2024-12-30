pub const SkeletalBuffers = struct {
    descriptorSet: vk.DescriptorSet,
    gc: *NeonVkContext,
    vkAllocator: *NeonVkAllocator,
    allocator: std.mem.Allocator,

    finalsBuffer: [2]NeonVkBuffer = undefined,

    pub fn init(gc: *NeonVkContext) !*@This() {
        const self = try gc.allocator.create(@This());

        self.* = .{
            .gc = gc,
            .allocator = gc.allocator,
            .vkAllocator = gc.vkAllocator,
            .skeletalPipeData = undefined,
        };

        self.buildBuffers();
        return self;
    }

    pub fn buildBuffers(self: *@This()) !void {
        const vkAllocator: *NeonVkAllocator = self.vkAllocator;

        // 100k animated skeletal mesh vertices ought to be enough for anyone right?
        for (0..2) |i| {
            self.finalsBuffer[i] = try vkAllocator.createSsboBuffer(@sizeOf(core.Mat) * 100_000, "bones buffer.");
        }
    }
};

const std = @import("std");
const core = @import("core");
const assets = @import("assets");
const graphics = @import("../graphics.zig");
const vk_renderer_types = @import("vk_renderer_types.zig");
const VertexBoneData = vk_renderer_types.VertexBoneData;
const gpd = graphics.gpu_pipe_data;
const NeonVkContext = graphics.NeonVkContext;
const NeonVkBuffer = graphics.NeonVkBuffer;
const NeonVkAllocator = graphics.NeonVkAllocator;
const vk = @import("vulkan");
