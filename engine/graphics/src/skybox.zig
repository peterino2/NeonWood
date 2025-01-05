allocator: std.mem.Allocator,
cubeMapShared: [graphics.NumFrames]?vk.DescriptorSet = .{ null, null },
cubeMapTextureSet: ?vk.DescriptorSet = null,
cubeMapName: ?core.Name = null,
material: *graphics.Material = undefined,
mesh: ?graphics.IndexedMesh = null,

pub const RendererInterfaceVTable = graphics.RendererInterface.from(@This());

pub var gSkybox: *@This() = undefined;

pub fn create(allocator: std.mem.Allocator) !*@This() {
    const self = try allocator.create(@This());

    self.* = .{
        .allocator = allocator,
    };

    gSkybox = self;
    try self.initPipeline();
    try graphics.registerRendererPlugin(self);

    return self;
}

pub fn sendShared(self: *@This(), fi: u32) void {
    if (self.cubeMapName == null) {
        self.cubeMapShared[fi] = self.cubeMapTextureSet;
        return;
    } else {
        if (self.mesh == null)
            self.mesh = graphics.getIndexedMeshByName(core.MakeName("m_skybox"));

        if (self.cubeMapTextureSet == null) {
            const handle = self.cubeMapName.?.handle();
            self.cubeMapTextureSet = graphics.getContext().textureSets.get(handle);
        }
    }

    self.cubeMapShared[fi] = self.cubeMapTextureSet;
}

pub fn initPipeline(self: *@This()) !void {
    const gc = graphics.getContext();

    var pipelineBuilder = try graphics.NeonVkPipelineBuilder.init(
        gc.dev,
        gc.vkd,
        self.allocator,
        gc.vkAllocator,
        skybox_vert.spv(),
        skybox_frag.spv(),
    );
    defer pipelineBuilder.deinit();

    try pipelineBuilder.add_mesh_description();
    try pipelineBuilder.add_layout(gc.globalDescriptorLayout);
    try pipelineBuilder.add_layout(gc.singleTextureSetLayout);
    try pipelineBuilder.add_depth_stencil(); // todo.. we might not want this for a skybox.
    try pipelineBuilder.init_triangle_pipeline(gc.actual_extent);
    pipelineBuilder.pdsci.?.depth_write_enable = vk.FALSE;
    pipelineBuilder.pdsci.?.depth_test_enable = vk.FALSE;
    pipelineBuilder.pdsci.?.depth_compare_op = .never;

    const materialName = core.MakeName("Mat_skybox");
    self.material = try self.allocator.create(graphics.Material);
    self.material.* = graphics.Material{
        .materialName = materialName,
        .pipeline = (try pipelineBuilder.build(gc.renderPass)).?,
        .layout = pipelineBuilder.pipelineLayout,
    };

    try gc.add_material(self.material);
}

pub fn setSkybox(textureName: []const u8) !void {
    const name = core.MakeName(textureName);
    gSkybox.cubeMapName = name;
}

pub fn destroy(self: *@This()) void {
    self.allocator.destroy(self);
}

const vk_renderer_interface = @import("vk_renderer/vk_renderer_interface.zig");
const RendererInterface = vk_renderer_interface.RendererInterface;

const std = @import("std");

const graphics = @import("graphics.zig");
const core = @import("core");
const vk = @import("vulkan");
const skybox_vert = @import("skybox_vert");
const skybox_frag = @import("skybox_frag");

const vkinit = @import("vk_init.zig");
