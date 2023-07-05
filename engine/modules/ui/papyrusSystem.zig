const std = @import("std");
const core = @import("../core.zig");
const assets = @import("../assets.zig");
const graphics = @import("../graphics.zig");
const gpd = graphics.gpu_pipe_data;
pub const papyrus = @import("papyrus/papyrus.zig");

const papyrus_vk_vert = @import("papyrus_vk_vert");
const papyrus_vk_frag = @import("papyrus_vk_frag");
const FontSDF_vert = @import("FontSDF_vert");
const FontSDF_frag = @import("FontSDF_frag");
const gl = @import("glslTypes");
const vk = @import("vulkan");
const tracy = core.tracy;

const Text = papyrus.Text;
const DrawCommand = @import("drawCommand.zig").DrawCommand;
const text_render = @import("text_render.zig");

const TextRenderer = text_render.TextRenderer;
const DisplayText = text_render.DisplayText;
const FontAtlasVk = text_render.FontAtlasVk;

gc: *graphics.NeonVkContext,
allocator: std.mem.Allocator,
pipeData: gpd.GpuPipeData = undefined,
materialName: core.Name = core.MakeName("mat_papyrus"),
material: *graphics.Material = undefined,
textMaterial: *graphics.Material = undefined,
mappedBuffers: []gpd.GpuMappingData(PapyrusImageGpu) = undefined,
indexBuffer: graphics.IndexBuffer = undefined,

fontTexture: *graphics.Texture = undefined,
fontTextureDescriptor: *vk.DescriptorSet = undefined,

papyrusCtx: *papyrus.PapyrusContext,
quad: *graphics.Mesh,

graphLog: core.FileLog,
fontAtlas: papyrus.FontAtlas = undefined,

textCount: u32 = 0,
ssboCount: u32 = 1,
time: f64 = 0,

textPipeData: gpd.GpuPipeData = undefined,

displayDemo: bool = true,

drawCommands: std.ArrayList(DrawCommand),

textRenderer: *TextRenderer,

const testString = "hello world";

pub const NeonObjectTable = core.RttiData.from(@This());
pub const RendererInterfaceVTable = graphics.RendererInterface.from(@This());

pub const PapyrusPushConstant = struct {
    extent: core.Vector2f,
};

pub const PapyrusImageGpu = papyrus_vk_vert.ImageRenderData;

pub fn init(allocator: std.mem.Allocator) !*@This() {
    var papyrusCtx = try papyrus.initialize(allocator);
    var self = try allocator.create(@This());
    self.* = .{
        .allocator = allocator,
        .gc = graphics.getContext(),
        .papyrusCtx = papyrusCtx,
        .quad = try allocator.create(graphics.Mesh),
        .graphLog = try core.FileLog.init(allocator, "papyrus_callgraph.viz"),
        .fontAtlas = try papyrus.FontAtlas.initFromFileSDF(allocator, "fonts/Roboto-Regular.ttf", 64),
        .drawCommands = std.ArrayList(DrawCommand).init(allocator),
        .textRenderer = try TextRenderer.init(allocator, graphics.getContext(), papyrusCtx),
    };
    return self;
}

pub fn prepareFont(self: *@This()) !void {
    // load with default font size as an SDF
    var pixels = try self.fontAtlas.makeBitmapRGBA(self.allocator);
    defer self.allocator.free(pixels);
    var res = try graphics.createTextureFromPixelsSync(
        core.MakeName("_t_papyrusFont"),
        pixels,
        .{ .x = self.fontAtlas.atlasSize.x, .y = self.fontAtlas.atlasSize.y },
        self.gc,
        false,
    );

    self.fontTexture = res.texture;
    self.fontTextureDescriptor = res.descriptor;

    _ = try self.textRenderer.addFont("fonts/Roboto-Regular.ttf", core.MakeName("roboto"));

    // using the v2 stuff
    for (0..32) |i| {
        _ = i;
        var newText = try self.textRenderer.addDisplayText(core.MakeName("roboto"), .{});
        _ = newText;
    }
}

pub fn setup(self: *@This(), gc: *graphics.NeonVkContext) !void {
    core.ui_log("Papyrus Subsystem setup {x}", .{@intFromPtr(self)});
    try self.graphLog.write("digraph G {{\n", .{});

    self.gc = gc;
    try self.preparePipeline();
    try self.prepareFont();
    try self.setupMeshes();

    try self.graphLog.write("}}\n", .{});
    // try self.graphLog.makeGraphViz();

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

    self.quad.vertices.items[0].position = .{ .x = 1, .y = 1, .z = 0 }; // bot right
    self.quad.vertices.items[1].position = .{ .x = 1, .y = -1, .z = 0 }; // top right
    self.quad.vertices.items[2].position = .{ .x = -1, .y = -1, .z = 0 }; // top left
    self.quad.vertices.items[3].position = .{ .x = -1, .y = 1, .z = 0 }; // bot left

    self.quad.vertices.items[0].uv = .{ .x = 1.0, .y = 1.0 };
    self.quad.vertices.items[1].uv = .{ .x = 1.0, .y = 0.0 };
    self.quad.vertices.items[2].uv = .{ .x = 0.0, .y = 0.0 };
    self.quad.vertices.items[3].uv = .{ .x = 0.0, .y = 1.0 };

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
    self.time += deltaTime;
}

