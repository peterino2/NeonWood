const std = @import("std");
const vk = @import("vulkan");
const core = @import("core");

pub const MeshPoolCreationSettings = struct {
    vertexCount: u32 = 4_000_000,
    indexCount: u32 = 16_000_000,
};

pub const MeshUpdate = union(enum(u8)) {
    new: struct {
        vertices: []MeshVertex,
        indices: []u32,
        name: core.Name,
    },
    free: struct {
        vertices: Span,
        indices: Span,
        name: core.Name,
    },

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        switch (self) {
            .new => |new| {
                allocator.free(new.vertices);
                allocator.free(new.indices);
            },
            .free => {},
        }
    }
};

const UploadList = struct {
    ctx: *MeshPoolBuffers,
    uploads: std.ArrayList(Transfer),
    destination: NeonVkBuffer,

    pub const Transfer = struct {
        staging: NeonVkBuffer,
        destination: Span,
    };

    pub fn init(ctx: *MeshPoolBuffers, destination: NeonVkBuffer) @This() {
        return .{
            .ctx = ctx,
            .uploads = std.ArrayList(Transfer).init(ctx.allocator),
            .destination = destination,
        };
    }

    pub fn issueCopy(self: *@This(), uploader: *NeonVkUploader, index: u32, elementSize: u32) !void {
        try core.assert(uploader.isActive);

        const upload = self.uploads.items[index];
        var copy = vk.BufferCopy{
            .dst_offset = upload.destination.start * elementSize,
            .src_offset = 0,
            .size = upload.destination.size * elementSize,
        };

        const cmd = uploader.commandBuffer;

        vkd.cmdCopyBuffer(
            cmd,
            upload.staging.buffer,
            self.destination.buffer,
            1,
            @as([*]const vk.BufferCopy, @ptrCast(&copy)),
        );
    }

    pub fn deinit(self: *@This()) void {
        for (self.uploads.items) |*up| {
            up.staging.deinit(self.ctx.vkAllocator);
        }

        self.uploads.deinit();
    }
};

// should be owned by renderthread
//
// operation per frame
//
// 1. async loading of vertices push model load results into a queue
// 2. these results ar ethen installe dinto the vertex pool

var gMeshPoolBuffer: *MeshPoolBuffers = undefined;

const MeshVertexTransmute = extern struct { data: [@sizeOf(MeshVertex)]u8 };

pub const IndexedMesh = struct {
    vertex: Span,
    index: Span,
    name: core.Name,
};

pub fn getIndexedMeshByName(name: core.Name) ?IndexedMesh {
    gMeshPoolBuffer.vertexMapLock.lock();
    defer gMeshPoolBuffer.vertexMapLock.unlock();
    return gMeshPoolBuffer.vertexMap.get(name.handle());
}

