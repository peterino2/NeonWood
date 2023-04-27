const std = @import("std");
const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const gpd = graphics.gpu_pipe_data;
const papyrus = @import("papyrus/papyrus.zig");
const papyrusRes = @import("papyrusRes");
const vk = @import("vulkan");
const tracy = core.tracy;

gc: *graphics.NeonVkContext,
allocator: std.mem.Allocator,
pipeData: gpd.GpuPipeData = undefined,
materialName: core.Name = core.MakeName("mat_papyrus"),
material: *graphics.Material = undefined,
mappedBuffers: []gpd.GpuMappingData(PapyrusImageGpu) = undefined,
indexBuffer: graphics.IndexBuffer = undefined,

papyrusCtx: *papyrus.PapyrusContext,
quad: *graphics.Mesh,

graphLog: core.FileLog,

ssboCount: u32 = 1,

pub const NeonObjectTable = core.RttiData.from(@This());
pub const RendererInterfaceVTable = graphics.RendererInterface.from(@This());

pub const PapyrusImageGpu = struct {
    topLeft: core.Vector2f,
    size: core.Vector2f,
    anchorPoint: core.Vector2f = .{ .x = -1.0, .y = -1.0 },
    scale: core.Vector2f = .{ .x = 1.0, .y = 1.0 },
    alpha: f32 = 1.0,
    //zLevel: f32 = 0.5,
    pad: [12]u8 = std.mem.zeroes([12]u8),
};

pub fn init(allocator: std.mem.Allocator) @This() {
    var papyrusCtx = papyrus.initialize(allocator) catch unreachable;
    return .{
        .allocator = allocator,
        .gc = undefined,
        .papyrusCtx = papyrusCtx,
        .quad = allocator.create(graphics.Mesh) catch unreachable,
        .graphLog = core.FileLog.init(allocator, "papyrus_callgraph.viz") catch unreachable,
    };
}

pub fn setup(self: *@This(), gc: *graphics.NeonVkContext) !void {
    core.ui_log("Papyrus Subsystem setup {x}", .{@ptrToInt(self)});
    try self.graphLog.write("digraph G {{\n", .{});

    self.gc = gc;
    try self.preparePipeline();
    try self.setupMeshes();

    var ctx = self.papyrusCtx;

    {
        const ModernStyle = papyrus.ModernStyle;
        var panel = try ctx.addPanel(0);
        ctx.getPanel(panel).hasTitle = true;
        ctx.getPanel(panel).titleColor = ModernStyle.GreyDark;
        ctx.get(panel).style.backgroundColor = ModernStyle.Grey;
        ctx.get(panel).style.foregroundColor = ModernStyle.BrightGrey;
        ctx.get(panel).style.borderColor = ModernStyle.Yellow;
        ctx.get(panel).pos = .{ .x = 1920 / 4 - 300, .y = 1080 / 4 };
        ctx.get(panel).size = .{ .x = 1920 / 2, .y = 1080 / 2 };
    }

    try self.graphLog.write("}}\n", .{});
    try self.graphLog.makeGraphViz();

    try self.gc.registerRendererPlugin(self);

    self.mappedBuffers = try self.pipeData.mapBuffers(self.gc, PapyrusImageGpu, 0);
    core.ui_log("Mapping buffers.", .{});
}

pub fn preDraw(self: *@This(), frameId: usize) void {
    _ = self;
    _ = frameId;
}

// todo: this thing should be optional
pub fn onBindObject(self: *@This(), objectHandle: core.ObjectHandle, objectIndex: usize, cmd: vk.CommandBuffer, frameIndex: usize) void {
    _ = self;
    _ = objectHandle;
    _ = objectIndex;
    _ = cmd;
    _ = frameIndex;
}

