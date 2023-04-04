const std = @import("std");
const vk = @import("vk");
const graphics = @import("../../graphics.zig");
const core = @import("../../core.zig");
const NeonVkContext = graphics.NeonVkContext;
const gpd = graphics.gpu_pipe_data;

const papyrusRes = @import("papyrusRes");

// vulkan based reference renderer
// this is just a sample integration
// device and cmd and vulkan bindings are assumed to be using the
// a 'vk' namespace.

// converts the emitted draw commands from the papyrus system into
// rendering draws for a vulkan instance

gc: *NeonVkContext,
allocator: std.mem.Allocator,
pipeData: gpd.GpuPipeData = undefined,
mappedBuffers: []gpd.GpuMappingData(PapyrusImageGpu) = undefined,
materialName: core.Name = core.MakeName("mat_papyrus"),
material: *graphics.Material = undefined,

pub const PapyrusImageGpu = struct {
    topLeft: core.Vector2f,
    size: core.Vector2f,
    anchorPoint: core.Vector2f = .{ .x = -1.0, .y = -1.0 },
    scale: core.Vector2f = .{ .x = 0, .y = 0 },
    alpha: f32 = 1.0,
    //zLevel: f32 = 0.5,
    pad: [12]u8 = std.mem.zeroes([12]u8),
};

pub fn init(gc: *NeonVkContext, allocator: std.mem.Allocator) !@This() {
    core.ui_log("UI subsystem initialized", .{});
    var self = @This(){
        .gc = gc,
        .allocator = allocator,
    };
    try self.preparePipeline();
    return self;
}

// TODO, papyrus should not use the pipeline builder from neonwood and isntead
// create it's own version of vulkan utilities
pub fn preparePipeline(self: *@This()) !void {
    var spriteDataBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
    try spriteDataBuilder.addBufferBinding(
        PapyrusImageGpu,
        .storage_buffer,
        .{ .vertex_bit = true, .fragment_bit = true },
        .storageBuffer,
    );
    self.pipeData = try spriteDataBuilder.build();
    defer spriteDataBuilder.deinit();

    var builder = try graphics.NeonVkPipelineBuilder.initFromContext(
        self.gc,
        papyrusRes.papyrus_vert,
        papyrusRes.papyrus_frag,
    );
    defer builder.deinit();

    try builder.add_mesh_description();
    try builder.add_layout(self.pipeData.descriptorSetLayout);
    try builder.add_layout(self.gc.singleTextureSetLayout);
    try builder.add_depth_stencil();
    try builder.init_triangle_pipeline(self.gc.actual_extent);

    var material = try self.gc.allocator.create(graphics.Material);

    material.* = graphics.Material{
        .materialName = self.materialName,
        .pipeline = (try builder.build(self.gc.renderPass)).?,
        .layout = builder.pipelineLayout,
    };

    try self.gc.add_material(material);

    self.material = material;
}

pub fn deinit(self: *@This()) void {
    _ = self;
}
