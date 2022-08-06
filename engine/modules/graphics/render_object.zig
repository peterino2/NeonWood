const std = @import("std");
const vk = @import("vulkan");
const resources = @import("resources");
const c = @import("c.zig");
const core = @import("../core/core.zig");
const VkConstants = @import("vk_constants.zig");
const meshes = @import("mesh.zig");
const EulerAngles = core.EulerAngles;

const Mesh = meshes.Mesh;

pub const Material = struct {
    pipeline: vk.Pipeline,
    layout: vk.PipelineLayout,
};

pub const RenderObject = struct {
    mesh: ?*Mesh,
    material: ?*Material,
    transform: core.Mat,

    pub fn applyTransform(self : *RenderObject, transform: core.Mat) void 
    {
        self.transform = core.zm.mul(self.transform, transform);
    }

    pub fn applyRelativeRotationY(self : *RenderObject, angle: f32) void 
    {
        var imat = core.zm.identity();
        imat[0][3] = -self.transform[0][3];
        imat[1][3] = -self.transform[1][3];
        imat[2][3] = -self.transform[2][3];

        var rmat = core.zm.identity();
        imat[0][3] = self.transform[0][3];
        imat[1][3] = self.transform[1][3];
        imat[2][3] = self.transform[2][3];


        var newTransform = core.zm.mul(imat, self.transform);
        newTransform = core.zm.mul(core.zm.rotationY(angle), newTransform);
        newTransform = core.zm.mul(rmat, newTransform);
        self.transform = newTransform;
    }
};