// Uploads a new primitive mesh and an index buffer to the gpu.
fn setupMeshes(self: *@This()) !void {
    try self.graphLog.write("  root->setup_meshes\n", .{});

    self.quad.* = graphics.Mesh.init(self.gc, self.allocator);
    try self.quad.vertices.resize(4);

    var indexBuffer: [6]u32 = undefined;

    self.quad.vertices.items[0].position = .{ .x = 0.5, .y = 0.5, .z = 0 };
    self.quad.vertices.items[1].position = .{ .x = 0.5, .y = -0.5, .z = 0 };
    self.quad.vertices.items[2].position = .{ .x = -0.5, .y = -0.5, .z = 0 };
    self.quad.vertices.items[3].position = .{ .x = -0.5, .y = 0.5, .z = 0 };

    indexBuffer[0] = 0;
    indexBuffer[1] = 1;
    indexBuffer[2] = 2;

    indexBuffer[3] = 2;
    indexBuffer[4] = 3;
    indexBuffer[5] = 0;

    self.indexBuffer = try graphics.IndexBuffer.uploadIndexBuffer(self.gc, &indexBuffer, self.allocator);

    try self.quad.upload(self.gc);
}

pub fn tick(self: *@This(), deltaTime: f64) void {
    _ = self;
    _ = deltaTime;
}

pub fn uiTick(self: *@This(), deltaTime: f64) void {
    _ = self;
    _ = deltaTime;
}

pub fn preparePipeline(self: *@This()) !void {
    try self.graphLog.write("  setup->preparePipeline\n", .{});
    core.ui_log("pipeline prepare", .{});

    var spriteDataBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
    try spriteDataBuilder.addBufferBinding(
        PapyrusImageGpu,
        .storage_buffer,
        .{ .vertex_bit = true, .fragment_bit = true },
        .storageBuffer,
    );
    self.pipeData = try spriteDataBuilder.build();
    defer spriteDataBuilder.deinit();

    var builder = try graphics.NeonVkPipelineBuilder.init(
        self.gc.dev,
        self.gc.vkd,
        self.gc.allocator,
        papyrusRes.papyrus_vert.len,
        @ptrCast([*]const u32, &papyrusRes.papyrus_vert),
        papyrusRes.papyrus_frag.len,
        @ptrCast([*]const u32, &papyrusRes.papyrus_frag),
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

pub fn pushSsbo(self: *@This(), ssbo: PapyrusImageGpu, frameId: usize) !void {
    var gpuObjects = self.mappedBuffers[frameId].objects;
    gpuObjects[self.ssboCount] = ssbo;
    self.ssboCount += 1;
}

pub fn uploadSSBOData(self: *@This(), frameId: usize) !void {
    var z = tracy.ZoneN(@src(), "Uploading SSBOs");
    defer z.End();

    var gpuObjects = self.mappedBuffers[frameId].objects;

    var drawList = try self.papyrusCtx.makeDrawList();
    defer drawList.deinit();

    self.ssboCount = 0;

    for (drawList) |drawCmd| {
        var tl = core.Vector2f{ .x = -0.5, .y = -0.5 };
        var size = core.Vector2f{ .x = 0.5, .y = 0.5 };
        gpuObjects[self.ssboCount] = PapyrusImageGpu{
            .topLeft = tl,
            .size = size,
        };
        self.ssboCount += 1;
    }
}

pub fn postDraw(self: *@This(), cmd: vk.CommandBuffer, frameIndex: usize, frameTime: f64) void {
    var z = tracy.ZoneN(@src(), "Papyrus post draw");
    defer z.End();

    self.uploadSSBOData(frameIndex) catch unreachable;

    {
        var size: u64 = 0;

        // bind
        self.gc.vkd.cmdBindPipeline(cmd, .graphics, self.material.pipeline);
        self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 0, 1, self.pipeData.getDescriptorSet(frameIndex), 0, undefined);
        self.gc.vkd.cmdBindVertexBuffers(cmd, 0, 1, core.p_to_a(&self.quad.buffer.buffer), core.p_to_a(&size));
        self.gc.vkd.cmdBindIndexBuffer(cmd, self.indexBuffer.buffer.buffer, 0, .uint32);

        self.gc.vkd.cmdDrawIndexed(cmd, @intCast(u32, self.indexBuffer.indices.len), 1, 0, 0, 0);
    }

    // 1. get the draw list
    _ = frameTime;
}

pub fn deinit(self: *@This()) void {
    for (self.mappedBuffers) |*mapped| {
        mapped.unmap(self.gc);
    }
    self.papyrusCtx.deinit();
}

pub fn processEvents(self: *@This(), frameNumber: u64) core.RttiDataEventError!void {
    _ = frameNumber;
    _ = self;
}
