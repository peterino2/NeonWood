const std = @import("std");
const vk = @import("vulkan");
const vk_renderer = @import("vk_renderer.zig");
const core = @import("../core.zig");
const vk_constants = @import("vk_constants.zig");
const c = vk_renderer.c;

const NeonVkContext = vk_renderer.NeonVkContext;

fn vkCast(comptime T: type, handle: anytype) T {
    return @ptrCast(T, @intToPtr(?*anyopaque, @enumToInt(handle)));
}

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
        io.*.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard;
        io.*.ConfigFlags |= c.ImGuiConfigFlags_DockingEnable;
        // io.*.ConfigFlags |= c.ImGuiConfigFlags_ViewportsEnable;
        var font = c.ImFontAtlas_AddFontFromFileTTF(io.*.Fonts, "content/VT323.ttf", 24, null, null);
        _ = font;
        _ = c.ImGui_ImplGlfw_InitForVulkan(ctx.window, true);

        var style = c.igGetStyle();
        c.igStyleColorsDark(style);
        style.*.WindowRounding = 0.0;
        style.*.Colors[c.ImGuiCol_WindowBg].w = 1.0;

        var imguiInit = c.ImGui_ImplVulkan_InitInfo{
            .Instance = vkCast(c.VkInstance, ctx.instance),
            ////.Instance = @ptrCast(c.VkInstance, @intToPtr(*anyopaque, @enumToInt(ctx.instance))),
            .PhysicalDevice = vkCast(c.VkPhysicalDevice, ctx.physicalDevice),
            .Device = vkCast(c.VkDevice, ctx.dev),
            .QueueFamily = ctx.graphicsQueue.family,
            .Queue = vkCast(c.VkQueue, ctx.graphicsQueue.handle),
            .PipelineCache = vkCast(c.VkPipelineCache, vk.PipelineCache.null_handle),
            .DescriptorPool = vkCast(c.VkDescriptorPool, self.descriptorPool),
            .Subpass = 0,
            .MinImageCount = 2,
            .ImageCount = vk_constants.NUM_FRAMES,
            .MSAASamples = 0x1,
            .Allocator = null,
            .CheckVkResultFn = checkVkResult,
        };
        _ = imguiInit;
        core.debug_struct("instance: ", ctx.instance);
        core.debug_struct("huh: ", imguiInit);
        _ = c.cImGui_vk_Init(&imguiInit, vkCast(c.VkRenderPass, ctx.renderPass));

        try ctx.start_upload_context(&ctx.uploadContext);
        _ = c.cImGui_vk_CreateFontsTexture(vkCast(c.VkCommandBuffer, ctx.uploadContext.commandBuffer));
        try ctx.finish_upload_context(&ctx.uploadContext);
        _ = c.cImGui_vk_DestroyFontUploadObjects();
    }

    pub fn setupVulkanWindow(self: *Self) void {
        var ctx = self.ctx;
        _ = ctx;
    }

    pub fn deinit(self: *Self) void {
        const ctx = self.ctx;
        ctx.vkd.deviceWaitIdle(ctx.dev) catch unreachable;

        c.cImGui_vk_Shutdown();
        // ... fuck... do i have to revert it
        ctx.vkd.destroyDescriptorPool(ctx.dev, self.descriptorPool, null);
    }
};

export fn checkVkResult(result: c_int) void {
    const r = @intToEnum(vk.Result, result);
    if (r == vk.Result.success)
        return;

    core.graphics_log("This is a big problem imgui call result: {any}", .{r});
    unreachable;
}
