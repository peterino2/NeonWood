const std = @import("std");
const vk = @import("vulkan");

const core = @import("core");
const graphics = @import("graphics.zig");
const assets = @import("assets");
const debug_vert = @import("debug_vert");
const debug_frag = @import("debug_frag");
const tracy = core.tracy;
const gpd = graphics.gpu_pipe_data;

pub const DebugLine = struct {
    start: core.Vectorf,
    end: core.Vectorf,

    pub fn resolve(self: @This(), _: anytype) core.Transform {
        var delta = self.start.sub(self.end);
        const d = delta.normalize();
        const axz = std.math.atan2(-d.z, d.x) + core.radians(180.0);
        const ay = -std.math.asin(d.y);
        const mat1 = core.zm.matFromRollPitchYaw(0, 0, ay);
        const mat2 = core.zm.rotationY(axz);
        const len = delta.length();
        return core.zm.mul(core.zm.mul(
            core.zm.mul(mat1, mat2),
            core.zm.scaling(len, len, len),
        ), core.zm.translationV(self.start.toZm()));
    }
};

pub const DebugSphere = struct {
    position: core.Vectorf,
    radius: f32,

    pub fn resolve(self: @This(), _: anytype) core.Transform {
        return core.zm.mul(
            core.zm.scaling(self.radius, self.radius, self.radius),
            core.zm.translationV(self.position.toZm()),
        );
    }
};

pub const DebugBox = struct {
    position: core.Vectorf,
    scale: core.Vectorf,
    rotation: core.Quat,

    pub fn resolve(self: @This(), _: anytype) core.Transform {
        return core.zm.mul(core.zm.mul(
            core.zm.matFromQuat(self.rotation),
            core.zm.scalingV(self.scale.toZm()),
        ), core.zm.translationV(self.position.toZm()));
    }
};

const DebugPrimitiveType = enum(u8) {
    line = 0,
    sphere = 1,
    box = 2,
};

pub const DebugPrimitive = struct {
    primitive: union(DebugPrimitiveType) {
        line: DebugLine,
        sphere: DebugSphere,
        box: DebugBox,
    },
    color: core.Vectorf = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
    duration: f32 = 0.0,

    pub fn resolve(self: @This()) core.Transform {
        comptime core.assert(@sizeOf(DebugPrimitiveGpu) == DebugPrimitiveGpu.TargetSize);

        switch (self.primitive) {
            .line => |inner| {
                return inner.resolve(.{});
            },
            .sphere => |inner| {
                return inner.resolve(.{});
            },
            .box => |inner| {
                return inner.resolve(.{});
            },
        }
        unreachable;

        // return core.implement_func_for_tagged_union_nonull(self.primitive, "resolve", core.Transform, .{});
    }
};

const DebugPrimitiveGpu = struct {
    const UnpaddedSize = @sizeOf(core.Transform) + @sizeOf(core.Vectorf);
    const TargetSize = 80;

    model: core.Transform,
    color: core.Vectorf,

    pad: [TargetSize - UnpaddedSize]u8 = std.mem.zeroes([TargetSize - UnpaddedSize]u8),
};

const objectCount = 4096;

