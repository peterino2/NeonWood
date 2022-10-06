const core = @import("core.zig");
const std = @import("std");
const vk_renderer = @import("graphics/vk_renderer.zig");
const materials = @import("graphics/materials.zig");

pub const gpu_pipe_data = @import("graphics/gpu_pipe_data.zig");
pub const vkinit = @import("graphics/vk_init.zig");
pub const c = vk_renderer.c;
pub const NeonVkPipelineBuilder = vk_renderer.NeonVkPipelineBuilder;
pub const NeonVkContext = vk_renderer.NeonVkContext;
pub const vk_ui = @import("graphics/vk_imgui.zig");
pub const constants = @import("graphics/vk_constants.zig");
pub const NeonVkImGui = vk_ui.NeonVkImGui;
pub const NeonVkImage = vk_renderer.NeonVkImage;
pub const Material = materials.Material;
pub const RendererInterfaceRef = vk_renderer.RendererInterfaceRef;
pub const RendererInterface = vk_renderer.RendererInterface;

pub const PixelPos = vk_renderer.PixelPos;

pub const NeonVkBuffer = vk_renderer.NeonVkBuffer;

pub const setWindowName = vk_renderer.setWindowName;
pub const NumFrames = constants.NUM_FRAMES;

const engine_logs = core.engine_logs;
const engine_log = core.engine_log;


pub fn getContext() *NeonVkContext {
    return vk_renderer.gContext;
}

pub const render_object = @import("graphics/render_object.zig");
pub const Camera = render_object.Camera;

pub var gImgui: *NeonVkImGui = undefined;

pub fn registerRendererPlugin(value: anytype) !void
{
    var ref = RendererInterfaceRef{
        .ptr = value, 
        .vtable = &@TypeOf(value.*).RendererInterfaceVTable,
    };
    var gc = getContext();
    try gc.rendererPlugins.append(gc.allocator, ref);
}

pub fn start_module() void {
    engine_logs("graphics module starting up...");

    var context: *NeonVkContext = core.gEngine.createObject(
        NeonVkContext,
        .{ .can_tick = true },
    ) catch unreachable;
    vk_renderer.gContext = context;

    var vkUi: *NeonVkImGui = core.gEngine.createObject(
        NeonVkImGui,
        .{ .can_tick = false },
    ) catch unreachable;
    gImgui = vkUi;

    vkUi.setup(context) catch unreachable;
}

pub fn shutdown_module() void {
    gImgui.deinit();
    vk_renderer.gContext.deinit();
    engine_logs("graphics module shutting down...");
}
