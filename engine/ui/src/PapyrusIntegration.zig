gc: *graphics.NeonVkContext,
allocator: std.mem.Allocator,
pipeData: gpd.GpuPipeData = undefined,
materialName: core.Name = core.MakeName("mat_papyrus"),
materialNameText: core.Name = core.MakeName("mat_papyrus_text"),
material: *graphics.Material = undefined, // main material used for anything that isn't text
defaultTextureSet: vk.DescriptorSet,
textMaterial: *graphics.Material = undefined, // main material used for text
mappedBuffers: []gpd.GpuMappingData(ImageGpu) = undefined,
textImageBuffers: []gpd.GpuMappingData(FontInfo) = undefined,
indexBuffer: graphics.IndexBuffer = undefined,

drawList: papyrus.DrawList,
stringArena: std.heap.ArenaAllocator,
fontTexture: *graphics.Texture = undefined,

papyrusCtx: *papyrus.Context,
quad: *graphics.Mesh,

ssboCount: u32 = 0,
textSsboCount: u32 = 0,
time: f64 = 0,

textPipeData: gpd.GpuPipeData = undefined,
displayDemo: bool = true,
drawCommands: std.ArrayList(VkCommand),
textRenderer: *TextRenderer,
averageFrameTime: f64 = 0,
onDebugInfoBinding: usize = 0,

sharedData: [graphics.NumFrames]SharedData = undefined,

const std = @import("std");
const core = @import("core");
const memory = core.MemoryTracker;

const assets = @import("assets");
const graphics = @import("graphics");
const gpd = graphics.gpu_pipe_data;
const RenderThread = graphics.RenderThread;

const platform = @import("platform");
const papyrus = @import("papyrus");

const papyrus_vk_vert = @import("papyrus_vk_vert");
const papyrus_vk_frag = @import("papyrus_vk_frag");
const FontSDF_vert = @import("FontSDF_vert");
const FontSDF_frag = @import("FontSDF_frag");
const gl = @import("glslTypes");
const vk = @import("vulkan");
const tracy = core.tracy;

const Text = papyrus.Text;
const VkCommand = @import("VkPapyrusRenderCommand.zig").VkCommand;
const text_render = @import("text_render.zig");

const TextRenderer = text_render.TextRenderer;
const DisplayText = text_render.DisplayText;
const FontAtlasVk = text_render.FontAtlasVk;
const Key = papyrus.Event.Key;

const use_renderthread = core.BuildOption("use_renderthread");

pub const RawInputListenerVTable = platform.windowing.RawInputListenerInterface.from(@This());

pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());
pub const RendererInterfaceVTable = graphics.RendererInterface.from(@This());

pub const PushConstant = FontSDF_vert.constants;

pub const ImageGpu = papyrus_vk_vert.ImageRenderData;
pub const FontInfo = FontSDF_vert.FontInfo;

pub fn init(allocator: std.mem.Allocator) !*@This() {
    const papyrusCtx = try papyrus.initialize(allocator);
    const self = try allocator.create(@This());
    self.* = .{
        .allocator = allocator,
        .gc = graphics.getContext(),
        .papyrusCtx = papyrusCtx,
        .quad = try allocator.create(graphics.Mesh),
        .drawCommands = std.ArrayList(VkCommand).init(allocator),
        .textRenderer = try TextRenderer.init(allocator, graphics.getContext(), papyrusCtx),
        .drawList = papyrus.DrawList.init(allocator),
        .stringArena = std.heap.ArenaAllocator.init(allocator),
        .defaultTextureSet = undefined,
    };

    if (use_renderthread) {
        self.initShared();
    }

    self.onDebugInfoBinding = try core.addEngineDelegateBinding("onFrameDebugInfoEmitted", onFrameDebugInfo, self);
    // core.engine_logs("PapyrusSystem init");

    memory.MTPrintStatsDelta();

    try platform.getInstance().installListener(self);
    return self;
}

pub fn onFrameDebugInfo(ctx: *anyopaque, averageFrameTime: f64) core.EngineDataEventError!void {
    const self: *@This() = @ptrCast(@alignCast(ctx));
    self.averageFrameTime = averageFrameTime;
}

