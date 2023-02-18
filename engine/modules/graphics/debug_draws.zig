const std = @import("std");
const vk = @import("vulkan");

const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const assets = @import("../assets.zig");
const resources = @import("resources");
const gpd = graphics.gpu_pipe_data;

pub const DebugLine = struct {
    start: core.Vectorf,
    end: core.Vectorf,

    pub fn resolve(self: @This(), _: anytype) core.Transform {
        var delta = self.start.sub(self.end);
        var d = delta.normalize();
        var axz = std.math.atan2(f32, -d.z, d.x) + core.radians(180.0);
        var ay = -std.math.asin(d.y);
        var mat1 = core.zm.matFromRollPitchYaw(0, 0, ay);
        var mat2 = core.zm.rotationY(axz);
        var len = delta.length();
        //var r = core.zm.matFromRollPitchYaw(d.x * std.math.pi, d.z * std.math.pi, d.y * std.math.pi);
        //var r = core.zm.quatFromRollPitchYaw(d.x, d.z, d.y);
        //var r = core.zm.lookToRh(0, self.start.toZm(), );
        //var r = core.zm.mul(core.radians(90.0), 0), core.zm.lookToLh(self.start.toZm(), self.end.normalize().toZm(), core.Vectorf.new(0, 1, 0).toZm()));
        //var anglex = d.x
        //var r = core.matFromEulerAngles(d.x, d.y, d.z);
        //var r = core.zm.lookAtRh();

        //var len = delta.length();
        return core.zm.mul(core.zm.mul(
            core.zm.mul(mat1, mat2),
            core.zm.scaling(len, len, len),
        ), core.zm.translationV(self.start.toZm()));
        //core.zm.scaling(len,len,len),);//mul(
        //core.zm.mul(core.zm.scaling(len, len, len), r);
        //core.zm.translationV(self.start.toZm()),
        //);
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
    count,
};

pub const DebugPrimitive = struct {
    primitive: union(DebugPrimitiveType) {
        line: DebugLine,
        sphere: DebugSphere,
        box: DebugBox,
        count: struct {},
    },
    color: core.Vectorf = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
    duration: f32 = 0.0,

    pub fn resolve(self: @This()) core.Transform {
        comptime core.assert(@sizeOf(DebugPrimitiveGpu) == DebugPrimitiveGpu.TargetSize);

        return core.implement_func_for_tagged_union_nonull(self.primitive, "resolve", core.Transform, .{});
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
    pub const NeonObjectTable = core.RttiData.from(@This());

    // Member functions
    allocator: std.mem.Allocator,
    debugDraws: core.RingQueueU(DebugPrimitive),
    meshes: [@intCast(usize, @enumToInt(DebugPrimitiveType.count))]*graphics.Mesh = .{ undefined, undefined, undefined },
    gc: *graphics.NeonVkContext = undefined,
    pipeData: gpd.GpuPipeData = undefined,
    mappedBuffers: []gpd.GpuMappingData(DebugPrimitiveGpu) = undefined,
    material: *graphics.Material = undefined,
    materialName: core.Name = core.MakeName("mat_debugsys"),

    const Primitives = [_]assets.AssetRef{
        .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_primitive_sphere"), .path = "content/meshes/primitive_sphere.obj" },
        .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_primitive_box"), .path = "content/meshes/primitive_box.obj" },
        .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_primitive_line"), .path = "content/meshes/primitive_line.obj" },
    };

    pub fn prepareSubsystem(self: *@This(), gc: *graphics.NeonVkContext) !void {
        self.gc = gc;
        // load debug meshes
        try assets.loadList(Primitives);

        // assign debug meshes
        self.meshes[@intCast(usize, @enumToInt(DebugPrimitiveType.sphere))] = gc.meshes.get(core.MakeName("m_primitive_sphere").hash).?;
        self.meshes[@intCast(usize, @enumToInt(DebugPrimitiveType.box))] = gc.meshes.get(core.MakeName("m_primitive_box").hash).?;
        self.meshes[@intCast(usize, @enumToInt(DebugPrimitiveType.line))] = gc.meshes.get(core.MakeName("m_primitive_line").hash).?;
        try self.createPipeData();
        try self.createMaterial();
    }

    pub fn createPipeData(self: *@This()) !void {
        var dataBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
        dataBuilder.setObjectCount(objectCount);
        try dataBuilder.addBufferBinding(DebugPrimitiveGpu, .storage_buffer, .{ .vertex_bit = true }, .storageBuffer);
        self.pipeData = try dataBuilder.build();
        self.mappedBuffers = try self.pipeData.mapBuffers(self.gc, DebugPrimitiveGpu, 0);
    }

    pub fn createMaterial(self: *@This()) !void {
        var gc: *graphics.NeonVkContext = self.gc;
        var pipelineBuilder = try graphics.NeonVkPipelineBuilder.init(
            gc.dev,
            gc.vkd,
            gc.allocator,
            resources.debug_vert.len,
            @ptrCast([*]const u32, &resources.debug_vert),
            resources.debug_frag.len,
            @ptrCast([*]const u32, &resources.debug_frag),
        );
        defer pipelineBuilder.deinit();

        try pipelineBuilder.add_mesh_description();
        try pipelineBuilder.add_layout(self.gc.globalDescriptorLayout);
        try pipelineBuilder.add_layout(self.pipeData.descriptorSetLayout);
        try pipelineBuilder.add_depth_stencil();
        pipelineBuilder.set_polygon_mode(.line);
        pipelineBuilder.set_topology(.line_list);
        try pipelineBuilder.init_triangle_pipeline(gc.actual_extent);

        var materialName = self.materialName;
        var material = try gc.allocator.create(graphics.Material);
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
        const count: usize = self.debugDraws.count();
        var offset: usize = 0;
        while (offset < count) : (offset += 1) {
            var primitive = self.debugDraws.at(offset).?;
            var transform = primitive.resolve();
            var color = primitive.color;

            var object = &self.mappedBuffers[frameId].objects[offset];
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

        const paddedSceneSize = @intCast(u32, self.gc.pad_uniform_buffer_size(@sizeOf(graphics.vk_renderer.NeonVkSceneDataGpu)));
        var startOffset: u32 = paddedSceneSize * @intCast(u32, frameIndex);

        vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 0, 1, core.p_to_a(&self.gc.frameData[frameIndex].globalDescriptorSet), 1, core.p_to_a(&startOffset));
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
                .count => unreachable,
            }

            vkd.cmdBindVertexBuffers(cmd, 0, 1, core.p_to_a(&mesh.buffer.buffer), core.p_to_a(&bindOffset));
            vkd.cmdDraw(cmd, @intCast(u32, mesh.vertices.items.len), 1, 0, @intCast(u32, offset));

            offset += 1;
            primitive.duration -= @floatCast(f32, deltaTime);
            if (primitive.duration >= 0) {
                // push this primitive so that it goes to the next frame
                self.debugDraws.push(primitive) catch continue;
            }
        }
    }

    // NeonObject Interface Implementation
    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .allocator = allocator,
            .debugDraws = core.RingQueueU(DebugPrimitive).init(allocator, objectCount) catch unreachable,
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.mappedBuffers) |*mapped| {
            mapped.unmap(self.gc);
        }
        self.pipeData.deinit(self.allocator, self.gc);
        self.debugDraws.deinit(self.allocator);
    }
};

var gDebugDrawSys: *DebugDrawSubsystem = undefined;

pub fn init_debug_draw_subsystem() !void {
    gDebugDrawSys = try core.gEngine.createObject(DebugDrawSubsystem, .{ .can_tick = false });
    try gDebugDrawSys.prepareSubsystem(graphics.getContext());
    try graphics.registerRendererPlugin(gDebugDrawSys);
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
