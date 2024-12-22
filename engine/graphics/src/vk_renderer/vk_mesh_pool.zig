const std = @import("std");
const vk = @import("vulkan");
const core = @import("core");

pub const MeshPoolCreationSettings = struct {
    vertexCount: u32 = 4_000_000,
    indexCount: u32 = 16_000_000,

    vertexStagingCount: u32 = 100_000,
    indexStagingCount: u32 = 400_000,
};

// should be owned by renderthread
//
// operation per frame
//
// 1. async loading of vertices push model load results into a queue
// 2. these results ar ethen installe dinto the vertex pool

var gMeshPoolBuffer: *MeshPoolBuffers = undefined;

const MeshVertexTransmute = extern struct { data: [@sizeOf(MeshVertex)]u8 };

const MeshPoolBuffers = struct {
    vertexStaging: NeonVkBuffer, // cpu sided vertex staging buffer
    vertexBuffer: NeonVkBuffer, // gpu sided vertex buffer

    indexStaging: NeonVkBuffer, // cpu sided staging buffer
    indexBuffer: NeonVkBuffer, // gpu sided index buffer

    allocator: std.mem.Allocator,
    vkAllocator: *NeonVkAllocator,

    gc: *NeonVkContext,

    uploader: NeonVkUploader,
    updateRequests: core.RingQueue(MeshUpdate),

    const Requests = core.RingQueue(MeshUpdate);

    pub fn create(
        allocator: std.mem.Allocator,
        gc: *NeonVkContext,
        opt: MeshPoolCreationSettings,
    ) !*@This() {
        const self = try allocator.create(@This());
        self.allocator = allocator;
        self.updateRequests = try Requests.init(allocator, 4096);

        self.vertexStaging = try gc.vkAllocator.createStagingBuffer(opt.vertexStagingCount * @sizeOf(MeshVertex), "Mesh Pool staging vertex buffer");
        self.vertexBuffer = try gc.vkAllocator.createStagingBuffer(opt.vertexCount * @sizeOf(MeshVertex), "Mesh Pool gpu vertex buffer");

        self.indexStaging = try gc.vkAllocator.createStagingBuffer(opt.indexStagingCount * @sizeOf(u32), "Mesh Pool staging index buffer");
        self.indexBuffer = try gc.vkAllocator.createStagingBuffer(opt.indexCount * @sizeOf(u32), "Mesh Pool gpu vertex buffer");

        self.gc = gc;
        self.uploader = try NeonVkUploader.init(gc, "Mesh Pool uploader");

        gMeshPoolBuffer = self;

        return self;
    }

    pub fn checkUpdates(self: @This()) !void {
        _ = self;
        // if there is anything in the mesh, upload everything to the uploader and call it a day.
    }

    pub fn destroy(self: *@This()) void {
        {
            self.updateRequests.lock();
            defer self.updateRequests.unlock();
            while (self.updateRequests.popFromUnlocked()) |x| {
                x.deinit(self.allocator);
            }
        }

        self.vertexStaging.deinit(self.gc.vkAllocator);
        self.vertexBuffer.deinit(self.gc.vkAllocator);

        self.indexStaging.deinit(self.gc.vkAllocator);
        self.indexBuffer.deinit(self.gc.vkAllocator);
        self.uploader.deinit();

        self.updateRequests.deinit();
        self.allocator.destroy(self);
    }
};

pub const MeshUpdate = union(enum(u8)) {
    new: struct {
        vertices: []MeshVertex,
        indices: []u32,
    },
    free: struct {
        vertices: Span,
        indices: Span,
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

pub const MeshPool = struct {
    buffers: *MeshPoolBuffers,

    indices: MergedSpans, // spans list of allocated indices
    vertices: MergedSpans, // spans list of allocated vertices

    allocator: std.mem.Allocator,

    pub fn create(allocator: std.mem.Allocator, gc: *NeonVkContext, opts: MeshPoolCreationSettings) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .indices = try MergedSpans.init(allocator, opts.indexCount),
            .vertices = try MergedSpans.init(allocator, opts.vertexCount),
            .buffers = try MeshPoolBuffers.create(allocator, gc, opts),
            .allocator = allocator,
        };
        return self;
    }

    pub fn destroy(self: *@This()) void {
        self.indices.deinit();
        self.vertices.deinit();
        self.buffers.destroy();

        self.allocator.destroy(self);
    }

    pub fn installMesh(self: *@This(), vertices: []MeshVertex, indices: []u32) !PoolMesh {
        const indexSpan = self.indices.allocate(indices.len);
        const vertexSpan = self.vertices.allocate(indices.len);

        const indexSlice = self.getVertexSlice(indexSpan);
        const vertexSlice = self.getVertexSlice(vertexSpan);

        std.mem.copyForwards(MeshVertex, vertexSlice, vertices);
        std.mem.copyForwards(u32, indexSlice, indices);
    }

    // should only ever be updated through the rendering thread.
    pub fn getIndexSlice(self: *@This(), span: Span) []MeshVertex {
        _ = self;
        _ = span;
    }

    pub fn getVertexSlice(self: *@This(), span: Span) []MeshVertex {
        _ = self;
        _ = span;
    }

    pub fn checkUpdates(self: *@This()) void {
        _ = self;
    }
};

pub const PoolMesh = struct {
    vertexSpan: Span,
    indexSpan: Span,
};

pub fn loadIndexedMeshForPooling(path: []const u8) !void {
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

    const rv: MeshUpdate = .{
        .new = .{
            .vertices = try vertexList.toOwnedSlice(),
            .indices = try indexList.toOwnedSlice(),
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