pub const MeshPoolBuffers = struct {
    vertexBuffer: NeonVkBuffer, // gpu sided vertex buffer
    indexBuffer: NeonVkBuffer, // gpu sided vertex buffer

    allocator: std.mem.Allocator,
    vkAllocator: *NeonVkAllocator,

    gc: *NeonVkContext,

    uploader: NeonVkUploader,
    updateRequests: Requests,

    indexSpans: MergedSpans,
    vertexSpans: MergedSpans,

    vertexMapLock: std.Thread.Mutex,
    vertexMap: std.AutoHashMapUnmanaged(u32, IndexedMesh),

    const Requests = core.RingQueue(MeshUpdate);

    pub fn create(
        allocator: std.mem.Allocator,
        gc: *NeonVkContext,
        opt: MeshPoolCreationSettings,
    ) !*@This() {
        const self = try allocator.create(@This());
        self.allocator = allocator;
        self.updateRequests = try Requests.init(allocator, 4096);

        self.vertexMap = .{};
        self.vertexMapLock = .{};

        self.indexSpans = try MergedSpans.init(allocator, opt.indexCount);
        self.vertexSpans = try MergedSpans.init(allocator, opt.vertexCount);

        self.vertexBuffer = try gc.vkAllocator.createGpuBuffer(opt.vertexCount * @sizeOf(MeshVertex), .{
            .vertex_buffer_bit = true,
        }, "Mesh Pool gpu vertex buffer");

        self.indexBuffer = try gc.vkAllocator.createGpuBuffer(opt.indexCount * @sizeOf(u32), .{
            .index_buffer_bit = true,
        }, "Mesh Pool gpu vertex buffer");

        self.gc = gc;
        self.vkAllocator = gc.vkAllocator;
        self.uploader = try NeonVkUploader.init(gc, "Mesh Pool uploader");

        gMeshPoolBuffer = self;

        return self;
    }

    pub fn checkUpdates(self: *@This()) !void {
        if (self.updateRequests.count() <= 0) {
            return;
        }

        self.updateRequests.lock();
        defer self.updateRequests.unlock();

        var vertexUploadList = UploadList.init(self, self.vertexBuffer);
        defer vertexUploadList.deinit();
        var indexUploadList = UploadList.init(self, self.indexBuffer);
        defer indexUploadList.deinit();

        while (self.updateRequests.popFromUnlocked()) |update| {
            switch (update) {
                .new => |new| {
                    const indexSpan = try self.indexSpans.allocate(@intCast(new.indices.len));
                    const vertexSpan = try self.vertexSpans.allocate(@intCast(new.vertices.len));

                    const stagingVertex = try self.vkAllocator.createStagingBuffer(
                        @intCast(new.vertices.len * @sizeOf(MeshVertex)),
                        "staging vertex buffer",
                    );
                    {
                        const stagingVertexMapped = try self.vkAllocator.mapBuffer(MeshVertex, stagingVertex);
                        defer self.vkAllocator.unmapMemory(stagingVertex);
                        std.mem.copyForwards(MeshVertex, stagingVertexMapped, new.vertices);
                    }

                    const stagingIndex = try self.vkAllocator.createStagingBuffer(
                        @intCast(new.indices.len * @sizeOf(u32)),
                        "staging index buffer",
                    );
                    {
                        const stagingMapped = try self.vkAllocator.mapBuffer(u32, stagingIndex);
                        defer self.vkAllocator.unmapMemory(stagingIndex);
                        for (new.indices, 0..) |index, i| {
                            stagingMapped[i] = index + vertexSpan.start;
                        }
                    }
                    try vertexUploadList.uploads.append(.{ .staging = stagingVertex, .destination = vertexSpan });
                    try indexUploadList.uploads.append(.{ .staging = stagingIndex, .destination = indexSpan });

                    gMeshPoolBuffer.vertexMapLock.lock();
                    try gMeshPoolBuffer.vertexMap.put(self.allocator, new.name.handle(), .{ .index = indexSpan, .vertex = vertexSpan, .name = new.name });
                    gMeshPoolBuffer.vertexMapLock.unlock();
                },
                .free => |free| {
                    self.vertexSpans.removeSpan(free.vertices);
                    self.indexSpans.removeSpan(free.indices);
                },
            }

            update.deinit(self.allocator);
        }

        try self.uploader.startUploadContext();
        // iterate over both upload lists and isssue uploads.

        for (indexUploadList.uploads.items, 0..) |_, i| {
            try indexUploadList.issueCopy(&self.uploader, @intCast(i), @sizeOf(u32));
            try vertexUploadList.issueCopy(&self.uploader, @intCast(i), @sizeOf(MeshVertex));
        }
        // Insert Barrier for indexBuffer
        var indexMemoryBarrier = vk.BufferMemoryBarrier{
            .buffer = self.indexBuffer.buffer,
            .src_access_mask = .{ .transfer_read_bit = true },
            .dst_access_mask = .{ .index_read_bit = true },
            .src_queue_family_index = 0,
            .dst_queue_family_index = 0,
            .offset = 0,
            .size = vk.WHOLE_SIZE,
        };
        vkd.cmdPipelineBarrier(
            self.uploader.commandBuffer, //
            .{ .transfer_bit = true }, //
            .{ .vertex_input_bit = true }, //
            .{}, //
            0,
            undefined,
            1,
            @ptrCast(&indexMemoryBarrier),
            0,
            undefined,
        );

        // Insert Barrier for vertexBuffer
        var vertexMemoryBarrier = vk.BufferMemoryBarrier{
            .buffer = self.vertexBuffer.buffer,
            .src_access_mask = .{ .transfer_read_bit = true },
            .dst_access_mask = .{
                .vertex_attribute_read_bit = true,
            },
            .src_queue_family_index = 0,
            .dst_queue_family_index = 0,
            .offset = 0,
            .size = vk.WHOLE_SIZE,
        };

        vkd.cmdPipelineBarrier(
            self.uploader.commandBuffer,
            .{ .transfer_bit = true },
            .{ .vertex_input_bit = true },
            .{},
            0,
            undefined,
            1,
            @ptrCast(&vertexMemoryBarrier),
            0,
            undefined,
        );

        try self.uploader.finishUploadContext();
    }

    pub fn destroy(self: *@This()) void {
        {
            self.updateRequests.lock();
            defer self.updateRequests.unlock();
            while (self.updateRequests.popFromUnlocked()) |x| {
                x.deinit(self.allocator);
            }
        }

        self.vertexMap.deinit(self.allocator);
        self.indexSpans.deinit();
        self.vertexSpans.deinit();

        self.vertexBuffer.deinit(self.gc.vkAllocator);

        self.indexBuffer.deinit(self.gc.vkAllocator);
        self.uploader.deinit();

        self.updateRequests.deinit();
        self.allocator.destroy(self);
    }
};

