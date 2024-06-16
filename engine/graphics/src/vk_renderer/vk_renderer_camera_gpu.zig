const std = @import("std");
const core = @import("core");

const render_objects = @import("../render_objects.zig");

const Mat = core.Mat;
const Vectorf = core.Vectorf;

const Camera = render_objects.Camera;

pub const NeonVkCameraDataGpu = struct {
    view: Mat,
    proj: Mat,
    viewproj: Mat,
    position: Vectorf,

    pub fn upload(self: @This(), data: [*]u8) void {
        var dataSlice: []u8 = undefined;
        dataSlice.ptr = data;
        dataSlice.len = @sizeOf(NeonVkCameraDataGpu);

        var inputSlice: []const u8 = undefined;
        inputSlice.ptr = @as([*]const u8, @ptrCast(&self));
        inputSlice.len = @sizeOf(NeonVkCameraDataGpu);

        @memcpy(dataSlice, inputSlice);
    }
};

// generates NeonVkCameraDataGpu and copies it into the buffer
pub fn memcpyCameraDataToStagedBuffer(camera: *const Camera, data: [*]u8) void {
    const projection_matrix: Mat = camera.final;
    const position: Vectorf = camera.position;

    var cameraData = NeonVkCameraDataGpu{
        .proj = core.zm.identity(),
        .view = core.zm.identity(),
        .viewproj = projection_matrix,
        .position = position,
    };

    var dataSlice: []u8 = undefined;
    dataSlice.ptr = data;
    dataSlice.len = @sizeOf(NeonVkCameraDataGpu);

    var inputSlice: []const u8 = undefined;
    inputSlice.ptr = @as([*]const u8, @ptrCast(&cameraData));
    inputSlice.len = @sizeOf(NeonVkCameraDataGpu);

    @memcpy(dataSlice, inputSlice);
}

// upload null to
pub fn uploadNullCameraToBuffer(data: [*]u8) void {
    var cameraData = NeonVkCameraDataGpu{
        .proj = core.zm.identity(),
        .view = core.zm.identity(),
        .viewproj = core.zm.identity(),
        .position = .{},
    };

    var dataSlice: []u8 = undefined;
    dataSlice.ptr = data;
    dataSlice.len = @sizeOf(NeonVkCameraDataGpu);

    var inputSlice: []const u8 = undefined;
    inputSlice.ptr = @as([*]const u8, @ptrCast(&cameraData));
    inputSlice.len = @sizeOf(NeonVkCameraDataGpu);

    @memcpy(dataSlice, inputSlice);
}
