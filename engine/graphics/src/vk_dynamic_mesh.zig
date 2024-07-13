const std = @import("std");
const core = @import("core");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const obj_loader = @import("objLoader");
const constants = @import("vk_constants.zig");
const vk_utils = @import("vk_utils.zig");

const NeonVkUploader = vk_utils.NeonVkUploader;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;
const ObjMesh = obj_loader.ObjMesh;
const ArrayList = std.ArrayList;
const Vectorf = core.Vectorf;
const Vector2f = core.Vector2f;
const LinearColor = core.colors.Color;
const NeonVkContext = vk_renderer.NeonVkContext;

const mesh = @import("mesh.zig");
const Vertex = mesh.Vertex;

const debug_struct = core.debug_struct;

pub const DynamicMeshManager = struct {
    gc: *NeonVkContext,

    allocator: std.mem.Allocator,
    dynMeshes: std.ArrayListUnmanaged(*DynamicMesh) = .{},
    uploader: NeonVkUploader,

    first: bool = true,

    pub fn init(gc: *NeonVkContext) !*@This() {
        const self = try gc.allocator.create(@This());
        self.* = @This(){
            .gc = gc,
            .allocator = gc.allocator,
            .uploader = try NeonVkUploader.init(gc, "dynamic mesh manager uploader"),
        };

        // core.graphics_log("creating the mesh manager", .{});
        return self;
    }

    pub fn deinit(self: *@This()) void {
        self.uploader.deinit();
        self.dynMeshes.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn addDynamicMesh(self: *@This(), dynamicMesh: *DynamicMesh) !void {
        try self.dynMeshes.append(self.allocator, dynamicMesh);
    }

    pub fn updateMeshes(self: *@This(), cmd: vk.CommandBuffer) !void {
        for (self.dynMeshes.items) |dynMesh| {
            try dynMesh.maybeUpdateVertices(cmd);
        }
    }

    pub fn finishUpload(self: *@This()) !void {
        if (self.uploader.isActive) {
            var t3 = core.tracy.ZoneN(@src(), "finishing dynamic mesh upload context");
            defer t3.End();

            try self.uploader.waitForFences();

            for (self.dynMeshes.items) |dynMesh| {
                if (dynMesh.isDirty) {
                    dynMesh.bumpSwapId();
                }
            }
        }
    }
};

pub const DynamicMesh = struct {
    pub const GeometryMode = enum { quads, triangles };

    allocator: std.mem.Allocator,
    gc: *NeonVkContext,

    vertices: []Vertex = undefined,
    geometryMode: GeometryMode = .quads, // geometry elaboration mode
    indicesMaxCount: u32 = 0,

    indexBuffers: [2]NeonVkBuffer = undefined,
    indexBufferLen: [2]u32 = .{ 0, 0 },

    vertexBuffers: [2]NeonVkBuffer = undefined,
    vertexBufferLen: [2]u32 = .{ 0, 0 },

    swapId: usize = 0, // the index of the previously uploaded vertex buffer
    vertexCount: u32 = 0, //

    stagingVertexBuffer: NeonVkBuffer = undefined,
    stagingIndexBuffer: NeonVkBuffer = undefined,

    isDirty: bool = true,

    maxVertexCount: u32,

    pub fn init(gc: *NeonVkContext, allocator: std.mem.Allocator, opts: struct {
        maxVertexCount: u32 = 4096,
        mode: GeometryMode = .quads,
    }) !*@This() {
        var self = try allocator.create(@This());
        self.* = .{
            .maxVertexCount = opts.maxVertexCount,
            .allocator = allocator,
            .vertices = try allocator.alloc(Vertex, opts.maxVertexCount),
            .gc = gc,
            .geometryMode = opts.mode,
        };

        try gc.dynamicMeshManager.addDynamicMesh(self);

        self.allocator = allocator;
        self.gc = gc;

        {
            self.stagingIndexBuffer = try gc.vkAllocator.createStagingBuffer(opts.maxVertexCount * @sizeOf(u32) * 6 / 4, "DynamicMesh.init - index staging");
            self.stagingVertexBuffer = try gc.vkAllocator.createStagingBuffer(opts.maxVertexCount * @sizeOf(Vertex), "DynamicMesh.init - vertex staging");

            inline for (0..2) |i| {
                self.indexBuffers[i] = try gc.vkAllocator.createGpuBuffer(opts.maxVertexCount * @sizeOf(u32), .{
                    .index_buffer_bit = true,
                }, "DynamicMesh.init - gpu indexBuffer" ++ std.fmt.comptimePrint("[{d}]", .{i}));

                self.vertexBuffers[i] = try gc.vkAllocator.createGpuBuffer(opts.maxVertexCount * @sizeOf(Vertex), .{
                    .vertex_buffer_bit = true,
                }, "DynamicMesh.init - gpu vertexBuffer" ++ std.fmt.comptimePrint("[{d}]", .{i}));
            }
        }

        return self;
    }

    pub fn getIndexBuffer(self: *@This()) NeonVkBuffer {
        return self.indexBuffers[self.swapId];
    }

    pub fn getVertexBuffer(self: *@This()) NeonVkBuffer {
        return self.vertexBuffers[self.swapId];
    }

    pub fn getIndexBufferLen(self: *@This()) u32 {
        return self.indexBufferLen[self.swapId];
    }

    pub fn getVertexBufferLen(self: *@This()) u32 {
        return self.vertexBufferLen[self.swapId];
    }

    pub fn maybeUpdateVertices(self: *@This(), cmd: vk.CommandBuffer) !void {
        if (!self.isDirty) {
            return;
        }
        var t1 = core.tracy.ZoneN(@src(), "Dynamic Mesh upload with barriers");
        defer t1.End();
        self.isDirty = false;

        try self.stageDirtyVertices();
        if (self.indexBufferLen[self.swapId] == 0 or self.vertexCount == 0) {
            return;
        }

        var vkd = self.gc.vkd;

        var copy = vk.BufferCopy{
            .dst_offset = 0,
            .src_offset = 0,
            .size = self.indexBufferLen[self.swapId] * @as(u32, @intCast(@sizeOf(u32))),
        };

        // submit index Buffer
        self.gc.vkd.cmdCopyBuffer(
            cmd,
            self.stagingIndexBuffer.buffer,
            self.indexBuffers[self.swapId].buffer,
            1,
            @as([*]const vk.BufferCopy, @ptrCast(&copy)),
        );

        var indexMemoryBarrier = vk.BufferMemoryBarrier{
            .buffer = self.indexBuffers[self.swapId].buffer,
            .src_access_mask = .{
                .transfer_read_bit = true,
            },
            .dst_access_mask = .{
                //.transfer_write_bit = true,
                .index_read_bit = true,
            },
            .src_queue_family_index = 0,
            .dst_queue_family_index = 0,
            .offset = 0,
            .size = copy.size,
        };

        copy.size = self.vertexCount * @as(u32, @intCast(@sizeOf(Vertex)));

        // Insert Barrier for indexBuffer
        vkd.cmdPipelineBarrier(
            cmd,
            .{
                .transfer_bit = true,
            },
            .{
                .vertex_input_bit = true,
            },
            .{},
            0,
            undefined,
            1,
            @ptrCast(&indexMemoryBarrier),
            0,
            undefined,
        );

        // submit vertex Buffer
        self.gc.vkd.cmdCopyBuffer(
            cmd,
            self.stagingVertexBuffer.buffer,
            self.vertexBuffers[self.swapId].buffer,
            1,
            @as([*]const vk.BufferCopy, @ptrCast(&copy)),
        );

        // Insert Barrier for vertexBuffer
        var vertexMemoryBarrier = vk.BufferMemoryBarrier{
            .buffer = self.vertexBuffers[self.swapId].buffer,
            .src_access_mask = .{
                .transfer_read_bit = true,
            },
            .dst_access_mask = .{
                // .transfer_write_bit = true,
                .vertex_attribute_read_bit = true,
            },
            .src_queue_family_index = 0,
            .dst_queue_family_index = 0,
            .offset = 0,
            .size = copy.size,
        };

        vkd.cmdPipelineBarrier(
            cmd,
            .{
                .transfer_bit = true,
            },
            .{
                .vertex_input_bit = true,
            },
            .{},
            0,
            undefined,
            1,
            @ptrCast(&vertexMemoryBarrier),
            0,
            undefined,
        );
    }

    pub fn stageDirtyVertices(self: *@This()) !void {
        const newSwapId = (self.swapId + 1) % 2;
        // map buffers

        var slice = try self.gc.vkAllocator.mapMemorySlice(Vertex, self.stagingVertexBuffer, self.vertices.len);
        var indexSlice = try self.gc.vkAllocator.mapMemorySlice(u32, self.stagingIndexBuffer, self.vertices.len * 6 / 4);

        defer self.gc.vkAllocator.unmapMemory(self.stagingVertexBuffer);
        defer self.gc.vkAllocator.unmapMemory(self.stagingIndexBuffer);

        // copy over vertices to mapped buffer
        for (0..self.vertexCount) |i| {
            slice[i] = self.vertices[i];
        }
        self.vertexBufferLen[newSwapId] = self.vertexCount;

        // interpret vertices as quads.
        if (self.geometryMode == .quads) {
            var index: u32 = 0;
            var vertex: u32 = 0;
            while (vertex < self.vertexCount) {
                indexSlice[index + 0] = vertex + 0;
                indexSlice[index + 1] = vertex + 1;
                indexSlice[index + 2] = vertex + 2;

                indexSlice[index + 3] = vertex + 2;
                indexSlice[index + 4] = vertex + 3;
                indexSlice[index + 5] = vertex + 0;

                vertex += 4;
                index += 6;
            }
            self.indexBufferLen[newSwapId] = index;
        }

        self.swapId = newSwapId;
    }

    // a stream-like interface for creating vertices
    pub fn uploadVertices(self: *@This(), uploader: *NeonVkUploader) !void {
        if (!self.isDirty) {
            return;
        }

        self.dirty = false;

        const newSwapId = (self.swapId + 1) % 2;
        // map buffers

        var slice = try self.gc.vkAllocator.mapMemorySlice(Vertex, self.stagingVertexBuffer, self.vertices.len);
        var indexSlice = try self.gc.vkAllocator.mapMemorySlice(u32, self.stagingIndexBuffer, self.vertices.len * 6 / 4);

        defer self.gc.vkAllocator.unmapMemory(self.stagingVertexBuffer);
        defer self.gc.vkAllocator.unmapMemory(self.stagingIndexBuffer);

        // copy over vertices to mapped buffer
        // so... this right here would need to lock.. actually this would be a try-lock
        // if we fail to lock it... that's ok. we can just try again at the end of the frame.
        // what happens if we always fail to lock it?

        for (0..self.vertexCount) |i| {
            slice[i] = self.vertices[i];
        }
        self.vertexBufferLen[newSwapId] = self.vertexCount;

        // interpret vertices as quads.
        if (self.geometryMode == .quads) {
            var index: u32 = 0;
            var vertex: u32 = 0;
            while (vertex < self.vertexCount) {
                indexSlice[index + 0] = vertex + 0;
                indexSlice[index + 1] = vertex + 1;
                indexSlice[index + 2] = vertex + 2;

                indexSlice[index + 3] = vertex + 2;
                indexSlice[index + 4] = vertex + 3;
                indexSlice[index + 5] = vertex + 0;

                vertex += 4;
                index += 6;
            }
            self.indexBufferLen[newSwapId] = index;
        }

        // upload index and vertex buffers
        try uploader.addBufferUpload(
            self.stagingIndexBuffer,
            self.indexBuffers[newSwapId],
            self.indexBufferLen[newSwapId] * @as(u32, @intCast(@sizeOf(u32))),
        );

        try uploader.addBufferUpload(
            self.stagingVertexBuffer,
            self.vertexBuffers[newSwapId],
            self.vertexCount * @as(u32, @intCast(@sizeOf(Vertex))),
        );
    }

    pub fn bumpSwapId(self: *@This()) void {
        self.swapId = (self.swapId + 1) % 2;
        self.isDirty = false;
    }

    pub fn clearVertices(self: *@This()) void {
        self.vertexCount = 0;
        self.isDirty = true;
    }

    pub fn addVertexList(self: *@This(), list: []const Vertex) void {
        if (list.len > 0) {
            self.isDirty = true;
        }
        for (list) |v| {
            self.vertices[self.vertexCount] = v;
            self.vertexCount += 1;
        }
    }

    // adds a quad only in the X and y Space,
    pub fn addQuad2D(
        self: *@This(),
        _topLeft: core.Vectorf, // only x and y is considered
        _size: core.Vectorf, // only x and y is considered
        topLeftUV: core.Vector2f,
        uvSize: core.Vector2f,
        color: LinearColor,
    ) void {
        var topLeft = _topLeft;
        var size = _size;

        topLeft.z = 0;
        size.z = 0;

        const normal = Vectorf{ .x = 0, .y = 0, .z = -1 };

        var vertices: [4]Vertex = undefined;

        vertices[0] = .{
            .position = topLeft,
            .normal = normal,
            .uv = topLeftUV,
            .color = color,
        };

        vertices[1] = .{
            .position = topLeft.add(.{ .x = size.x }),
            .normal = normal,
            .uv = topLeftUV.add(core.Vector2f{ .x = uvSize.x }),
            .color = color,
        };

        vertices[2] = .{
            .position = topLeft.add(size),
            .normal = normal,
            .uv = topLeftUV.add(uvSize),
            .color = color,
        };

        vertices[3] = .{
            .position = topLeft.add(.{ .y = size.y }),
            .normal = normal,
            .uv = topLeftUV.add(core.Vector2f{ .y = uvSize.y }),
            .color = color,
        };

        self.addVertexList(&vertices);
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.vertices);

        const vkAllocator = self.gc.vkAllocator;

        self.stagingVertexBuffer.deinit(vkAllocator);
        self.stagingIndexBuffer.deinit(vkAllocator);

        for (0..self.indexBuffers.len) |i| {
            self.indexBuffers[i].deinit(vkAllocator);
            self.vertexBuffers[i].deinit(vkAllocator);
        }

        self.allocator.destroy(self);
        // should remove ourselves from the manager
    }
};
