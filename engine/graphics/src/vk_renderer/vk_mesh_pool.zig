const std = @import("std");
const vk = @import("vulkan");
const core = @import("core");
const zgltf = core.zgltf;

pub const MeshPoolCreationSettings = struct {
    vertexCount: u32 = 4_000_000,
    indexCount: u32 = 16_000_000,
};

pub const MeshUpdate = union(enum(u8)) {
    new: struct {
        vertices: []MeshVertex,
        indices: []u32,
        jointNames: []JointNameEntry,
        name: core.Name,
        skeletonName: ?core.Name,
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
                for (new.jointNames) |entry| {
                    entry.deinit();
                }
                allocator.free(new.jointNames);
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
// 2. these results ar ethen installed into the vertex pool

var gMeshPoolBuffer: *MeshPoolBuffers = undefined;

const MeshVertexTransmute = extern struct { data: [@sizeOf(MeshVertex)]u8 };

pub const IndexedMesh = struct {
    vertex: Span,
    index: Span,
    name: core.Name,
    jointRemap: ?[]u8, // this is NOT a string, they're joint indices.. which happen to be u8s
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
    jointMaps: std.AutoHashMapUnmanaged(u32, JointMapEntry),

    const JointMapEntry = std.AutoHashMapUnmanaged(u32, u32);

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
        self.jointMaps = .{};

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

                    var jointMap: JointMapEntry = .{};

                    for (new.jointNames) |entry| {
                        core.engine_log("gtlf bone found {s} -> {d}", .{ entry.name, entry.index });
                        try jointMap.put(self.allocator, core.MakeName(entry.name).handle(), entry.index);
                    }

                    try gMeshPoolBuffer.jointMaps.put(self.allocator, new.name.handle(), jointMap);

                    var jointRemap: ?[]u8 = null;

                    if (new.skeletonName) |skName| {
                        if (animationSystem.getSkeletonByName(skName)) |sk| {
                            // build the joint remap
                            // this is a map from ozz's index to gltf's index
                            var iter = sk.jointMapping.iterator();
                            jointRemap = try graphics.getContext().allocator.alloc(u8, sk.jointMapping.count());

                            while (iter.next()) |i| {
                                const jointName = i.key_ptr.*;
                                const ozzIndex = i.value_ptr.*;
                                var gltfIndex = jointMap.get(core.MakeName(jointName).handle());
                                if (gltfIndex == null) {
                                    gltfIndex = 0;
                                    core.engine_log("ERROR REMAPPING BONE setting to zero {s}", .{jointName});
                                }

                                core.engine_log("remapping bone from {s} ozz {d} -> {d} gltf", .{ jointName, ozzIndex, gltfIndex.? });

                                jointRemap.?[ozzIndex] = @intCast(gltfIndex.?);
                            }
                        }
                    }

                    gMeshPoolBuffer.vertexMapLock.lock();
                    try gMeshPoolBuffer.vertexMap.put(self.allocator, new.name.handle(), .{ .index = indexSpan, .vertex = vertexSpan, .name = new.name, .jointRemap = jointRemap });

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

        {
            var iter = self.vertexMap.valueIterator();
            while (iter.next()) |p| {
                if (p.jointRemap) |jr| {
                    graphics.getContext().allocator.free(jr);
                }
            }
        }
        self.vertexMap.deinit(self.allocator);
        self.indexSpans.deinit();
        self.vertexSpans.deinit();
        {
            var iter = self.jointMaps.valueIterator();
            while (iter.next()) |p| {
                p.deinit(self.allocator);
            }
        }

        self.jointMaps.deinit(self.allocator);

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

pub const MeshSourceType = enum { obj, gltf };

pub const LoadMeshSettings = struct {
    path: []const u8,
    sourceType: ?MeshSourceType = null,
    skeletonName: ?core.Name,
};

pub fn loadIndexedMeshForPooling(meshName: core.Name, opt: LoadMeshSettings) !void {
    var sourceType = MeshSourceType.gltf;
    if (opt.sourceType) |st| {
        sourceType = st;
    }

    // check if we have a cooked version of that file, if so just load that instead.

    // otherwise, load the file
    switch (sourceType) {
        .obj => {
            try loadIndexedMeshForPoolingObj(meshName, opt.path);
        },
        .gltf => {
            try loadIndexedMeshForPoolingGltf(meshName, opt.skeletonName, opt.path);
        },
    }
}

pub fn loadIndexedMeshForPoolingGltf(meshName: core.Name, skeletonName: ?core.Name, path: []const u8) !void {
    const file = try core.fs().loadFile(path);
    defer core.fs().unmap(file);

    const allocator = gMeshPoolBuffer.allocator;

    var parser = zgltf.init(allocator);
    defer parser.deinit();

    const ext = core.getFileExtension(path);
    if (std.mem.eql(u8, ".gltf", ext)) {
        try parser.parse(@alignCast(file.bytes[0 .. file.bytes.len - 1]));
    } else {
        try parser.parse(@alignCast(file.bytes));
    }

    // std.debug.print("\n", .{});
    // parser.debugPrint();

    if (parser.data.meshes.items.len > 1) {
        return error.OnlyOneMeshPerGltfImplemented;
    }

    if (parser.data.skins.items.len > 1) {
        return error.TooManySkins;
    }

    var binaryFile: ?core.packer.PackerBytesMapping = null;
    var binaryBytes: []const u8 = undefined;

    if (std.mem.eql(u8, ext, ".glb")) {
        binaryBytes = parser.glb_binary.?;
    } else {
        const binaryPath = try std.fmt.allocPrint(allocator, "{s}bin", .{path[0 .. path.len - 4]});
        defer allocator.free(binaryPath);
        core.engine_log("{s}", .{binaryPath});
        binaryFile = try core.fs().loadFile(binaryPath);
        binaryBytes = binaryFile.?.bytes;
    }

    defer if (binaryFile) |f| core.fs().unmap(f);

    const m = parser.data.meshes.items[0];
    core.engine_log("mesh name {s} number of primitives = {d}", .{ m.name, m.primitives.items.len });

    var positions = std.ArrayList(f32).init(allocator);
    defer positions.deinit();

    var texcoords = std.ArrayList(f32).init(allocator);
    defer texcoords.deinit();

    var normals = std.ArrayList(f32).init(allocator);
    defer normals.deinit();

    var joints = std.ArrayList(u16).init(allocator);
    defer joints.deinit();
    // add a different joint format one, todo- i need to fix up zgltf

    var useJoints8: bool = false;
    var joints8 = std.ArrayList(u8).init(allocator);
    defer joints8.deinit();

    var weights = std.ArrayList(f32).init(allocator);
    defer weights.deinit();

    var weightCount: usize = 4;

    if (m.prmitives.items.len > 1) {
        @panic("sorry, havent implemented support for multiple primitives yet, would require more work on the way i handle materials");
    }

    var indexList = std.ArrayList(u32).init(allocator);
    for (m.primitives.items) |primitive| {
        if (primitive.indices) |indices| {
            const accessor = parser.data.accessors.items[indices];
            core.engine_log("index accessor info: {any}", .{accessor});

            if (accessor.component_type == .unsigned_short) {
                var temp = std.ArrayList(u16).init(allocator);
                defer temp.deinit();
                parser.getDataFromBufferView(u16, &temp, accessor, @alignCast(binaryBytes));
                for (temp.items) |t| {
                    try indexList.append(@intCast(t));
                }
            } else if (accessor.component_type == .unsigned_integer) {
                parser.getDataFromBufferView(u32, &indexList, accessor, @alignCast(binaryBytes));
            }
        }

        for (primitive.attributes.items) |attribute| {
            core.engine_log("attribute: {any}", .{attribute});

            switch (attribute) {
                .position => |x| {
                    const accessor = parser.data.accessors.items[x];
                    core.engine_log("accessor info: {any}", .{accessor});

                    parser.getDataFromBufferView(f32, &positions, accessor, @alignCast(binaryBytes));
                    core.engine_log("positions loaded: {d}", .{positions.items.len});
                },
                .normal => |x| {
                    const accessor = parser.data.accessors.items[x];
                    core.engine_log("accessor info: {any}", .{accessor});

                    parser.getDataFromBufferView(f32, &normals, accessor, @alignCast(binaryBytes));
                    core.engine_log("normals loaded: {d}", .{normals.items.len});
                },
                .texcoord => |x| {
                    const accessor = parser.data.accessors.items[x];
                    core.engine_log("accessor info: {any}", .{accessor});

                    parser.getDataFromBufferView(f32, &texcoords, accessor, @alignCast(binaryBytes));
                    core.engine_log("texcoords loaded: {d}", .{texcoords.items.len});
                },
                .joints => |x| {
                    const accessor = parser.data.accessors.items[x];
                    core.engine_log("accessor info: {any} acecssor index {d}", .{ accessor, x });

                    if (accessor.component_type == .unsigned_byte) {
                        useJoints8 = true;
                        parser.getDataFromBufferView(u8, &joints8, accessor, @alignCast(binaryBytes));
                        core.engine_log("joints8 loaded: {d} - {d} {d} {d} {d}", .{
                            joints8.items.len,
                            joints8.items[0],
                            joints8.items[1],
                            joints8.items[2],
                            joints8.items[3],
                        });
                    } else {
                        parser.getDataFromBufferView(u16, &joints, accessor, @alignCast(binaryBytes));
                        core.engine_log("joints loaded: {d} - {d} {d} {d} {d}", .{
                            joints.items.len,
                            joints.items[0],
                            joints.items[1],
                            joints.items[2],
                            joints.items[3],
                        });
                    }
                },
                .weights => |x| {
                    const accessor = parser.data.accessors.items[x];
                    core.engine_log("accessor info: {any}", .{accessor});

                    parser.getDataFromBufferView(f32, &weights, accessor, @alignCast(binaryBytes));

                    if (accessor.type == .vec3) {
                        weightCount = 3;
                    }

                    core.engine_log("weights loaded: {d} - {d} {d} {d} {d}", .{
                        weights.items.len,
                        weights.items[0],
                        weights.items[1],
                        weights.items[2],
                        weights.items[3],
                    });
                },
                .tangent => |x| {
                    const accessor = parser.data.accessors.items[x];
                    core.engine_log("accessor info: {any} NOT PARSED", .{accessor});
                },
                .color => |x| {
                    const accessor = parser.data.accessors.items[x];
                    core.engine_log("accessor info: {any} NOT PARSED", .{accessor});
                },
            }
        }
    }

    if (parser.data.skins.items.len > 1) {
        @panic("too many skins, not supported");
    }

    var jointNameList: std.ArrayList(JointNameEntry) = std.ArrayList(JointNameEntry).init(allocator);

    if (weights.items.len > 0) {
        core.engine_log("skin found, building joint map", .{});
        if (parser.data.skins.items[0].skeleton) |skeletonIndex| {
            for (parser.data.nodes.items[skeletonIndex..], 0..) |node, i| {
                core.engine_log("gltf: {s} -> {d} (skeleton index)", .{ node.name, i });
                const gcAllocator = graphics.getContext().allocator;
                try jointNameList.append(.{ .index = @intCast(i), .name = try gcAllocator.dupe(u8, node.name) });
            }
        } else {
            if (parser.data.skins.items[0].joints.items.len > 0) {
                for (parser.data.skins.items[0].joints.items, 0..) |i, j| {
                    const node = parser.data.nodes.items[i];
                    core.engine_log("gltf: {s} -> {d} (joints map)", .{ node.name, j });
                    const gcAllocator = graphics.getContext().allocator;
                    try jointNameList.append(.{ .index = @intCast(j), .name = try gcAllocator.dupe(u8, node.name) });
                }
            } else {
                for (parser.data.nodes.items, 0..) |node, i| {
                    core.engine_log("gltf: {s} -> {d} (fallback)", .{ node.name, i });
                    const gcAllocator = graphics.getContext().allocator;
                    try jointNameList.append(.{ .index = @intCast(i), .name = try gcAllocator.dupe(u8, node.name) });
                }
            }
        }
    }

    var vertexList = std.ArrayList(MeshVertex).init(allocator);

    var i: usize = 0;
    const vertexCount = positions.items.len / 3;
    while (i < vertexCount) : (i += 1) {
        const normalIndex = i * 3;
        const positionIndex = i * 3;
        const uvIndex = i * 2;

        const uv: core.Vector2f = if (uvIndex < texcoords.items.len) .{
            .x = texcoords.items[uvIndex],
            .y = texcoords.items[uvIndex + 1],
        } else core.Vector2f{};

        const normal = if (normalIndex < normals.items.len) core.Vectorf{
            .x = normals.items[i],
            .y = normals.items[i + 1],
            .z = normals.items[i + 2],
        } else core.Vectorf{};

        try vertexList.append(.{
            .position = .{
                .x = positions.items[positionIndex],
                .y = positions.items[positionIndex + 1],
                .z = positions.items[positionIndex + 2],
            },
            .normal = normal,
            .color = .{},
            .uv = uv,
        });

        const jointsIndex = weightCount * i;
        if (weightCount == 4) {
            if (useJoints8) {
                if (jointsIndex < joints8.items.len) {
                    vertexList.items[vertexList.items.len - 1].bones = .{
                        @intCast(joints8.items[jointsIndex + 0]),
                        @intCast(joints8.items[jointsIndex + 1]),
                        @intCast(joints8.items[jointsIndex + 2]),
                        @intCast(joints8.items[jointsIndex + 3]),
                    };
                    vertexList.items[vertexList.items.len - 1].weights = .{
                        @intFromFloat(weights.items[jointsIndex + 0] * 255),
                        @intFromFloat(weights.items[jointsIndex + 1] * 255),
                        @intFromFloat(weights.items[jointsIndex + 2] * 255),
                        @intFromFloat(weights.items[jointsIndex + 3] * 255),
                    };
                }
            } else {
                if (jointsIndex < joints.items.len) {
                    vertexList.items[vertexList.items.len - 1].bones = .{
                        @intCast(joints.items[jointsIndex + 0]),
                        @intCast(joints.items[jointsIndex + 1]),
                        @intCast(joints.items[jointsIndex + 2]),
                        @intCast(joints.items[jointsIndex + 3]),
                    };
                    vertexList.items[vertexList.items.len - 1].weights = .{
                        @intFromFloat(weights.items[jointsIndex + 0] * 255),
                        @intFromFloat(weights.items[jointsIndex + 1] * 255),
                        @intFromFloat(weights.items[jointsIndex + 2] * 255),
                        @intFromFloat(weights.items[jointsIndex + 3] * 255),
                    };
                }
            }
        } else {
            return error.NotImplementedYet;
        }
    }

    if (indexList.items.len == 0) {
        for (0..vertexList.items.len) |x| {
            try indexList.append(@intCast(x));
        }
    }

    const rv: MeshUpdate = .{
        .new = .{
            .vertices = try vertexList.toOwnedSlice(),
            .indices = try indexList.toOwnedSlice(),
            .jointNames = try jointNameList.toOwnedSlice(),
            .skeletonName = skeletonName,
            .name = meshName,
        },
    };

    core.graphics_log("[{s}] gltf loaded vertex count vertices={d} indices={d}", .{ path, rv.new.vertices.len, rv.new.indices.len });

    try gMeshPoolBuffer.updateRequests.pushLocked(rv);

    // return error.NotImplementedYet;

    // var vertexList = std.ArrayList(MeshVertex).init(allocator);
    // var indexList = std.ArrayList(u32).init(allocator);

    // const rv: MeshUpdate = .{
    //     .new = .{
    //         .vertices = try vertexList.toOwnedSlice(),
    //         .indices = try indexList.toOwnedSlice(),
    //         .name = meshName,
    //     },
    // };

    // core.graphics_log("[{s}] vertex count vertices={d} indices={d}", .{ path, rv.new.vertices.len, rv.new.indices.len });

    // try gMeshPoolBuffer.updateRequests.pushLocked(rv);
}

pub fn loadIndexedMeshForPoolingObj(meshName: core.Name, path: []const u8) !void {
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

    var jointNames = std.ArrayList(JointNameEntry).init(allocator);

    const rv: MeshUpdate = .{
        .new = .{
            .vertices = try vertexList.toOwnedSlice(),
            .indices = try indexList.toOwnedSlice(),
            .jointNames = try jointNames.toOwnedSlice(),
            .skeletonName = null,
            .name = meshName,
        },
    };

    core.graphics_log("[{s}] vertex count vertices={d} indices={d}", .{ path, rv.new.vertices.len, rv.new.indices.len });

    try gMeshPoolBuffer.updateRequests.pushLocked(rv);
}

pub const JointNameEntry = struct {
    name: []u8 = undefined,
    index: u32 = 0,

    pub fn deinit(self: @This()) void {
        const allocator = graphics.getContext().allocator;
        allocator.free(self.name);
    }
};

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

const animationSystem = @import("../animation/animationSystem.zig");
const vk_constants = @import("../vk_constants.zig");
const vk_api = @import("../vk_api.zig");
const vkd = vk_api.vkd;
const vki = vk_api.vki;
const vkb = vk_api.vkb;
const graphics = @import("../graphics.zig");
