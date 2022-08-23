const std = @import("std");
const vk = @import("vulkan");
const resources = @import("resources");
const c = @import("c.zig");
const core = @import("../core/core.zig");
const VkConstants = @import("vk_constants.zig");
const meshes = @import("mesh.zig");

const EulerAngles = core.EulerAngles;
const Mat = core.Mat;
const Vectorf = core.Vectorf;
const Quat = core.Quat;
const zm = core.zm;
const mul = zm.mul;

const Mesh = meshes.Mesh;

pub const Material = struct {
    textureSet: vk.DescriptorSet = .null_handle,
    pipeline: vk.Pipeline,
    layout: vk.PipelineLayout,
};

pub const RenderObject = struct {
    mesh: ?*Mesh,
    material: ?*Material,
    transform: core.Mat,

    pub fn applyTransform(self: *RenderObject, transform: core.Mat) void {
        self.transform = core.zm.mul(self.transform, transform);
    }

    pub fn applyRelativeRotationY(self: *RenderObject, angle: f32) void {
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

fn makePerspective(fov: f32, aspect: f32, near: f32, far: f32) Mat {
    var proj = core.zm.perspectiveFovRh(
        core.radians(fov),
        aspect,
        near,
        far,
    );
    proj[1][1] *= -1;
    return proj;
}

pub const Camera = struct {
    fov: f32 = 70.0,
    aspect: f32 = 16.0 / 9.0,
    near_clipping: f32 = 0.1,
    far_clipping: f32 = 2000.0,

    fov_cache: f32 = 70.0,
    aspect_cache: f32 = 16.0 / 9.0,
    near_clipping_cache: f32 = 0.1,
    far_clipping_cache: f32 = 2000.0,

    position: Vectorf = Vectorf{ .x = 0.0, .y = 0.0, .z = 0.0 },
    rotation: Quat,
    transform: Mat = zm.identity(),
    projection: Mat = makePerspective(
        core.radians(70.0),
        16.0 / 9.0,
        0.1,
        2000,
    ),
    final: Mat = zm.identity(),

    pub fn isDirty(self: *Camera) bool {
        if (self.fov_cache != self.fov)
            return true;
        if (self.aspect_cache != self.aspect_cache)
            return true;
        if (self.near_clipping != self.near_clipping_cache)
            return true;
        if (self.far_clipping != self.far_clipping_cache)
            return true;

        return false;
    }

    pub fn init() Camera {
        return .{
            .rotation = zm.quatFromRollPitchYaw(0.0, 0.0, 0.0),
        };
    }

    pub fn translate(self: *Camera, offset: core.Vectorf) void {
        self.position = self.position.add(offset);
    }

    pub fn setPositionAndRotationEuler(self: *Camera, position: Vectorf, eulerAngles: Vectorf) void {
        self.transform = mul(zm.translation(position.x, position.y, position.z), core.matFromEulerAngles(eulerAngles.x, eulerAngles.y, eulerAngles.z));
    }

    pub fn getRotation(self: *Camera) Quat {
        return zm.quatFromMat(self.transform);
    }

    pub fn updateCamera(self: *Camera) void {
        self.projection = zm.perspectiveFovRh(core.radians(self.fov), 16.0 / 9.0, 0.1, 2000);
        self.projection[1][1] *= -1;
    }

    pub fn resolve(self: *Camera, base: Mat) void {
        self.transform = mul(zm.translation(self.position.x, self.position.y, self.position.z), base);
        self.transform = mul(self.transform, zm.matFromQuat(self.rotation));
        self.final = mul(self.transform, self.projection);
    }
};
