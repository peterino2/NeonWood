const std = @import("std");
const core = @import("../core.zig");
const assets = @import("../assets.zig");
const graphics = @import("../graphics.zig");
const gpd = graphics.gpu_pipe_data;
const papyrus = @import("papyrus/papyrus.zig");
const papyrus_vk_vert = @import("papyrus_vk_vert");
const papyrus_vk_frag = @import("papyrus_vk_frag");
const FontSDF_vert = @import("FontSDF_vert");
const FontSDF_frag = @import("FontSDF_frag");
const gl = @import("glslTypes");
const vk = @import("vulkan");
const tracy = core.tracy;

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

ssboCount: u32 = 1,

time: f32 = 0,

textMesh: *graphics.DynamicMesh,
textPipeData: gpd.GpuPipeData = undefined,

displayDemo: bool = true,

const testString = "hello world";

const DrawListEntryInfo = struct {
    entryType: enum {
        image,
        text, // text is an sdf text utilizing a dynamic mesh.
    },
};

pub const NeonObjectTable = core.RttiData.from(@This());
pub const RendererInterfaceVTable = graphics.RendererInterface.from(@This());

pub const PapyrusPushConstant = struct {
    extent: core.Vector2f,
};

pub const PapyrusImageGpu = papyrus_vk_vert.ImageRenderData;

pub fn init(allocator: std.mem.Allocator) @This() {
    var papyrusCtx = papyrus.initialize(allocator) catch unreachable;
    return .{
        .allocator = allocator,
        .gc = graphics.getContext(),
        .papyrusCtx = papyrusCtx,
        .quad = allocator.create(graphics.Mesh) catch unreachable,
        .graphLog = core.FileLog.init(allocator, "papyrus_callgraph.viz") catch unreachable,
        .textMesh = undefined,
        .fontAtlas = papyrus.FontAtlas.initFromFileSDF(allocator, "fonts/ShareTechMono-Regular.ttf", 50) catch unreachable,
    };
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
}

fn setupDynamicMesh(self: *@This()) !void {
    self.textMesh.addQuad2D(
        .{ .x = 0.3, .y = 0.3, .z = 0 },
        .{ .x = 0.1, .y = 0.1, .z = 0 },
        .{ .x = 0.0, .y = 0.0 },
        .{ .x = 1.0, .y = 1.0 },
    );
}

pub fn setup(self: *@This(), gc: *graphics.NeonVkContext) !void {
    core.ui_log("Papyrus Subsystem setup {x}", .{@ptrToInt(self)});
    try self.graphLog.write("digraph G {{\n", .{});

    self.gc = gc;
    self.textMesh = try graphics.DynamicMesh.init(gc, gc.allocator, .{
        .maxVertexCount = 4096 * 4,
    });
    try self.preparePipeline();
    try self.prepareFont();
    try self.setupMeshes();
    try self.setupDynamicMesh();

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
    self.time += @floatCast(f32, deltaTime);
    self.time = @mod(self.time, 10.0);
}

pub fn uiTick(self: *@This(), deltaTime: f64) void {
    _ = self;
    _ = deltaTime;
}

