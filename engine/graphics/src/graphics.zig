const core = @import("core");
const assets = @import("assets");
const std = @import("std");
const memory = core.MemoryTracker;
pub const ozz = @import("ozz");
const texture_cooking = @import("cooking/texture_cooking.zig");
const mesh_cooking = @import("cooking/mesh_cooking.zig");
pub const vk_renderer = @import("vk_renderer.zig");
const materials = @import("materials.zig");

pub usingnamespace @import("debug_draws.zig");
pub const gpu_pipe_data = @import("gpu_pipe_data.zig");
pub const BoneHandle = animation_system.BoneHandle;

pub const SkyboxSystem = @import("skybox.zig");
pub const setSkybox = SkyboxSystem.setSkybox;

pub const animation_system = @import("animation/animationSystem.zig");
pub const AnimationSystem = animation_system.AnimationSystem;
pub const Animator = animation_system.Animator;
pub const AnimationTrack = animation_system.AnimationTrack;
pub const Skeleton = animation_system.Skeleton;

const vk_cubemap = @import("vk_renderer/vk_cubemap.zig");
pub const CubeMapDirs = vk_cubemap.CubeMapDirs;
pub const MakeCubeMapList = vk_cubemap.MakeCubeMapList;

pub const animation_loaders = @import("animation/loaders.zig");

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
pub const MeshVertex = mesh.MeshVertex;

pub const mesh_pool = @import("vk_renderer/vk_mesh_pool.zig");
pub const MeshSourceType = mesh_pool.MeshSourceType;
pub const loadIndexedMeshForPooling = mesh_pool.loadIndexedMeshForPooling;
pub const getMeshPoolBuffers = mesh_pool.getMeshPoolBuffers;
pub const getIndexedMeshByName = mesh_pool.getIndexedMeshByName;

// pub const DynamicTexture = @import("dynamic_texture/DynamicTexture.zig");

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
pub const StaticMesh = render_objects.StaticMesh;
pub const IndexedMesh = mesh_pool.IndexedMesh;

pub fn registerRendererPlugin(value: anytype) !void {
    const ref = RendererInterfaceRef{
        .ptr = value,
        .vtable = &@TypeOf(value.*).RendererInterfaceVTable,
    };
    var gc = getContext();
    try gc.rendererPlugins.append(gc.allocator, ref);
}
var gCooking: bool = false;

const primitives = [_]assets.AssetImportReference{
    assets.MakeImportRef("Mesh", "m_primitive_sphere", "meshes/primitive_sphere.obj"),
    assets.MakeImportRef("Mesh", "m_primitive_box", "meshes/primitive_box.obj"),
    assets.MakeImportRef("Mesh", "m_primitive_line", "meshes/primitive_line.obj"),
    assets.MakeImportRef("Mesh", "m_skybox", "meshes/skybox.obj"),
};

pub fn start_module(comptime programSpec: anytype, args: anytype, allocator: std.mem.Allocator) !void {
    _ = args;
    engine_logs("graphics module starting up...");

    memory.MTPrintStatsDelta();
    const context: *NeonVkContext = core.gEngine.createObject(
        NeonVkContext,
        .{ .can_tick = true, .isCore = true },
    ) catch unreachable;
    memory.MTPrintStatsDelta();

    vk_renderer.gContext = context;

    const as = try core.createObject(AnimationSystem, .{ .can_tick = false });
    try animation_loaders.initLoaders();

    try registerRendererPlugin(as);

    vk_assetLoaders.init_loaders(allocator) catch unreachable;
    memory.MTPrintStatsDelta();

    try assets.loadList(primitives);
    debug_draw.init_debug_draw_subsystem() catch unreachable;

    context.skybox = SkyboxSystem.create(context.allocator) catch return core.EngineDataEventError.UnknownStatePanic;

    if (@hasField(@TypeOf(programSpec), "cooking")) {
        gCooking = true;
        try texture_cooking.initCooker(allocator);
        try mesh_cooking.initCooker(allocator);
    }

    memory.MTPrintStatsDelta();
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    _ = allocator;
    if (gCooking) {
        mesh_cooking.deinitCooker();
        texture_cooking.deinitCooker();
    }
    engine_logs("graphics module shutting down...");
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

pub const Module = core.ModuleDescription{
    .name = "graphics",
    .enabledByDefault = true,
};
