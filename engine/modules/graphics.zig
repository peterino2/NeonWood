const core = @import("core.zig");
const std = @import("std");
pub const vk_renderer = @import("graphics/vk_renderer.zig");
const materials = @import("graphics/materials.zig");

pub usingnamespace @import("graphics/debug_draws.zig");
pub const gpu_pipe_data = @import("graphics/gpu_pipe_data.zig");
pub const vkinit = @import("graphics/vk_init.zig");
pub const c = vk_renderer.c;
pub const vk_allocator = @import("graphics/vk_allocator.zig");
pub const NeonVkAllocator = vk_allocator.NeonVkAllocator;
pub const NeonVkPipelineBuilder = vk_renderer.NeonVkPipelineBuilder;
pub const NeonVkContext = vk_renderer.NeonVkContext;
pub const vk_ui = @import("graphics/vk_imgui.zig");
pub const constants = @import("graphics/vk_constants.zig");
pub const NeonVkImGui = vk_ui.NeonVkImGui;
pub const NeonVkImage = vk_renderer.NeonVkImage;
pub const Material = materials.Material;
pub const RendererInterfaceRef = vk_renderer.RendererInterfaceRef;
pub const RendererInterface = vk_renderer.RendererInterface;
pub const texture = @import("graphics/texture.zig");
pub const debug_draw = @import("graphics/debug_draws.zig");
pub const mesh = @import("graphics/mesh.zig");
pub const Mesh = mesh.Mesh;
pub const DynamicMesh = mesh.DynamicMesh;
pub const IndexBuffer = mesh.IndexBuffer;
pub const Texture = texture.Texture;

pub const vk_util = @import("graphics/vk_utils.zig");
pub const createTextureFromPixelsSync = vk_util.createTextureFromPixelsSync;

pub const imguiUtils = @import("graphics/igUtils.zig");

pub const vk_assetLoaders = @import("graphics/vk_assetLoaders.zig");

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
pub const RenderObject = render_object.RenderObject;

pub var gImgui: *NeonVkImGui = undefined;

pub fn registerRendererPlugin(value: anytype) !void {
    var ref = RendererInterfaceRef{
        .ptr = value,
        .vtable = &@TypeOf(value.*).RendererInterfaceVTable,
    };
    var gc = getContext();
    try gc.rendererPlugins.append(gc.allocator, ref);
}

pub fn start_module(allocator: std.mem.Allocator) void {
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

    vk_assetLoaders.init_loaders(allocator) catch unreachable;

    debug_draw.init_debug_draw_subsystem() catch unreachable;
}

pub fn shutdown_module() void {
    gImgui.deinit();
    debug_draw.deinit() catch unreachable;
    vk_renderer.gContext.deinit();
    engine_logs("graphics module shutting down...");
}

pub var icon: []const u8 = "content/textures/icon.png";

pub fn setStartupSettings(comptime field: []const u8, value: anytype) void {
    @field(vk_renderer.gGraphicsStartupSettings, field) = value;
}

pub fn loadSpv(allocator: std.mem.Allocator, path: []const u8) ![]const u32 {
    var file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    const filesize = (try file.stat()).size;
    var buffer: []u8 = try allocator.alignedAlloc(u8, 4, filesize);
    try file.reader().readNoEof(buffer);

    var rv: []u32 = undefined;
    rv.ptr = @as([*]u32, @ptrCast(@alignCast(buffer.ptr)));
    rv.len = buffer.len / 4;
    return rv;
}