pub fn buildTextPipeline(self: *@This()) !void {
    core.ui_log("building text pipeline", .{});
    try self.graphLog.write(" setup->buildTextPipeline", .{});
    var gpdBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
    try gpdBuilder.addBufferBinding(
        FontSDF_vert.FontInfo,
        .storage_buffer,
        .{ .vertex_bit = true, .fragment_bit = true },
        .storageBuffer,
    );

    self.textPipeData = try gpdBuilder.build("Papyrus-Text");
    defer gpdBuilder.deinit();

    var builder = try graphics.NeonVkPipelineBuilder.init(
        self.gc.dev,
        self.gc.vkd,
        self.gc.allocator,
        FontSDF_vert.spirv.len,
        @ptrCast([*]const u32, @alignCast(4, FontSDF_vert.spirv)),
        FontSDF_frag.spirv.len,
        @ptrCast([*]const u32, @alignCast(4, FontSDF_frag.spirv)),
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

    var builder = try graphics.NeonVkPipelineBuilder.init(
        self.gc.dev,
        self.gc.vkd,
        self.gc.allocator,
        papyrus_vk_vert.spirv.len,
        @ptrCast([*]const u32, @alignCast(4, papyrus_vk_vert.spirv)),
        papyrus_vk_frag.spirv.len,
        @ptrCast([*]const u32, @alignCast(4, papyrus_vk_frag.spirv)),
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
    // try self.buildTextPipeline();
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

    var baseColor: gl.vec4 = .{ .x = 0.0, .y = std.math.sin(self.time), .z = 1.0, .w = 1.0 };

    var drawList = try self.papyrusCtx.makeDrawList();
    defer drawList.deinit();

    self.ssboCount = 0;

    imagesGpu[self.ssboCount] = PapyrusImageGpu{
        .imagePosition = .{ .x = 0, .y = 400 },
        .imageSize = .{ .x = 200, .y = 200 },
        .scale = .{ .x = 1.0, .y = 1.0 },
        .anchorPoint = .{ .x = -1.0, .y = -1.0 },
        .alpha = 1.0,
        .pad0 = std.mem.zeroes([12]u8),
        .baseColor = baseColor,
    };
    self.ssboCount += 1;

    for (drawList.items) |drawCmd| {
        _ = drawCmd;
    }

    imagesGpu[self.ssboCount] = PapyrusImageGpu{
        .imagePosition = .{ .x = 400, .y = 400 },
        .imageSize = .{ .x = 200, .y = 200 },
        .anchorPoint = .{ .x = -1.0, .y = -1.0 },
        .scale = .{ .x = 1.0, .y = 1.0 },
        .alpha = 1.0,
        .pad0 = std.mem.zeroes([12]u8),
        .baseColor = .{ .x = 1.0, .y = 1.0, .z = 0.0, .w = 1.0 },
    };
    self.ssboCount += 1;

    imagesGpu[self.ssboCount] = PapyrusImageGpu{
        .imagePosition = .{ .x = 600, .y = 200 },
        .imageSize = .{ .x = 200, .y = 200 },
        .anchorPoint = .{ .x = -1.0, .y = -1.0 },
        .scale = .{ .x = 1.0, .y = 1.0 },
        .alpha = 1.0,
        .pad0 = std.mem.zeroes([12]u8),
        .baseColor = .{ .x = 1.0, .y = 0.0, .z = 0.0, .w = 1.0 },
    };
    self.ssboCount += 1;

    imagesGpu[self.ssboCount] = PapyrusImageGpu{
        .imagePosition = .{ .x = 800, .y = 400 },
        .imageSize = .{ .x = 50, .y = 50 },
        .anchorPoint = .{ .x = -1.0, .y = -1.0 },
        .scale = .{ .x = 1.0, .y = 1.0 },
        .alpha = 1.0,
        .pad0 = std.mem.zeroes([12]u8),
        .baseColor = .{ .x = 1.0, .y = 0.0, .z = 1.0, .w = 1.0 },
    };
    self.ssboCount += 1;
}

pub fn postDraw(self: *@This(), cmd: vk.CommandBuffer, frameIndex: usize, frameTime: f64) void {
    var z = tracy.ZoneN(@src(), "Papyrus post draw");
    defer z.End();

    if (!self.displayDemo) {
        return;
    }

    self.uploadSSBOData(frameIndex) catch unreachable;

    {
        var size: u64 = 0;

        var constants = PapyrusPushConstant{
            .extent = .{
                .x = @intToFloat(f32, self.gc.extent.width),
                .y = @intToFloat(f32, self.gc.extent.height),
            },
        };

        self.gc.vkd.cmdPushConstants(cmd, self.material.layout, .{ .vertex_bit = true, .fragment_bit = true }, 0, @sizeOf(PapyrusPushConstant), &constants);
        self.gc.vkd.cmdBindPipeline(cmd, .graphics, self.material.pipeline);
        self.gc.vkd.cmdBindVertexBuffers(cmd, 0, 1, core.p_to_a(&self.quad.buffer.buffer), core.p_to_a(&size));
        self.gc.vkd.cmdBindIndexBuffer(cmd, self.indexBuffer.buffer.buffer, 0, .uint32);

        var index: u32 = 0;
        while (index < self.ssboCount) : (index += 1) {
            self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 0, 1, self.pipeData.getDescriptorSet(frameIndex), 0, undefined);
            self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 1, 1, core.p_to_a(self.fontTextureDescriptor), 0, undefined);
            self.gc.vkd.cmdDrawIndexed(cmd, @intCast(u32, self.indexBuffer.indices.len), 1, 0, 0, index);
        }
    }

    // 1. get the draw list
    _ = frameTime;
}

pub fn deinit(self: *@This()) void {
    core.ui_logs("Shutting down UI");
    for (self.mappedBuffers) |*mapped| {
        mapped.unmap(self.gc);
    }
    self.quad.deinit(self.gc);

    self.pipeData.deinit(self.allocator, self.gc);
    self.textPipeData.deinit(self.allocator, self.gc);
    self.textMesh.deinit();

    self.indexBuffer.deinit(self.gc);
    self.allocator.destroy(self.textMesh);

    self.papyrusCtx.deinit();
}

pub fn processEvents(self: *@This(), frameNumber: u64) core.RttiDataEventError!void {
    _ = frameNumber;
    _ = self;
}
