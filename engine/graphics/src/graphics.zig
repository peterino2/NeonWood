const core = @import("core");
const std = @import("std");
const memory = core.MemoryTracker;
pub const vk_renderer = @import("vk_renderer.zig");
const materials = @import("materials.zig");

pub const graphics_ecs = @import("graphics_ecs.zig");
pub usingnamespace @import("debug_draws.zig");
pub const gpu_pipe_data = @import("gpu_pipe_data.zig");

pub const RenderThread = @import("vk_renderer/RenderThread.zig");
pub const vkinit = @import("vk_init.zig");
pub const vk_allocator = @import("vk_allocator.zig");
pub const NeonVkAllocator = vk_allocator.NeonVkAllocator;
pub const NeonVkPipelineBuilder = vk_renderer.NeonVkPipelineBuilder;
pub const NeonVkContext = vk_renderer.NeonVkContext;
pub const constants = @import("vk_constants.zig");
pub const NeonVkImage = vk_renderer.NeonVkImage;
pub const Material = materials.Material;
pub const RendererInterfaceRef = vk_renderer.RendererInterfaceRef;
pub const RendererInterface = vk_renderer.RendererInterface;
pub const texture = @import("texture.zig");
pub const debug_draw = @import("debug_draws.zig");
pub const mesh = @import("mesh.zig");
pub const Mesh = mesh.Mesh;
pub const DynamicMesh = mesh.DynamicMesh;
pub const IndexBuffer = mesh.IndexBuffer;
pub const Texture = texture.Texture;

pub const DynamicTexture = @import("dynamic_texture/DynamicTexture.zig");

pub const vk_util = @import("vk_utils.zig");
pub const createAndInstallTextureFromPixels = vk_util.createAndInstallTextureFromPixels;

const vk_api = @import("../vk_api.zig");
pub const vkd = &vk_api.vkd;
pub const vki = &vk_api.vki;
pub const vkb = &vk_api.vkb;

pub const PixelBufferRGBA8 = @import("PixelBufferRGBA8.zig");

pub const vk_assetLoaders = @import("vk_assetLoaders.zig");

pub const PixelPos = vk_renderer.PixelPos;

pub const NeonVkBuffer = vk_renderer.NeonVkBuffer;

pub const NumFrames = constants.NUM_FRAMES;

const engine_logs = core.engine_logs;
const engine_log = core.engine_log;

pub fn getContext() *NeonVkContext {
    return vk_renderer.gContext;
}

pub usingnamespace @import("vk_renderer/vk_renderer_types.zig");

pub const render_objects = @import("render_objects.zig");
pub const Camera = render_objects.Camera;
pub const RenderObject = render_objects.RenderObject;

pub fn registerRendererPlugin(value: anytype) !void {
    const ref = RendererInterfaceRef{
        .ptr = value,
        .vtable = &@TypeOf(value.*).RendererInterfaceVTable,
    };
    var gc = getContext();
    try gc.rendererPlugins.append(gc.allocator, ref);
}

pub fn start_module(comptime programSpec: anytype, args: anytype, allocator: std.mem.Allocator) !void {
    _ = args;
    _ = programSpec;
    engine_logs("graphics module starting up...");

    const context: *NeonVkContext = core.gEngine.createObject(
        NeonVkContext,
        .{ .can_tick = true, .isCore = true },
    ) catch unreachable;

    vk_renderer.gContext = context;
    try graphics_ecs.registerEcs(allocator);

    vk_assetLoaders.init_loaders(allocator) catch unreachable;

    debug_draw.init_debug_draw_subsystem() catch unreachable;
    memory.MTPrintStatsDelta();
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    _ = allocator;
    engine_logs("graphics module shutting down...");
    graphics_ecs.shutdownEcs();
    vk_renderer.gContext.shutdown();
}

pub var icon: []const u8 = "content/textures/icon.png";

pub fn setStartupSettings(comptime field: []const u8, value: anytype) void {
    @field(vk_renderer.gGraphicsStartupSettings, field) = value;
}

pub fn getStartupSettings() *const @TypeOf(vk_renderer.gGraphicsStartupSettings) {
    return &vk_renderer.gGraphicsStartupSettings;
}

pub fn loadSpv(allocator: std.mem.Allocator, path: []const u8) ![]const u32 {
    core.engine_log("loading path {s}", .{path});
    const search_prefixes: []const []const u8 = &.{
        "zig-out/shaders",
        "shaders",
    };

    var s_path: [4096]u8 = undefined;

    for (search_prefixes) |prefix| {
        const s = try std.fmt.bufPrint(&s_path, "{s}/{s}", .{ prefix, path });
        var file = std.fs.cwd().openFile(s, .{ .mode = .read_only }) catch continue;
        const filesize = (try file.stat()).size;
        const buffer: []u8 = try allocator.alignedAlloc(u8, 4, filesize);
        try file.reader().readNoEof(buffer);

        var rv: []u32 = undefined;
        rv.ptr = @as([*]u32, @ptrCast(@alignCast(buffer.ptr)));
        rv.len = buffer.len / 4;
        return rv;
    }

    return error.FileNotFound;
}

pub const rend = @import("rend_core.zig");
pub usingnamespace @import("rend_core.zig");

pub const gles_renderer = @import("gles_renderer.zig");

pub fn start_gles(allocator: std.mem.Allocator) void {
    gles_renderer.start(allocator);
}

pub fn shutdown_gles(allocator: std.mem.Allocator) void {
    gles_renderer.shutdown(allocator);
}

pub const Module = core.ModuleDescription{
    .name = "graphics",
    .enabledByDefault = true,
};