pub fn uiTick(self: *@This(), deltaTime: f64) void {
    _ = self;
    _ = deltaTime;
}

pub fn buildTextPipeline(self: *@This()) !void {
    core.ui_log("building text pipeline", .{});
    try self.graphLog.write(" setup->buildTextPipeline", .{});
    var gpdBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
    gpdBuilder.objectCount = 64;
    try gpdBuilder.addBufferBinding(
        FontSDF_vert.FontInfo,
        .storage_buffer,
        .{ .vertex_bit = true, .fragment_bit = true },
        .storageBuffer,
    );

    self.textPipeData = try gpdBuilder.build("Papyrus-Text");
    defer gpdBuilder.deinit();

    var vert_spv = try graphics.loadSpv(self.allocator, "zig-out/shaders/FontSDF_vert.spv");
    defer self.allocator.free(vert_spv);
    var frag_spv = try graphics.loadSpv(self.allocator, "zig-out/shaders/FontSDF_frag.spv");
    defer self.allocator.free(frag_spv);

    var builder = try graphics.NeonVkPipelineBuilder.init(
        self.gc.dev,
        self.gc.vkd,
        self.gc.allocator,
        vert_spv,
        frag_spv,
    );
    defer builder.deinit();

    try builder.add_mesh_description();
    try builder.add_layout(self.textPipeData.descriptorSetLayout);
    try builder.add_layout(self.gc.singleTextureSetLayout);
    try builder.add_depth_stencil();
    try builder.add_push_constant_custom(PapyrusPushConstant);
    try builder.init_triangle_pipeline(self.gc.actual_extent);

    self.textMaterial = try self.allocator.create(graphics.Material);
    self.textMaterial.* = graphics.Material{
        .materialName = self.materialName,
        .pipeline = (try builder.build(self.gc.renderPass)).?,
        .layout = builder.pipelineLayout,
    };

    try self.gc.add_material(self.textMaterial);
}