pub const PoolMesh = struct {
    vertexSpan: Span,
    indexSpan: Span,
};

pub fn getMeshPoolBuffers() struct { index: NeonVkBuffer, vertex: NeonVkBuffer } {
    return .{
        .index = gMeshPoolBuffer.indexBuffer,
        .vertex = gMeshPoolBuffer.vertexBuffer,
    };
}

pub fn loadIndexedMeshForPooling(meshName: core.Name, path: []const u8) !void {
    const file = try core.fs().loadFile(path);
    defer core.fs().unmap(file);

    const allocator = gMeshPoolBuffer.allocator;

    var Objs = try objLoader.loadObjBytes(file.bytes, allocator);
    defer Objs.deinit();

    var vertexMap = std.AutoHashMap(MeshVertexTransmute, u32).init(allocator);
    defer vertexMap.deinit();
    var vertexList = std.ArrayList(MeshVertex).init(allocator);
    var indexList = std.ArrayList(u32).init(allocator);

    const m: *objLoader.ObjMesh = &Objs.meshes.items[0];

    //  only thing i care about right now is normal and position
    for (m.v_faces.items) |f| {
        const face: objLoader.ObjFace = f;

        if (face.count == 3) {
            for (0..face.count) |i| {
                const p = m.v_positions.items[face.vertex[i] - 1];
                const n = m.v_normals.items[face.normal[i] - 1];
                const u = m.v_uvs.items[face.texture[i] - 1];
                const meshVertex: MeshVertex = .{
                    .position = .{ .x = p.x, .y = p.y, .z = p.z },
                    .normal = .{ .x = n.x, .y = n.y, .z = n.z },
                    .color = .{ .r = n.x, .g = n.y, .b = n.z, .a = 1.0 },
                    .uv = .{ .x = u.x, .y = 1 - u.y },
                };

                var index: u32 = @intCast(vertexList.items.len);

                const transmute: MeshVertexTransmute = @bitCast(meshVertex);
                if (vertexMap.get(transmute)) |cachedIndex| {
                    index = cachedIndex;
                } else {
                    try vertexMap.put(transmute, index);
                    try vertexList.append(meshVertex);
                }
                try indexList.append(index);
            }
        }

        if (face.count == 4) {
            const il: []const usize = &.{ 0, 1, 2, 2, 3, 0 };
            for (il) |i| {
                const p = m.v_positions.items[face.vertex[i] - 1];
                const n = m.v_normals.items[face.normal[i] - 1];
                const u = m.v_uvs.items[face.texture[i] - 1];
                const meshVertex: MeshVertex = .{
                    .position = .{ .x = p.x, .y = p.y, .z = p.z },
                    .normal = .{ .x = n.x, .y = n.y, .z = n.z },
                    .color = .{ .r = n.x, .g = n.y, .b = n.z, .a = 1.0 },
                    .uv = .{ .x = u.x, .y = 1 - u.y },
                };

                var index: u32 = @intCast(vertexList.items.len);

                const transmute: MeshVertexTransmute = @bitCast(meshVertex);
                if (vertexMap.get(transmute)) |cachedIndex| {
                    index = cachedIndex;
                } else {
                    try vertexMap.put(transmute, index);
                    try vertexList.append(meshVertex);
                }
                try indexList.append(index);
            }
        }
    }

    const rv: MeshUpdate = .{
        .new = .{
            .vertices = try vertexList.toOwnedSlice(),
            .indices = try indexList.toOwnedSlice(),
            .name = meshName,
        },
    };

    core.graphics_log("[{s}] vertex count vertices={d} indices={d}", .{ path, rv.new.vertices.len, rv.new.indices.len });

    try gMeshPoolBuffer.updateRequests.pushLocked(rv);
}

const objLoader = @import("objLoader");

const vk_allocator = @import("../vk_allocator.zig");
const NeonVkAllocator = vk_allocator.NeonVkAllocator;
const NeonVkBuffer = vk_allocator.NeonVkBuffer;

const mesh = @import("../mesh.zig");
const MeshVertex = mesh.MeshVertex;

const Span = core.Span;
const MergedSpans = core.MergedSpans;

const vk_utils = @import("../vk_utils.zig");
const NeonVkUploader = vk_utils.NeonVkUploader;

const vk_renderer = @import("../vk_renderer.zig");
const NeonVkContext = vk_renderer.NeonVkContext;

const vk_constants = @import("../vk_constants.zig");
const vk_api = @import("../vk_api.zig");
const vkd = vk_api.vkd;
const vki = vk_api.vki;
const vkb = vk_api.vkb;