// Debug draw system also an example of how to do plugins in this engine
pub const DebugDrawSubsystem = struct {

    // Interfaces and tables
    pub const RendererInterfaceVTable = graphics.RendererInterface.from(@This());
    pub var NeonObjectTable: core.RttiData = core.RttiData.from(@This());

    // Member functions
    allocator: std.mem.Allocator,
    debugDraws: core.RingQueueU(DebugPrimitive),
    meshes: [@as(usize, @intCast(@intFromEnum(DebugPrimitiveType.box) + 1))]*graphics.Mesh = .{ undefined, undefined, undefined },
    gc: *graphics.NeonVkContext = undefined,
    pipeData: gpd.GpuPipeData = undefined,
    mappedBuffers: []gpd.GpuMappingData(DebugPrimitiveGpu) = undefined,
    material: *graphics.Material = undefined,
    materialName: core.Name = core.MakeName("mat_debugsys"),

    const Primitives = [_]assets.AssetImportReference{
        assets.MakeImportRef("Mesh", "m_primitive_sphere", "content/meshes/primitive_sphere.obj"),
        assets.MakeImportRef("Mesh", "m_primitive_box", "content/meshes/primitive_box.obj"),
        assets.MakeImportRef("Mesh", "m_primitive_line", "content/meshes/primitive_line.obj"),
    };

    pub fn prepareSubsystem(self: *@This(), gc: *graphics.NeonVkContext) !void {
        self.gc = gc;
        // load debug meshes
        try assets.loadList(Primitives);

        // assign debug meshes
        self.meshes[@as(usize, @intCast(@intFromEnum(DebugPrimitiveType.sphere)))] = gc.meshes.get(core.MakeName("m_primitive_sphere").handle()).?;
        self.meshes[@as(usize, @intCast(@intFromEnum(DebugPrimitiveType.box)))] = gc.meshes.get(core.MakeName("m_primitive_box").handle()).?;
        self.meshes[@as(usize, @intCast(@intFromEnum(DebugPrimitiveType.line)))] = gc.meshes.get(core.MakeName("m_primitive_line").handle()).?;
        try self.createPipeData();
        try self.createMaterial();
    }

    pub fn createPipeData(self: *@This()) !void {
        var dataBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
        defer dataBuilder.deinit();
        dataBuilder.setObjectCount(objectCount);
        try dataBuilder.addBufferBinding(DebugPrimitiveGpu, .storage_buffer, .{ .vertex_bit = true }, .storageBuffer);
        self.pipeData = try dataBuilder.build("debug draws");
        self.mappedBuffers = try self.pipeData.mapBuffers(self.gc, DebugPrimitiveGpu, 0);
    }

    pub fn createMaterial(self: *@This()) !void {
        var gc: *graphics.NeonVkContext = self.gc;

        const vert_spv = try graphics.loadSpv(gc.allocator, "debug_vert.spv");
        defer gc.allocator.free(vert_spv);

        const frag_spv = try graphics.loadSpv(gc.allocator, "debug_frag.spv");
        defer gc.allocator.free(frag_spv);

        var pipelineBuilder = try graphics.NeonVkPipelineBuilder.init(
            gc.dev,
            gc.vkd,
            gc.allocator,
            gc.vkAllocator,
            vert_spv,
            frag_spv,
        );
        defer pipelineBuilder.deinit();

        try pipelineBuilder.add_mesh_description();
        try pipelineBuilder.add_layout(self.gc.globalDescriptorLayout);
        try pipelineBuilder.add_layout(self.pipeData.descriptorSetLayout);
        try pipelineBuilder.add_depth_stencil();
        pipelineBuilder.set_polygon_mode(.line);
        pipelineBuilder.set_topology(.line_list);
        try pipelineBuilder.init_triangle_pipeline(gc.actual_extent);

        const materialName = self.materialName;
        const material = try gc.allocator.create(graphics.Material);
        material.* = graphics.Material{
            .materialName = materialName,
            .pipeline = (try pipelineBuilder.build(gc.renderPass)).?,
            .layout = pipelineBuilder.pipelineLayout,
        };

        try gc.add_material(material);

        self.material = material;
    }

    // Renderer Ineterface Implementation
    pub fn preDraw(self: *@This(), frameId: usize) void {
        var zone = tracy.ZoneN(@src(), "Debug draw renderer");
        defer zone.End();

        const count: usize = self.debugDraws.count();
        var offset: usize = 0;
        while (offset < count) : (offset += 1) {
            const primitive = self.debugDraws.at(offset).?;
            const transform = primitive.resolve();
            const color = primitive.color;

            const object = &self.mappedBuffers[frameId].objects[offset];
            object.*.color = color;
            object.*.model = transform;
        }
    }

    pub fn onBindObject(
        self: *@This(),
        objectHandle: core.ObjectHandle,
        drawIndex: usize,
        cmd: vk.CommandBuffer,
        frameIndex: usize,
    ) void {
        _ = self;
        _ = objectHandle;
        _ = cmd;
        _ = drawIndex;
        _ = frameIndex;
    }

    pub fn postDraw(
        self: *@This(),
        cmd: vk.CommandBuffer,
        frameIndex: usize,
        deltaTime: f64,
    ) void {
        var vkd = self.gc.vkd;

        var offset: usize = 0;
        vkd.cmdBindPipeline(cmd, .graphics, self.material.pipeline);
        var bindOffset: usize = 0;
        const count: usize = self.debugDraws.count();

        const paddedSceneSize = @as(u32, @intCast(self.gc.pad_uniform_buffer_size(@sizeOf(graphics.NeonVkSceneDataGpu))));
        var startOffset: u32 = paddedSceneSize * @as(u32, @intCast(frameIndex));

        vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 0, 1, @ptrCast(&self.gc.frameData[frameIndex].globalDescriptorSet), 1, @ptrCast(&startOffset));
        while (offset < count) {
            var primitive: DebugPrimitive = self.debugDraws.pop().?;
            vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 1, 1, self.pipeData.getDescriptorSet(frameIndex), 0, undefined);

            var mesh: *graphics.Mesh = undefined;
            switch (primitive.primitive) {
                .box => {
                    mesh = self.meshes[2];
                },
                .sphere => {
                    mesh = self.meshes[1];
                },
                .line => {
                    mesh = self.meshes[0];
                },
            }

            vkd.cmdBindVertexBuffers(cmd, 0, 1, @ptrCast(&mesh.buffer.buffer), @ptrCast(&bindOffset));
            vkd.cmdDraw(cmd, @as(u32, @intCast(mesh.vertices.items.len)), 1, 0, @as(u32, @intCast(offset)));

            offset += 1;
            primitive.duration -= @as(f32, @floatCast(deltaTime));
            if (primitive.duration >= 0) {
                // push this primitive so that it goes to the next frame
                self.debugDraws.push(primitive) catch continue;
            }
        }
    }

    // NeonObject Interface Implementation
    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
            .debugDraws = core.RingQueueU(DebugPrimitive).init(allocator, objectCount) catch unreachable,
        };

        return self;
    }

    pub fn shutdown(self: *@This()) void {
        for (self.mappedBuffers) |*mapped| {
            mapped.unmap(self.gc);
        }
        self.gc.allocator.free(self.mappedBuffers);
        self.pipeData.deinit(self.allocator, self.gc);
        self.debugDraws.deinit(self.allocator);
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

var gDebugDrawSys: *DebugDrawSubsystem = undefined;

pub fn init_debug_draw_subsystem() !void {
    gDebugDrawSys = try core.gEngine.createObject(DebugDrawSubsystem, .{ .can_tick = false });
    try gDebugDrawSys.prepareSubsystem(graphics.getContext());
    try graphics.registerRendererPlugin(gDebugDrawSys);
}

pub fn shutdown() void {
    gDebugDrawSys.shutdown();
}

pub const DebugDrawParams = struct {
    color: core.Vectorf = .{ .x = 0, .y = 1.0, .z = 0 },
    duration: f32 = 0,
};

pub fn debugSphere(position: core.Vectorf, radius: f32, params: DebugDrawParams) void {
    gDebugDrawSys.debugDraws.push(.{
        .primitive = .{ .sphere = .{
            .position = position,
            .radius = radius,
        } },
        .color = params.color,
        .duration = params.duration,
    }) catch return;
}

pub fn debugLine(start: core.Vectorf, end: core.Vectorf, params: DebugDrawParams) void {
    gDebugDrawSys.debugDraws.push(.{
        .primitive = .{ .line = .{
            .start = start,
            .end = end,
        } },
        .color = params.color,
        .duration = params.duration,
    }) catch return;
}