pub fn OnIoEvent(self: *@This(), event: platform.IOEvent) platform.InputListenerError!void {
    try OnIoEvent_GLFW(self, event);
}

pub fn OnIoEvent_GLFW(self: *@This(), event: platform.IOEvent) platform.InputListenerError!void {
    switch (event) {
        .mousePosition => |mousePosition| {
            _ = mousePosition;
        },
        .mouseButton => |mouseButton| {
            var keycode: Key = .Unknown;
            var eventType: papyrus.Event.PressedType = .onPressed;
            switch (mouseButton.button) {
                0 => {
                    // left click
                    keycode = Key.Mouse1;
                },
                1 => {
                    // right click
                    keycode = Key.Mouse2;
                },
                2 => {
                    // middle click
                    keycode = Key.Mouse3;
                },
                3 => {
                    // button 3
                    keycode = Key.Mouse4;
                },
                4 => {
                    // button 4
                    keycode = Key.Mouse5;
                },
                else => {},
            }

            switch (mouseButton.action) {
                0 => {
                    eventType = .onReleased;
                },
                1 => {
                    eventType = .onPressed;
                },
                else => {},
            }

            // todo: use the right error code here
            self.papyrusCtx.onKey(keycode, eventType) catch unreachable;
        },
        .windowResize => |e| {
            const pi = platform.getInstance();

            self.papyrusCtx.get(.{}).setSize(.{
                .x = e.newSize.x / pi.contentScale.x,
                .y = e.newSize.y / pi.contentScale.y,
            });
        },
        .codepoint => |codepoint| {
            try self.papyrusCtx.textEntry.sendCodePoint(@as(u32, codepoint));
        },
        .key => |keyEvent| {
            var te = self.papyrusCtx.textEntry;

            const actions = platform.glfw_defs.actions;
            const keys = platform.glfw_defs.keys;

            if (@as(actions, @enumFromInt(keyEvent.action)) == actions.Press or
                @as(actions, @enumFromInt(keyEvent.action)) == actions.Repeat)
            {

                // reference glfw3.h
                switch (@as(keys, @enumFromInt(keyEvent.key))) {
                    keys.Escape => {
                        try te.sendEscape();
                    },
                    keys.Enter => {
                        try te.sendEnter();
                    },
                    keys.Tab => {
                        try te.sendTab();
                    },
                    keys.Backspace => {
                        try te.sendBackspace();
                    },
                    keys.Delete => {
                        try te.sendDelete();
                    },
                    keys.Right => {
                        try te.sendRight();
                    },
                    keys.Left => {
                        try te.sendLeft();
                    },
                    keys.Up => {
                        try te.sendUp();
                    },
                    keys.Down => {
                        try te.sendDown();
                    },
                    keys.Pageup => {
                        try te.sendPageup();
                    },
                    keys.Pagedown => {
                        try te.sendPagedown();
                    },
                    keys.Home => {
                        try te.sendHome();
                    },
                    keys.End => {
                        try te.sendEnd();
                    },
                    else => {},
                }
            }
        },
        else => {},
    }
}

