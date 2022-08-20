const std = @import("std");
const core = @import("../core/core.zig");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const obj_loader = @import("lib/objLoader/obj_loader.zig");

const ObjMesh = obj_loader.ObjMesh;
const ArrayList = std.ArrayList;
const Vectorf = core.Vectorf;
const NeonVkContext = vk_renderer.NeonVkContext;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;

const debug_struct = core.debug_struct;

pub const Vertex = struct {
    position: Vectorf,
    normal: Vectorf,
    color: core.LinearColor,
};

pub const Mesh = struct {
    vertices: ArrayList(Vertex),
    buffer: NeonVkBuffer,
    allocator: std.mem.Allocator,

    pub fn init(context: *NeonVkContext, allocator: std.mem.Allocator) Mesh {
        var self = Mesh{
            .vertices = ArrayList(Vertex).init(allocator),
            .buffer = undefined,
            .allocator = allocator,
        };
        _ = context;
        return self;
    }

    pub fn upload(self: *Mesh, ctx: *NeonVkContext) !void {
        try ctx.stage_and_push_mesh(self);
        //self.buffer = try ctx.upload_mesh(self);
    }

    pub fn load_from_obj_file(self: *Mesh, filename: []const u8) !void {
        var fileContents = try obj_loader.loadObj(filename, self.allocator);
        defer fileContents.deinit();

        if (fileContents.meshes.items.len > 0) {
            // default grabbing shape zero
            core.graphics_log("loading mesh: ", .{});
            fileContents.meshes.items[0].print_stats();
            try self.load_from_obj_mesh(fileContents.meshes.items[0]);
        }
    }

    pub fn load_from_obj_mesh(self: *Mesh, mesh: ObjMesh) !void {
        try mesh.validate_mesh();

        try self.vertices.ensureTotalCapacity(mesh.v_faces.items.len * 3);

        for (mesh.v_faces.items) |face| {
            if (face.count == 3) {
                var i: u32 = 0;
                while (i < 3) : (i += 1) {
                    const p = mesh.v_positions.items[face.vertex[i] - 1];
                    const n = mesh.v_normals.items[face.normal[i] - 1];
                    const v = Vertex{
                        .position = .{ .x = p.x, .y = p.y, .z = p.z },
                        .normal = .{ .x = n.x, .y = n.y, .z = n.z },
                        .color = .{ .r = n.x, .g = n.y, .b = n.z, .a = 1.0 },
                    };
                    try self.vertices.append(v);
                }
            } else {
                return error.OnlyTrianglesAreSupportedRightNow;
            }
        }
    }

    pub fn deinit(self: *Mesh, ctx: *NeonVkContext) void {
        self.buffer.deinit(ctx.vmaAllocator);
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
            .stride = @sizeOf(Vertex),
            .input_rate = .vertex,
        });

        //debug_struct("bindings 0", self.bindings.items[0]);

        // position
        try self.attributes.append(.{
            .binding = 0,
            .location = 0,
            .format = .r32g32b32_sfloat,
            .offset = @offsetOf(Vertex, "position"),
        });
        //debug_struct("attributes 0", self.attributes.items[0]);

        // normal
        try self.attributes.append(.{
            .binding = 0,
            .location = 1,
            .format = .r32g32b32_sfloat,
            .offset = @offsetOf(Vertex, "normal"),
        });

        //debug_struct("attributes 0", self.attributes.items[1]);
        // color
        try self.attributes.append(.{
            .binding = 0,
            .location = 2,
            .format = .r32g32b32a32_sfloat,
            .offset = @offsetOf(Vertex, "color"),
        });
        //debug_struct("attributes 0", self.attributes.items[2]);

        return self;
    }

    pub fn deinit(self: *@This()) void {
        self.bindings.deinit();
        self.attributes.deinit();
    }
};
