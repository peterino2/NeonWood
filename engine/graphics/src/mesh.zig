const std = @import("std");
const core = @import("core");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const obj_loader = @import("objLoader");
const constants = @import("vk_constants.zig");
const vk_utils = @import("vk_utils.zig");

const vk_dynamic_mesh = @import("vk_dynamic_mesh.zig");

const NeonVkUploader = vk_utils.NeonVkUploader;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;
const ObjMesh = obj_loader.ObjMesh;
const ArrayList = std.ArrayList;
const Vectorf = core.Vectorf;
const Vector2f = core.Vector2f;
const Color = core.colors.Color;
const NeonVkContext = vk_renderer.NeonVkContext;

const debug_struct = core.debug_struct;

pub const DynamicMesh = vk_dynamic_mesh.DynamicMesh;
pub const DynamicMeshManager = vk_dynamic_mesh.DynamicMeshManager;

pub const MeshVertex = extern struct {
    position: Vectorf = .{},
    normal: Vectorf = .{},
    color: Color = .{},
    uv: Vector2f = .{},
    skeletal: u32 = 0,
    pad: u32 = undefined,
};

pub const IndexBuffer = struct {
    buffer: NeonVkBuffer,
    indices: []const u32,
    allocator: std.mem.Allocator,

    pub fn uploadIndexBuffer(gc: *NeonVkContext, indices: []const u32, allocator: std.mem.Allocator) !@This() {
        var self = @This(){
            .buffer = undefined,
            .indices = indices,
            .allocator = allocator,
        };

        self.indices = try allocator.dupe(u32, indices);

        const bufferSize = indices.len * @sizeOf(u32);

        const bci = vk.BufferCreateInfo{
            .flags = .{},
            .size = bufferSize,
            .usage = .{ .transfer_src_bit = true },
            .sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = undefined,
        };

        const vmaCreateInfo = vma.AllocationCreateInfo{
            .flags = .{},
            .usage = .cpuOnly,
        };

        var stagingBuffer = try gc.vkAllocator.createBuffer(bci, vmaCreateInfo, @src().fn_name ++ " - upload buffer");
        defer stagingBuffer.deinit(gc.vkAllocator);

        {
            const data = try gc.vkAllocator.vmaAllocator.mapMemory(stagingBuffer.allocation, u8);
            var dataSlice: []u8 = undefined;
            dataSlice.ptr = data;
            dataSlice.len = bufferSize;

            var iSlice: []const u8 = undefined;
            iSlice.ptr = @as([*]const u8, @ptrCast(indices.ptr));
            iSlice.len = bufferSize;

            @memcpy(dataSlice, iSlice);
            gc.vkAllocator.vmaAllocator.unmapMemory(stagingBuffer.allocation);
        }

        // GPU sided buffer

        const gpuBci = vk.BufferCreateInfo{
            .flags = .{},
            .size = bufferSize,
            .usage = .{ .transfer_dst_bit = true, .index_buffer_bit = true },
            .sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = undefined,
        };

        const gpuVmaCreateInfo = vma.AllocationCreateInfo{
            .flags = .{},
            .usage = .gpuOnly,
        };

        self.buffer = try gc.vkAllocator.createBuffer(gpuBci, gpuVmaCreateInfo, @src().fn_name ++ " - gpu buffer");
        //try gc.start_upload_context(&gc.uploadContext);
        try gc.uploader.startUploadContext();
        {
            var copy = vk.BufferCopy{
                .dst_offset = 0,
                .src_offset = 0,
                .size = bufferSize,
            };

            const cmd = gc.uploader.commandBuffer;
            // core.graphics_log("Starting command copy buffer", .{});

            gc.vkd.cmdCopyBuffer(
                cmd,
                stagingBuffer.buffer,
                self.buffer.buffer,
                1,
                @as([*]const vk.BufferCopy, @ptrCast(&copy)),
            );
        }

        //try gc.finish_upload_context(&gc.uploadContext);
        try gc.uploader.finishUploadContext();

        return self;
    }

    pub fn deinit(self: *@This(), gc: *NeonVkContext) void {
        self.buffer.deinit(gc.vkAllocator);
        self.allocator.free(self.indices);
    }
};

pub fn loadObjMeshVertices(vertices: *ArrayList(MeshVertex), mesh: ObjMesh) !void {
    try mesh.validate_mesh();

    try vertices.ensureTotalCapacity(mesh.v_faces.items.len * 3);

    for (mesh.v_faces.items) |face| {
        if (face.count == 3) {
            var i: u32 = 0;
            while (i < 3) : (i += 1) {
                const v = vertexFromFaceOffset(mesh, face, i);
                try vertices.append(v);
            }
        } else if (face.count == 4) {
            const vx = [_]MeshVertex{
                vertexFromFaceOffset(mesh, face, 0),
                vertexFromFaceOffset(mesh, face, 1),
                vertexFromFaceOffset(mesh, face, 2),
                vertexFromFaceOffset(mesh, face, 2),
                vertexFromFaceOffset(mesh, face, 3),
                vertexFromFaceOffset(mesh, face, 0),
            };

            try vertices.appendSlice(vx[0..]);
        }
    }
}

