const std = @import("std");
const vk = @import("vulkan");
const core = @import("core");

// should be owned by renderthread
//
// operation per frame
//
// 1. async loading of vertices push model load results into a queue
// 2. these results ar ethen installe dinto the vertex pool

const MeshPoolBuffers = struct {
    vertexStaging: NeonVkBuffer, // cpu sided vertex staging buffer
    vertexBuffer: NeonVkBuffer, // gpu sided vertex buffer

    indexStaging: NeonVkBuffer, // cpu sided staging buffer
    indexBuffer: NeonVkBuffer, // gpu sided index buffer

    allocator: std.mem.Allocator,

    uploader: NeonVkUploader,
    updateRequests: core.RingQueue(MeshUpdate),

    const Requests = core.RingQueue(MeshUpdate);

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.allocator = allocator;
        self.updateRequests = try Requests.init(allocator);

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
            while (self.updateRequests.popUnlocked()) |x| {
                x.deinit(self.allocator);
            }
        }

        self.updateRequests.deinit();
        self.allocator.destroy(self);
    }
};

pub const MeshUpdate = union(u8) {
    new: struct {
        vertices: []MeshVertex,
        indices: []u32,
        name: core.Name,
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

    pub fn create(allocator: std.mem.Allocator, vertexCapacity: u32, indexCapacity: u32) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .indices = try MergedSpans.init(allocator, indexCapacity),
            .vertices = try MergedSpans.init(allocator, vertexCapacity),
            .buffers = try MeshPoolBuffers.create(allocator),
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

const vk_allocator = @import("../vk_allocator.zig");
const NeonVkAllocator = vk_allocator.NeonVkAllocator;
const NeonVkBuffer = vk_allocator.NeonVkBuffer;

const mesh = @import("../mesh.zig");
const MeshVertex = mesh.MeshVertex;

const Span = core.Span;
const MergedSpans = core.MergedSpans;

const vk_utils = @import("../vk_utils.zig");
const NeonVkUploader = vk_utils.NeonVkUploader;

const vk_constants = @import("../vk_constants.zig");
const vk_api = @import("../vk_api.zig");
const vkd = vk_api.vkd;
const vki = vk_api.vki;
const vkb = vk_api.vkb;