pub fn setup(self: *@This(), gc: *graphics.NeonVkContext) !void {
    core.ui_log("Papyrus Subsystem setup {x}", .{@intFromPtr(self)});

    self.gc = gc;
    try self.preparePipeline();
    try self.setupMeshes();

    try self.gc.registerRendererPlugin(self);
    self.defaultTextureSet = self.gc.textureSets.get(core.MakeName("t_white").handle()).?;

    self.mappedBuffers = try self.pipeData.mapBuffers(self.gc, ImageGpu, 0);
    self.textImageBuffers = try self.textPipeData.mapBuffers(self.gc, FontInfo, 0);
    // core.ui_log("Mapping buffers.", .{});
    const extent = self.gc.actual_extent;
    const pi = platform.getInstance();

    self.papyrusCtx.get(.{}).setSize(.{
        .x = @as(f32, @floatFromInt(extent.width)) / pi.contentScale.x,
        .y = @as(f32, @floatFromInt(extent.height)) / pi.contentScale.y,
    });
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

var lastEventCount: usize = 0;
var displayEventsPerSecond: f64 = 0;

pub fn tick(self: *@This(), deltaTime: f64) void {
    self.time += deltaTime;
    const cursor = platform.getInstance().inputState.mousePos;

    // TODO, use OnIoEvent, but ehh this is fine.
    self.papyrusCtx.setCursorLocation(.{
        .x = @floatCast(cursor.x),
        .y = @floatCast(cursor.y),
    });

    self.papyrusCtx.tick(deltaTime) catch unreachable;
    if (memory.MTGet()) |mt| {
        const eventsPerFrame = @as(f64, @floatFromInt(mt.eventsCount - lastEventCount));

        displayEventsPerSecond = (displayEventsPerSecond + eventsPerFrame / 60.0) - displayEventsPerSecond / 60.0;

        self.papyrusCtx.pushDebugText("memory used: {d:.3}MB {d} allocations ({d} events per frame)", .{
            @as(f32, @floatFromInt(mt.totalAllocSize)) / 1e6,
            mt.allocationsCount,
            eventsPerFrame,
        }) catch {};

        lastEventCount = mt.eventsCount;
    }

    if (self.gc.vulkanValidation) {
        self.papyrusCtx.pushDebugText("vulkan validation: ON", .{}) catch unreachable;
    }

    self.papyrusCtx.pushDebugText("ecs entities: {d}", .{core.getRegistry().baseSet.count()}) catch unreachable;

    self.papyrusCtx.pushDebugText("frameTime (ms): {d:.4} fps: {d:.3} engine uptime: {d:.3}", .{ self.averageFrameTime * 1000.0, 1.0 / self.averageFrameTime, core.getEngineUptime() }) catch unreachable;

    self.papyrusCtx.pushDebugText("  systems (ms): {d:.4}", .{
        core.getEngine().systemsThreadTime * 1000.0,
    }) catch unreachable;

    self.papyrusCtx.pushDebugText("  renderthread (ms): {d:.4}", .{core.getEngine().renderThreadTime * 1000.0}) catch unreachable;
}

pub fn buildTextPipeline(self: *@This()) !void {
    var gpdBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
    gpdBuilder.objectCount = 64;
    try gpdBuilder.addBufferBinding(
        FontInfo,
        .storage_buffer,
        .{ .vertex_bit = true, .fragment_bit = true },
        .storageBuffer,
    );

    self.textPipeData = try gpdBuilder.build("Papyrus-Text");
    defer gpdBuilder.deinit();

    // const vert_spv = try graphics.loadSpv(self.allocator, "FontSDF_vert.spv");
    // defer self.allocator.free(vert_spv);
    // const frag_spv = try graphics.loadSpv(self.allocator, "FontSDF_frag.spv");
    // defer self.allocator.free(frag_spv);

    const vert_spv = FontSDF_vert.spv();
    const frag_spv = FontSDF_frag.spv();

    var builder = try graphics.NeonVkPipelineBuilder.init(
        self.gc.dev,
        self.gc.vkd,
        self.gc.allocator,
        self.gc.vkAllocator,
        vert_spv,
        frag_spv,
    );
    defer builder.deinit();

    try builder.add_mesh_description();
    try builder.add_layout(self.textPipeData.descriptorSetLayout);
    try builder.add_layout(self.gc.singleTextureSetLayout);
    try builder.add_depth_stencil();
    try builder.add_push_constant_custom(PushConstant);
    try builder.init_triangle_pipeline(self.gc.actual_extent);

    self.textMaterial = try self.allocator.create(graphics.Material);
    self.textMaterial.* = graphics.Material{
        .materialName = self.materialNameText,
        .pipeline = (try builder.build(self.gc.renderPass)).?,
        .layout = builder.pipelineLayout,
    };

    try self.gc.add_material(self.textMaterial);
}

pub fn buildImagePipeline(self: *@This()) !void {
    var spriteDataBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
    try spriteDataBuilder.addBufferBinding(
        ImageGpu,
        .storage_buffer,
        .{ .vertex_bit = true, .fragment_bit = true },
        .storageBuffer,
    );
    self.pipeData = try spriteDataBuilder.build("Papyrus");
    defer spriteDataBuilder.deinit();

    const vert_spv = papyrus_vk_vert.spv();
    const frag_spv = papyrus_vk_frag.spv();

    var builder = try graphics.NeonVkPipelineBuilder.init(
        self.gc.dev,
        self.gc.vkd,
        self.gc.allocator,
        self.gc.vkAllocator,
        vert_spv,
        frag_spv,
    );

    defer builder.deinit();

    try builder.add_mesh_description();
    try builder.add_layout(self.pipeData.descriptorSetLayout);
    try builder.add_layout(self.gc.singleTextureSetLayout);
    try builder.add_depth_stencil();
    try builder.add_push_constant_custom(PushConstant);
    try builder.init_triangle_pipeline(self.gc.actual_extent);

    const material = try self.gc.allocator.create(graphics.Material);

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

pub fn uploadSSBOData(self: *@This(), frameId: usize, drawList: *const papyrus.DrawList) !void {
    var z = tracy.ZoneN(@src(), "Uploading SSBOs");
    defer z.End();

    var imagesGpu = self.mappedBuffers[frameId].objects;
    var imagesText = self.textImageBuffers[frameId].objects;

    self.textSsboCount = 0;
    self.ssboCount = 0;

    var textFrameContext = self.textRenderer.startRendering();

    for (drawList.items) |drawCmd| {
        switch (drawCmd.primitive) {
            .Rect => |rect| {
                imagesGpu[self.ssboCount] = ImageGpu{
                    .imagePosition = .{ .x = rect.tl.x, .y = rect.tl.y },
                    .imageSize = .{ .x = rect.size.x, .y = rect.size.y },
                    .anchorPoint = .{ .x = -1.0, .y = -1.0 },
                    .scale = .{ .x = 1.0, .y = 1.0 },
                    .alpha = 1.0,
                    .pad0 = std.mem.zeroes([4]u8),
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
                    .borderWidth = rect.borderWidth,
                    .flags = 0,
                };
                var imageSet: ?vk.DescriptorSet = null;

                if (rect.imageRef) |_imageRef| {
                    if (self.gc.textureSets.get(_imageRef.handle())) |maybeImageSet| {
                        imageSet = maybeImageSet;
                        imagesGpu[self.ssboCount].flags = 1;
                    }
                }

                try self.drawCommands.append(.{
                    .image = .{ .index = self.ssboCount, .imageSet = imageSet },
                });

                // core.ui_log("drawCmd: {any} {any} {any}", .{
                //     drawCmd.node,
                //     imagesGpu[self.ssboCount].imagePosition,
                //     imagesGpu[self.ssboCount].imageSize,
                // });
                self.ssboCount += 1;
            },
            .Text => |text| {
                const nextDisplay = self.textRenderer.getNextSlot(text.text.utf8.len, &textFrameContext);

                var textDisplay: *DisplayText = undefined;
                if (nextDisplay.small) {
                    textDisplay = self.textRenderer.smallDisplays.items[nextDisplay.index];
                } else {
                    textDisplay = self.textRenderer.displays.items[nextDisplay.index];
                }

                textDisplay.displaySize = text.textSize;
                textDisplay.renderMode = text.renderMode;
                textDisplay.boxSize = .{ .x = text.size.x, .y = text.size.y };
                textDisplay.color = text.color;
                textDisplay.position = .{ .x = text.tl.x, .y = text.tl.y };

                // TODO this is really bad and confusing.
                // The renderer should not be storing a hash on the papyrus resource.
                if (text.rendererHash != 0) {
                    textDisplay.atlas = self.textRenderer.fonts.get(text.rendererHash).?;
                }

                textDisplay.setString(&text.text.utf8);

                try textDisplay.updateMesh(text.flags.setSourceGeometry);
                self.papyrusCtx.get(drawCmd.node).textRenderedSize = textDisplay.renderedSize;

                if (text.flags.setSourceGeometry) {
                    self.papyrusCtx.textEntry.trg = textDisplay.renderedGeo;
                }

                // core.ui_log("nextDisplay = {any}, font = {d} sdf={any} ssbo={d}", .{
                //     nextDisplay,
                //     text.rendererHash,
                //     textDisplay.atlas.atlas.isSDF,
                //     self.textSsboCount,
                // });

                imagesText[self.textSsboCount] = .{
                    .isSdf = if (textDisplay.atlas.atlas.isSDF) 1 else 0,
                    .position = .{ .x = textDisplay.position.x, .y = textDisplay.position.y },
                    .size = .{ .x = textDisplay.boxSize.x, .y = textDisplay.boxSize.y },
                    .pad0 = 0,
                    .pad2 = undefined,
                };

                try self.drawCommands.append(.{ .text = .{
                    .index = nextDisplay.index,
                    .small = nextDisplay.small,
                    .ssbo = self.textSsboCount,
                } });

                self.textSsboCount += 1;
            },
        }
    }
}

pub fn rtPostDraw(self: *@This(), rt: *RenderThread, cmd: vk.CommandBuffer, frameIndex: u32) void {
    const shared = self.getShared(frameIndex);
    self.drawCommands.clearRetainingCapacity();

    const rtShared = rt.getShared(frameIndex);

    shared.lock.lock();
    self.uploadSSBOData(frameIndex, &shared.drawList) catch unreachable;
    shared.lock.unlock();

    var vertexBufferOffset: u64 = 0;

    var pushConstant = PushConstant{
        .extent = .{
            .x = rtShared.extent.x,
            .y = rtShared.extent.y,
        },
    };

    for (self.drawCommands.items) |command| {
        switch (command) {
            .text => |t| {
                self.gc.vkd.cmdPushConstants(cmd, self.textMaterial.layout, .{ .vertex_bit = true, .fragment_bit = true }, 0, @sizeOf(PushConstant), &pushConstant);
                if (t.small) {
                    var drawText = self.textRenderer.smallDisplays.items[t.index];
                    drawText.draw(frameIndex, cmd, self.textMaterial, t.ssbo, self.textPipeData);
                } else {
                    var drawText = self.textRenderer.displays.items[t.index];
                    drawText.draw(frameIndex, cmd, self.textMaterial, t.ssbo, self.textPipeData);
                }
            },
            .image => |img| {
                self.gc.vkd.cmdPushConstants(cmd, self.material.layout, .{ .vertex_bit = true, .fragment_bit = true }, 0, @sizeOf(PushConstant), &pushConstant);
                const index = img.index;
                self.gc.vkd.cmdBindPipeline(cmd, .graphics, self.material.pipeline);
                self.gc.vkd.cmdBindVertexBuffers(cmd, 0, 1, @ptrCast(&self.quad.buffer.buffer), @ptrCast(&vertexBufferOffset));
                self.gc.vkd.cmdBindIndexBuffer(cmd, self.indexBuffer.buffer.buffer, 0, .uint32);
                self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 0, 1, self.pipeData.getDescriptorSet(frameIndex), 0, undefined);

                if (img.imageSet) |imageSet| {
                    self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 1, 1, @ptrCast(&imageSet), 0, undefined);
                } else {
                    self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 1, 1, @ptrCast(&self.defaultTextureSet), 0, undefined);
                }

                self.gc.vkd.cmdDrawIndexed(cmd, @as(u32, @intCast(self.indexBuffer.indices.len)), 1, 0, 0, index);
            },
        }
    }
}