fn vertexFromFaceOffset(mesh: ObjMesh, face: obj_loader.ObjFace, offset: u32) MeshVertex {
    const p = mesh.v_positions.items[face.vertex[offset] - 1];
    const n = mesh.v_normals.items[face.normal[offset] - 1];
    const u = mesh.v_uvs.items[face.texture[offset] - 1];
    const v = MeshVertex{
        .position = .{ .x = p.x, .y = p.y, .z = p.z },
        .normal = .{ .x = n.x, .y = n.y, .z = n.z },
        .color = .{ .r = n.x, .g = n.y, .b = n.z, .a = 1.0 },
        .uv = .{ .x = u.x, .y = 1 - u.y },
    };

    return v;
}

pub const Mesh = struct {
    vertices: ArrayList(MeshVertex),
    buffer: NeonVkBuffer,
    allocator: std.mem.Allocator,

    pub fn init(context: *NeonVkContext, allocator: std.mem.Allocator) Mesh {
        const self = Mesh{
            .vertices = ArrayList(MeshVertex).init(allocator),
            .buffer = undefined,
            .allocator = allocator,
        };
        _ = context;
        return self;
    }

    pub fn upload(self: *Mesh, ctx: *NeonVkContext) !void {
        try ctx.stage_and_push_mesh(self);
    }

    pub fn loadFromObjFileCooked(self: *Mesh, fileName: []const u8) !void {
        const mapping = try core.fs().loadFile(fileName);
        defer core.fs().unmap(mapping);
        const s = @sizeOf(MeshVertex);

        var i: usize = 0;
        var vertexOffset: usize = 0;
        try self.vertices.resize(1 + mapping.bytes.len / s);
        while (i < mapping.bytes.len) : (i += s) {
            self.vertices.items[vertexOffset] = @as(*const MeshVertex, @ptrCast(@alignCast(mapping.bytes.ptr + i))).*;
            vertexOffset += 1;
        }
    }

    pub fn load_from_obj_file(self: *Mesh, fileName: []const u8) !void {
        const mapping = try core.fs().loadFile(fileName);
        defer core.fs().unmap(mapping);
        var fileObjs = try obj_loader.loadObjBytes(mapping.bytes, self.allocator);
        defer fileObjs.deinit();

        if (fileObjs.meshes.items.len > 0) {
            // default grabbing shape zero
            core.graphics_log("loading mesh: {s}", .{fileName});
            // fileObjs.meshes.items[0].print_stats();
            // try self.load_from_obj_mesh(fileObjs.meshes.items[0]);
            try loadObjMeshVertices(&self.vertices, fileObjs.meshes.items[0]);
        }
    }

    pub fn deinit(self: *Mesh, ctx: *NeonVkContext) void {
        self.buffer.deinit(ctx.vkAllocator);
        self.vertices.deinit();
    }
};

pub const VertexInputDescription = struct {
    bindings: ArrayList(vk.VertexInputBindingDescription),
    attributes: ArrayList(vk.VertexInputAttributeDescription),
    flags: vk.PipelineVertexInputStateCreateFlags = .{},

    pub fn init(allocator: std.mem.Allocator) !VertexInputDescription {
        var self = VertexInputDescription{
            .bindings = ArrayList(vk.VertexInputBindingDescription).init(allocator),
            .attributes = ArrayList(vk.VertexInputAttributeDescription).init(allocator),
        };

        try self.bindings.append(.{
            .binding = 0,
            .stride = @sizeOf(MeshVertex),
            .input_rate = .vertex,
        });

        //debug_struct("bindings 0", self.bindings.items[0]);

        // position
        try self.attributes.append(.{
            .binding = 0,
            .location = 0,
            .format = .r32g32b32_sfloat,
            .offset = @offsetOf(MeshVertex, "position"),
        });
        //debug_struct("attributes 0", self.attributes.items[0]);

        // normal
        try self.attributes.append(.{
            .binding = 0,
            .location = 1,
            .format = .r32g32b32_sfloat,
            .offset = @offsetOf(MeshVertex, "normal"),
        });

        //debug_struct("attributes 0", self.attributes.items[1]);
        // color
        try self.attributes.append(.{
            .binding = 0,
            .location = 2,
            .format = .r32g32b32a32_sfloat,
            .offset = @offsetOf(MeshVertex, "color"),
        });

        //debug_struct("attributes 0", self.attributes.items[2]);
        try self.attributes.append(.{
            .binding = 0,
            .location = 3,
            .format = .r32g32_sfloat,
            .offset = @offsetOf(MeshVertex, "uv"),
        });

        try self.attributes.append(.{
            .binding = 0,
            .location = 4,
            .format = .r8_uint,
            .offset = @offsetOf(MeshVertex, "skeletal"),
        });

        return self;
    }

    pub fn deinit(self: *@This()) void {
        self.bindings.deinit();
        self.attributes.deinit();
    }
};
