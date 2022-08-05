const std = @import("std");
const vk = @import("vulkan");
const resources = @import("resources");
const c = @import("c.zig");
const core = @import("../core/core.zig");
const VkConstants = @import("vk_constants.zig");
const meshes = @import("mesh.zig");

const Mesh = meshes.Mesh;

pub const Material = struct {
    pipeline: vk.Pipeline,
    layout: vk.PipelineLayout,
};

pub const RenderObject = struct {
    mesh: ?*Mesh,
    Material: ?*Material,
    transform: core.Mat,
};