pub fn getShared(self: *@This(), fi: u32) *SharedData {
    return &self.sharedData[fi];
}

pub fn sendShared(self: *@This(), frameIndex: u32) void {
    const z1 = tracy.ZoneN(@src(), "PapryusIntegration - UploadingShared");
    defer z1.End();

    const shared = self.getShared(frameIndex);
    shared.lock.lock();
    defer shared.lock.unlock();

    self.papyrusCtx.makeDrawList(&shared.drawList, &shared.stringArena) catch unreachable;
}

pub fn postDraw(self: *@This(), cmd: vk.CommandBuffer, frameIndex: usize, frameTime: f64) void {
    _ = frameTime;

    var z = tracy.ZoneN(@src(), "Papyrus post draw");
    defer z.End();
    var vertexBufferOffset: u64 = 0;

    if (!self.displayDemo) {
        return;
    }

    var z1 = tracy.ZoneN(@src(), "Papyrus Making Draw List");
    self.papyrusCtx.makeDrawList(&self.drawList, &self.stringArena) catch unreachable;
    z1.End();

    self.drawCommands.clearRetainingCapacity();
    self.uploadSSBOData(frameIndex, &self.drawList) catch unreachable;

    var pushConstant = PushConstant{
        .extent = .{
            .x = @as(f32, @floatFromInt(self.gc.extent.width)),
            .y = @as(f32, @floatFromInt(self.gc.extent.height)),
        },
    };

    for (self.drawCommands.items) |command| {
        switch (command) {
            .text => |t| {
                self.gc.vkd.cmdPushConstants(cmd, self.textMaterial.layout, .{ .vertex_bit = true, .fragment_bit = true }, 0, @sizeOf(PushConstant), &pushConstant);
                if (t.small) {
                    var drawText = self.textRenderer.smallDisplays.items[t.index];
                    drawText.draw(frameIndex, cmd, self.textMaterial, t.ssbo, self.textPipeData);
                } else {
                    var drawText = self.textRenderer.displays.items[t.index];
                    drawText.draw(frameIndex, cmd, self.textMaterial, t.ssbo, self.textPipeData);
                }
            },
            .image => |img| {
                self.gc.vkd.cmdPushConstants(cmd, self.material.layout, .{ .vertex_bit = true, .fragment_bit = true }, 0, @sizeOf(PushConstant), &pushConstant);
                const index = img.index;
                self.gc.vkd.cmdBindPipeline(cmd, .graphics, self.material.pipeline);
                self.gc.vkd.cmdBindVertexBuffers(cmd, 0, 1, @ptrCast(&self.quad.buffer.buffer), @ptrCast(&vertexBufferOffset));
                self.gc.vkd.cmdBindIndexBuffer(cmd, self.indexBuffer.buffer.buffer, 0, .uint32);
                self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 0, 1, self.pipeData.getDescriptorSet(frameIndex), 0, undefined);

                if (img.imageSet) |imageSet| {
                    self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 1, 1, @ptrCast(&imageSet), 0, undefined);
                } else {
                    self.gc.vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 1, 1, @ptrCast(&self.defaultTextureSet), 0, undefined);
                }

                self.gc.vkd.cmdDrawIndexed(cmd, @as(u32, @intCast(self.indexBuffer.indices.len)), 1, 0, 0, index);
            },
        }
    }
}

