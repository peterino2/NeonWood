const std = @import("std");
const vk = @import("vulkan");
const resources = @import("resources");
const c = @import("c.zig");
const core = @import("../core.zig");
const VkConstants = @import("vk_constants.zig");
const meshes = @import("mesh.zig");
const NeonVkContext = @import("vk_renderer.zig").NeonVkContext;
const materials = @import("materials.zig");

const Material = materials.Material;
const EulerAngles = core.EulerAngles;
const Mat = core.Mat;
const Vectorf = core.Vectorf;
const Quat = core.Quat;
const zm = core.zm;
const mul = zm.mul;

const Mesh = meshes.Mesh;

pub const RenderObject = struct {
    const Self = @This();
    mesh: ?*Mesh = null,
    material: ?*Material = null,
    texture: ?vk.DescriptorSet = null,
    transform: core.Mat,
    visibility: bool = true,

    // new position and rotator based api
    position: Vectorf,
    rotation: Quat,
    scale: Vectorf,

    // TODO factor this out into a metadata function
    textureName: core.Name = core.NameInvalid,
    meshName: core.Name = core.NameInvalid,

    pub fn fromTransform(transform: core.Mat) Self {
        var self = Self{
            .mesh = null,
            .material = null,
            .texture = null,
            .transform = transform,
            .position = undefined,
            .rotation = undefined,
            .scale = undefined,
        };

        self.updateScalars();

        return self;
    }

    pub fn setMesh(self: *Self, mesh: Mesh) Self {
        self.mesh = mesh;
    }

    pub fn setTextureByName(self: *Self, gc: *NeonVkContext, name: core.Name) void {
        self.texture = gc.textureSets.get(name.handle()).?;
        self.textureName = name;
    }

    pub fn applyTransform(self: *RenderObject, transform: core.Mat) void {
        self.transform = core.zm.mul(self.transform, transform);
        self.updateScalars();
    }

    pub fn applyRelativeRotationX(self: *RenderObject, angle: f32) void {
        var imat = core.zm.identity();
        imat[0][3] = -self.transform[0][3];
        imat[1][3] = -self.transform[1][3];
        imat[2][3] = -self.transform[2][3];

        var rmat = core.zm.identity();
        imat[0][3] = self.transform[0][3];
        imat[1][3] = self.transform[1][3];
        imat[2][3] = self.transform[2][3];

        var newTransform = core.zm.mul(imat, self.transform);
        newTransform = core.zm.mul(core.zm.rotationX(angle), newTransform);
        newTransform = core.zm.mul(rmat, newTransform);
        self.transform = newTransform;
    }

    pub fn applyRelativeRotationZ(self: *RenderObject, angle: f32) void {
        var imat = core.zm.identity();
        imat[0][3] = -self.transform[0][3];
        imat[1][3] = -self.transform[1][3];
        imat[2][3] = -self.transform[2][3];

        var rmat = core.zm.identity();
        imat[0][3] = self.transform[0][3];
        imat[1][3] = self.transform[1][3];
        imat[2][3] = self.transform[2][3];

        var newTransform = core.zm.mul(imat, self.transform);
        newTransform = core.zm.mul(core.zm.rotationZ(angle), newTransform);
        newTransform = core.zm.mul(rmat, newTransform);
        self.transform = newTransform;
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

    pub fn updateScalars(self: *RenderObject) void {
        self.position = Vectorf.fromZm(mul(self.transform, Vectorf.new(0.0, 0.0, 0.0).toZm()));
        self.rotation = zm.matToQuat(self.transform);
        self.scale = core.matToScalef(self.transform);
    }
};

fn makePerspective(fov: f32, aspect: f32, near: f32, far: f32) Mat {
    var proj = core.zm.perspectiveFovRh(
        core.radians(fov),
        aspect,
        near,
        far,
    );
    // proj[1][1] *= -1;
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
        core.radians(70.0), // angle
        16.0 / 9.0,
        0.1,
        200000,
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
        var off: core.Vectorf = offset;
        off.y = offset.y;
        off.x = offset.x;
        off.z = offset.z;
        self.*.position = self.position.add(off);
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
        self.transform = mul(base, zm.matFromQuat(self.rotation));
        self.transform = mul(zm.translationV(self.position.fmul(-1).toZm()), self.transform);
        self.final = mul(self.transform, self.projection);
    }
};
