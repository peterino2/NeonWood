const std = @import("std");
const vk = @import("vulkan");
const graphics = @import("graphics");
const RenderThread = graphics.RenderThread;
const platform = @import("platform");
const vk_renderer = graphics.vk_renderer;
const core = @import("core");

const tracy = core.tracy;
const vk_constants = graphics.constants;

const use_renderthread = core.BuildOption("use_renderthread");

pub const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cDefine("CIMGUI_USE_GLFW", "1"); // if this needs a reference to glfw3, cleanest thing to do is to copy the glfw3 header here. I suspect it won't need it though.
    @cInclude("cimgui.h");
    @cInclude("cimgui_compat.h");
    @cInclude("cimgui_impl.h");
    @cInclude("cimplot.h");
});

const NeonVkContext = vk_renderer.NeonVkContext;

pub const Module: core.ModuleDescription = .{
    .name = "vkImgui",
    .enabledByDefault = true,
};

// new imgui integration
//
// arather than call imgui newframe only during the draw step.
//
// imgui NewFrame will be called in engine pre-tick
//
// this will make it safe to call imgui functions from anywhere within tick();

fn vkCast(comptime T: type, handle: anytype) T {
    return @as(T, @ptrFromInt(@as(u64, @intFromEnum(handle))));
}

// this data structure is invalid until you call setup
pub const NeonVkImGui = struct {
    const Self = @This();
    pub const NeonObjectTable = core.EngineObjectVTable.from(Self);
    pub const RendererInterfaceVTable = graphics.RendererInterface.from(Self);

    allocator: std.mem.Allocator,
    ctx: *NeonVkContext = undefined,
    descriptorPool: vk.DescriptorPool = undefined,

    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);

        self.* = Self{
            .allocator = allocator,
        };

        return self;
    }

    // NeonObject interface
    pub fn preTick(_: *Self, _: f64) core.EngineDataEventError!void {
        c.ImGui_ImplGlfw_NewFrame();
        c.cImGui_vk_NewFrame();
        c.igNewFrame();
    }

    // VkRenderer interface
    pub fn preDraw(self: *@This(), frameId: usize) void {
        _ = self;
        _ = frameId;
    }

    pub fn sendShared(self: *@This(), frameIndex: u32) void {
        _ = self;

        const z = core.tracy.ZoneN(@src(), "imgui uploading shared data");
        defer z.End();

        c.igRenderPlatformWindowsDefault(null, null);
        c.igRender();
        c.cimgui_vk_UploadSharedData(@intCast(frameIndex), c.igGetDrawData());
        c.igUpdatePlatformWindows();
    }

    pub fn rtPostDraw(self: *@This(), rt: *RenderThread, cmd: vk.CommandBuffer, frameIndex: u32) void {
        const z = core.tracy.ZoneN(@src(), "imgui render");
        defer z.End();

        _ = rt;
        _ = self;

        c.cImGui_vk_RenderDrawData(
            c.cimgui_vk_GetSharedData(@intCast(frameIndex)),
            vkCast(c.VkCommandBuffer, cmd),
            vkCast(c.VkPipeline, vk.Pipeline.null_handle),
        );
        c.cimgui_vk_ReleaseSharedData(@intCast(frameIndex));
    }

    pub fn postDraw(self: *@This(), cmd: vk.CommandBuffer, frameIndex: usize, deltaTime: f64) void {
        _ = self;
        _ = deltaTime;

        const z = core.tracy.ZoneN(@src(), "imgui render");

        c.igRenderPlatformWindowsDefault(null, null);
        c.igRender();

        c.cimgui_vk_UploadSharedData(@intCast(frameIndex), c.igGetDrawData());

        c.cImGui_vk_RenderDrawData(
            c.cimgui_vk_GetSharedData(@intCast(frameIndex)),
            vkCast(c.VkCommandBuffer, cmd),
            vkCast(c.VkPipeline, vk.Pipeline.null_handle),
        );
        c.cimgui_vk_ReleaseSharedData(@intCast(frameIndex));

        c.igUpdatePlatformWindows();

        z.End();
    }
    // VkRenderer interface end

    pub fn setup(self: *Self, ctx: *NeonVkContext) !void {
        self.ctx = ctx;

        const descriptorPoolSizes = [_]vk.DescriptorPoolSize{
            .{ .type = .sampler, .descriptor_count = 1000 },
            .{ .type = .combined_image_sampler, .descriptor_count = 1000 },
            .{ .type = .sampled_image, .descriptor_count = 1000 },
            .{ .type = .storage_image, .descriptor_count = 1000 },
            .{ .type = .uniform_texel_buffer, .descriptor_count = 1000 },
            .{ .type = .storage_texel_buffer, .descriptor_count = 1000 },
            .{ .type = .uniform_buffer, .descriptor_count = 1000 },
            .{ .type = .storage_buffer, .descriptor_count = 1000 },
            .{ .type = .uniform_buffer_dynamic, .descriptor_count = 1000 },
            .{ .type = .storage_buffer_dynamic, .descriptor_count = 1000 },
            .{ .type = .input_attachment, .descriptor_count = 1000 },
        };

        var poolInfo = vk.DescriptorPoolCreateInfo{
            .flags = .{},
            .max_sets = 1000,
            .pool_size_count = @intCast(descriptorPoolSizes.len),
            .p_pool_sizes = &descriptorPoolSizes,
        };

        self.descriptorPool = try ctx.vkd.createDescriptorPool(ctx.dev, &poolInfo, null);
        _ = c.igCreateContext(null);
        const io: *c.ImGuiIO = c.igGetIO();
        io.*.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard;
        io.*.ConfigFlags |= c.ImGuiConfigFlags_DockingEnable;
        // io.*.ConfigFlags |= c.ImGuiConfigFlags_ViewportsEnable;
        // const font = c.ImFontAtlas_AddFontFromFileTTF(io.*.Fonts, "content/VT323.ttf", 36, null, null);
        // _ = font;
        _ = c.ImGui_ImplGlfw_InitForVulkan(@ptrCast(platform.getInstance().window), true);

        const style = c.igGetStyle();
        c.igStyleColorsDark(style);
        style.*.WindowRounding = 0.0;
        style.*.Colors[c.ImGuiCol_WindowBg].w = 1.0;

        var imguiInit = c.ImGui_ImplVulkan_InitInfo{
            .Instance = vkCast(c.VkInstance, ctx.instance),
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
        // core.debug_struct("instance: ", ctx.instance);
        // core.debug_struct("huh: ", imguiInit);
        _ = c.cImGui_vk_Init(&imguiInit, vkCast(c.VkRenderPass, ctx.renderPass));

        // try ctx.start_upload_context(&ctx.uploadContext);
        try ctx.uploader.startUploadContext();
        _ = c.cImGui_vk_CreateFontsTexture(vkCast(c.VkCommandBuffer, ctx.uploader.commandBuffer));
        try ctx.uploader.finishUploadContext();
        _ = c.cImGui_vk_DestroyFontUploadObjects();

        _ = c.SetupImguiColors();

        c.cimgui_vk_PrepareSharedData();

        try self.ctx.registerRendererPlugin(self);
    }

    pub fn onRendererTeardown(self: *Self) void {
        // c.ImGui_ImplGlfw_Shutdown();
        if (use_renderthread)
            c.cImGui_vk_Shutdown();

        _ = self;
    }

    pub fn deinit(self: *Self) void {
        const ctx = self.ctx;
        ctx.vkd.deviceWaitIdle(ctx.dev) catch unreachable;
        if (!use_renderthread) {
            c.cImGui_vk_Shutdown();
        }
        ctx.vkd.destroyDescriptorPool(ctx.dev, self.descriptorPool, null);
        self.allocator.destroy(self);
    }
};

export fn checkVkResult(result: c_int) void {
    const r: vk.Result = @enumFromInt(result);
    if (r == vk.Result.success)
        return;

    core.graphics_log("This is a big problem, imgui call result: {any}", .{r});
    unreachable;
}

pub fn start_module(comptime programSpec: anytype, args: anytype, allocator: std.mem.Allocator) !void {
    _ = args;
    _ = programSpec;
    _ = allocator;
    const neonVkImgui = try core.createObject(NeonVkImGui, .{});
    try neonVkImgui.setup(graphics.getContext());
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    _ = allocator;
}