pub fn shutdown(self: *@This()) void {
    self.gc.vkd.deviceWaitIdle(self.gc.dev) catch unreachable;
    core.ui_logs("Shutting down UI");
    for (self.mappedBuffers) |*mapped| {
        mapped.unmap(self.gc);
    }

    for (self.textImageBuffers) |*mapped| {
        mapped.unmap(self.gc);
    }
    self.drawCommands.deinit();

    self.stringArena.deinit();

    self.quad.deinit(self.gc);
    self.allocator.destroy(self.quad);
    self.gc.allocator.free(self.mappedBuffers);
    self.gc.allocator.free(self.textImageBuffers);

    self.textRenderer.deinit(self.allocator);

    self.pipeData.deinit(self.allocator, self.gc);
    self.textPipeData.deinit(self.allocator, self.gc);
    self.indexBuffer.deinit(self.gc);

    self.drawList.deinit();
    self.papyrusCtx.deinit();

    if (use_renderthread) {
        self.deinitShared();
    }

    core.ui_logs("finished shutting down ui");
}

pub fn deinit(self: *@This()) void {
    self.shutdown();
    self.allocator.destroy(self);
}

pub fn processEvents(self: *@This(), frameNumber: u64) core.EngineDataEventError!void {
    _ = frameNumber;
    _ = self;
}

const SharedData = struct {
    lock: std.Thread.Mutex,
    drawList: papyrus.DrawList,
    stringArena: std.heap.ArenaAllocator,
};

pub fn initShared(self: *@This()) void {
    for (&self.sharedData) |*s| {
        s.* = .{
            .lock = .{},
            .drawList = papyrus.DrawList.init(self.allocator),
            .stringArena = std.heap.ArenaAllocator.init(self.allocator),
        };
    }
}

pub fn deinitShared(self: *@This()) void {
    for (&self.sharedData) |*s| {
        s.drawList.deinit();
        s.stringArena.deinit();
    }
}