pub fn buildImagePipeline(self: *@This()) !void {
    core.ui_log("buildingImagePipeline", .{});
    try self.graphLog.write("  setup->preparePipeline\n", .{});

    var spriteDataBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
    try spriteDataBuilder.addBufferBinding(
        PapyrusImageGpu,
        .storage_buffer,
        .{ .vertex_bit = true, .fragment_bit = true },
        .storageBuffer,
    );
    self.pipeData = try spriteDataBuilder.build("Papyrus");
    defer spriteDataBuilder.deinit();

    var vert_spv = try graphics.loadSpv(self.allocator, "zig-out/shaders/papyrus_vk_vert.spv");
    defer self.allocator.free(vert_spv);

    var frag_spv = try graphics.loadSpv(self.allocator, "zig-out/shaders/papyrus_vk_frag.spv");
    defer self.allocator.free(frag_spv);

    var builder = try graphics.NeonVkPipelineBuilder.init(
        self.gc.dev,
        self.gc.vkd,
        self.gc.allocator,
        vert_spv,
        frag_spv,
    );

    defer builder.deinit();

    try builder.add_mesh_description();
    try builder.add_layout(self.pipeData.descriptorSetLayout);
    try builder.add_layout(self.gc.singleTextureSetLayout);
    try builder.add_depth_stencil();
    try builder.add_push_constant_custom(PapyrusPushConstant);
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

pub fn preparePipeline(self: *@This()) !void {
    try self.buildTextPipeline();
    try self.buildImagePipeline();
}

pub fn pushSsbo(self: *@This(), ssbo: PapyrusImageGpu, frameId: usize) !void {
    var imagesGpu = self.mappedBuffers[frameId].objects;
    imagesGpu[self.ssboCount] = ssbo;
    self.ssboCount += 1;
}

pub fn uploadSSBOData(self: *@This(), frameId: usize) !void {
    var z = tracy.ZoneN(@src(), "Uploading SSBOs");
    defer z.End();

    var imagesGpu = self.mappedBuffers[frameId].objects;

    var drawList = try self.papyrusCtx.makeDrawList();
    self.drawCommands.clearRetainingCapacity();
    defer drawList.deinit();

    self.ssboCount = 0;
    self.textCount = 0;

    for (drawList.items) |drawCmd| {
        switch (drawCmd.primitive) {
            .Rect => |rect| {
                //
                imagesGpu[self.ssboCount] = PapyrusImageGpu{
                    .imagePosition = .{ .x = rect.tl.x, .y = rect.tl.y },
                    .imageSize = .{ .x = rect.size.x, .y = rect.size.y },
                    .anchorPoint = .{ .x = -1.0, .y = -1.0 },
                    .scale = .{ .x = 1.0, .y = 1.0 },
                    .alpha = 1.0,
                    .pad0 = std.mem.zeroes([8]u8),
                    .baseColor = .{
                        .x = rect.backgroundColor.r,
                        .y = rect.backgroundColor.g,
                        .z = rect.backgroundColor.b,
                        .w = rect.backgroundColor.a,
                    },
                    .rounding = .{
                        .x = rect.rounding.tl,
                        .y = rect.rounding.tr,
                        .z = rect.rounding.bl,
                        .w = rect.rounding.br,
                    },
                    .borderColor = .{
                        .x = rect.borderColor.r,
                        .y = rect.borderColor.g,
                        .z = rect.borderColor.b,
                        .w = rect.borderColor.a,
                    },
                    .borderWidth = 1.0,
                };
                try self.drawCommands.append(.{ .image = self.ssboCount });
                self.ssboCount += 1;
            },
            .Text => |text| {
                var textDisplay = self.textRenderer.displays.items[self.textCount];
                textDisplay.displaySize = text.textSize;
                textDisplay.boxSize = .{ .x = text.size.x, .y = text.size.y };
                textDisplay.color = text.color;
                textDisplay.position = .{ .x = text.tl.x, .y = text.tl.y };
                textDisplay.string.clearRetainingCapacity();
                try textDisplay.string.appendSlice(text.text.utf8);

                try self.drawCommands.append(.{ .text = self.textCount });
                self.textCount += 1;
            },
        }
    }

    for (0..self.textCount) |i| {
        var displayText = self.textRenderer.displays.items[i];
        try displayText.updateMesh();
    }
}

pub fn postDraw(self: *@This(), cmd: vk.CommandBuffer, frameIndex: usize, frameTime: f64) void {
    _ = frameTime;

    var z = tracy.ZoneN(@src(), "Papyrus post draw");
    defer z.End();
    var vertexBufferOffset: u64 = 0;

    if (!self.displayDemo) {
        return;
    }

    self.uploadSSBOData(frameIndex) catch unreachable;

    var constants = PapyrusPushConstant{
        .extent = .{
            .x = @as(f32, @floatFromInt(self.gc.extent.width)),
            .y = @as(f32, @floatFromInt(self.gc.extent.height)),
        },
    };
    self.gc.vkd.cmdPushConstants(cmd, self.material.layout, .{ .vertex_bit = true, .fragment_bit = true }, 0, @sizeOf(PapyrusPushConstant), &constants);

    {
        self.gc.vkd.cmdBindPipeline(cmd, .graphics, self.material.pipeline);
        self.gc.vkd.cmdBindVertexBuffers(cmd, 0, 1, core.p_to_a(&self.quad.buffer.buffer), core.p_to_a(&vertexBufferOffset));
        self.gc.vkd.cmdBindIndexBuffer(cmd, self.indexBuffer.buffer.buffer, 0, .uint32);

        var index: u32 = 0;
        while (index < self.ssboCount) : (index += 1) {
            self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 0, 1, self.pipeData.getDescriptorSet(frameIndex), 0, undefined);
            self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 1, 1, core.p_to_a(self.fontTextureDescriptor), 0, undefined);
            self.gc.vkd.cmdDrawIndexed(cmd, @as(u32, @intCast(self.indexBuffer.indices.len)), 1, 0, 0, index);
        }
    }

    // draw text
    for (0..self.textCount) |i| {
        var drawText = self.textRenderer.displays.items[i];
        drawText.draw(cmd, self.textMaterial);
    }
}

pub fn deinit(self: *@This()) void {
    core.ui_logs("Shutting down UI");
    for (self.mappedBuffers) |*mapped| {
        mapped.unmap(self.gc);
    }
    self.quad.deinit(self.gc);

    self.textRenderer.deinit(self.allocator);

    self.pipeData.deinit(self.allocator, self.gc);
    self.textPipeData.deinit(self.allocator, self.gc);

    self.indexBuffer.deinit(self.gc);

    self.papyrusCtx.deinit();
}

pub fn processEvents(self: *@This(), frameNumber: u64) core.RttiDataEventError!void {
    _ = frameNumber;
    _ = self;
}
