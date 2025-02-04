pub fn hello() void {
    std.debug.print("whatsup\n", .{});
}

pub const Skeleton = opaque {
    pub fn create() *@This() {
        return @ptrCast(CreateSkeleton_c());
    }

    // todo add error messages
    pub fn loadFromFile(self: *@This(), path: [*c]const u8) void {
        LoadSkeletonFromFile_c(self, path);
    }

    pub fn loadFromBytes(self: *@This(), bytes: []const u8) void {
        LoadSkeletonFromBytes_c(self, @constCast(@ptrCast(bytes.ptr)), bytes.len);
    }

    pub fn getJointsList(self: *@This()) []const [*c]const u8 {
        const span: Span([*c]const u8) = @bitCast(SkeletonGetJointsList_c(@ptrCast(self)));

        // std.debug.print("{d} \n", .{@intFromPtr(span.end)});
        return span.toSlice();
    }

    pub fn getRestPoseModel(self: *@This()) Span(SoaTransform) {
        return @bitCast(SkeletonJointRestPoses_c(@ptrCast(self)));
    }

    pub fn numSoaJoints(self: *@This()) usize {
        return @intCast(SkeletonNumSoaJoints_c(@ptrCast(self)));
    }

    pub fn numJoints(self: *@This()) usize {
        return @intCast(SkeletonNumJoints_c(@ptrCast(self)));
    }

    pub fn destroy(self: *@This()) void {
        DestroySkeleton_c(@ptrCast(self));
    }

    pub extern fn SkeletonJointRestPoses_c(s: ?*anyopaque) callconv(.C) OpaqueSpan;
    pub extern fn SkeletonNumJoints_c(s: ?*anyopaque) callconv(.C) c_int;
    pub extern fn SkeletonNumSoaJoints_c(s: ?*anyopaque) callconv(.C) c_int;
    pub extern fn SkeletonGetJointsList_c(s: ?*anyopaque) callconv(.C) OpaqueSpan;

    pub extern fn CreateSkeleton_c() callconv(.C) ?*anyopaque;
    pub extern fn DestroySkeleton_c(target: ?*anyopaque) callconv(.C) void;
    pub extern fn LoadSkeletonFromFile_c(s: ?*anyopaque, path: [*c]const u8) callconv(.C) void;
    pub extern fn LoadSkeletonFromBytes_c(s: ?*anyopaque, size: ?*anyopaque, size: usize) void;
};

pub const Animation = opaque {
    pub fn create() *@This() {
        return @ptrCast(CreateAnimation_c());
    }

    // todo add error messages
    pub fn loadFromFile(self: *@This(), path: [*c]const u8) void {
        LoadAnimationFromFile_c(self, path);
    }

    pub fn loadFromBytes(self: *@This(), bytes: []const u8) void {
        LoadAnimationFromBytes_c(self, @constCast(@ptrCast(bytes.ptr)), bytes.len);
    }

    pub fn destroy(self: *@This()) void {
        DestroyAnimation_c(@ptrCast(self));
    }

    pub fn getDuration(self: *@This()) f32 {
        return AnimationGetDuration_c(@ptrCast(self));
    }

    pub extern fn AnimationGetDuration_c(s: ?*anyopaque) callconv(.C) f32;
    pub extern fn CreateAnimation_c() callconv(.C) ?*anyopaque;
    pub extern fn LoadAnimationFromFile_c(s: ?*anyopaque, path: [*c]const u8) void;
    pub extern fn LoadAnimationFromBytes_c(s: ?*anyopaque, size: ?*anyopaque, size: usize) void;
    pub extern fn DestroyAnimation_c(target: ?*anyopaque) callconv(.C) void;
};

pub const SamplingJob = extern struct {
    ratio: f32 = 0.0, // float ratio;
    animation: ?*Animation = undefined, // const Animation* animation;
    context: ?*SamplingJobContext = undefined, //
    output: Span(SoaTransform) = .{}, // ozz::span<SoaTransform>

    pub fn run(self: *@This()) bool {
        return SamplingJob_Run_c(@ptrCast(self));
    }

    pub fn validate(self: *@This()) bool {
        return SamplingJob_Validate_c(@ptrCast(self));
    }

    pub extern fn SamplingJob_Validate_c(*anyopaque) bool;
    pub extern fn SamplingJob_Run_c(*anyopaque) bool;
};

pub fn spanFromArrayList(list: anytype) Span(@TypeOf(list.items[0])) {
    return makeSpan(list.items);
}

pub fn makeSpan(slice: anytype) Span(@TypeOf(slice[0])) {
    //return .{ .start = slice.ptr, .end = slice.ptr + slice.len };
    return .{ .start = slice.ptr, .end = slice.len };
}

pub fn Span(comptime T: type) type {
    return extern struct {
        start: [*c]T = null,
        end: [*c]T = null,

        pub fn fromArray(arr: []T) @This() {
            //return .{ .start = arr.ptr, .end = arr.ptr + arr.len };
            return .{ .start = arr.ptr, .end = arr.len };
        }

        pub fn toSlice(self: @This()) []T {
            return self.start[0..(@intFromPtr(self.end))];
        }
    };
}

pub const SamplingJobContext = opaque {
    pub fn create() *@This() {
        return @ptrCast(CreateSamplingJobContext_c());
    }

    pub fn createMaxTracks(tracksCount: c_int) *@This() {
        return @ptrCast(CreateSamplingJobContextCount_c(tracksCount));
    }

    pub fn resize(self: *@This(), tracksCount: usize) void {
        SamplingJobContext_Resize_c(@ptrCast(self), @intCast(tracksCount));
    }

    pub fn invalidate(self: *@This()) void {
        SamplingJobContext_Invalidate_c(self);
    }

    pub fn maxTracks(self: *@This()) c_int {
        return SamplingJobContext_MaxTracks_c(@ptrCast(self));
    }

    pub fn maxSoaTracks(self: *@This()) c_int {
        return SamplingJobContext_MaxSoaTracks_c(@ptrCast(self));
    }

    pub fn destroy(self: *@This()) void {
        DestroySamplingJobContext_c(self);
    }

    pub extern fn CreateSamplingJobContextCount_c(c_int) callconv(.C) ?*anyopaque;
    pub extern fn CreateSamplingJobContext_c() callconv(.C) ?*anyopaque;
    pub extern fn DestroySamplingJobContext_c(?*anyopaque) callconv(.C) void;

    pub extern fn SamplingJobContext_Resize_c(?*anyopaque, c_int) callconv(.C) void;
    pub extern fn SamplingJobContext_Invalidate_c(?*anyopaque) callconv(.C) void;

    pub extern fn SamplingJobContext_MaxTracks_c(?*anyopaque) callconv(.C) c_int;
    pub extern fn SamplingJobContext_MaxSoaTracks_c(?*anyopaque) callconv(.C) c_int;
};

pub extern fn testFunc() callconv(.C) void;
pub extern fn startupOzz() callconv(.C) void;
pub extern fn shutdownOzz() callconv(.C) void;

pub const SimdFloat4 = @Vector(4, f32);

pub const Float4x4 = extern struct {
    cols: [4]SimdFloat4,
};

pub const SimdFloat4_one = .{ 1, 1, 1, 1 };
pub const SimdFloat4_zero = .{ 0, 0, 0, 0 };

pub const SoaFloat2 = extern struct {
    x: SimdFloat4 = undefined,
    y: SimdFloat4 = undefined,
};

pub const SoaFloat3 = extern struct {
    x: SimdFloat4 = undefined,
    y: SimdFloat4 = undefined,
    z: SimdFloat4 = undefined,

    pub fn zero() @This() {
        return .{
            .x = SimdFloat4_zero,
            .y = SimdFloat4_zero,
            .z = SimdFloat4_zero,
        };
    }

    pub fn one() @This() {
        return .{
            .x = SimdFloat4_one,
            .y = SimdFloat4_one,
            .z = SimdFloat4_one,
        };
    }
};

pub const SoaQuaternion = extern struct {
    x: SimdFloat4 = undefined,
    y: SimdFloat4 = undefined,
    z: SimdFloat4 = undefined,
    w: SimdFloat4 = undefined,

    pub fn identity() @This() {
        return .{
            .x = SimdFloat4_zero,
            .y = SimdFloat4_zero,
            .z = SimdFloat4_zero,
            .w = SimdFloat4_one,
        };
    }
};

pub const OpaqueSpan = extern struct {
    start: ?*anyopaque,
    end: ?*anyopaque,
};

pub const SoaTransform = extern struct {
    translation: SoaFloat3 = SoaFloat3.zero(),
    rotation: SoaQuaternion = SoaQuaternion.identity(),
    scale: SoaFloat3 = SoaFloat3.one(),
};

pub const kNoParent = -1;
pub const kMaxJoints = 1024;
pub const kMaxSoAJoints = (kMaxJoints + 3) / 4;

pub const LocalToModelJob = extern struct {
    // The Skeleton object describing the joint hierarchy used for local to
    // model space conversion.
    skeleton: ?*Skeleton,

    // The root matrix will multiply to every model space matrices, default nullptr
    // means an identity matrix. This can be used to directly compute world-space
    // transforms for example.
    root: ?*Float4x4 = null,

    // Defines "from" which joint the local-to-model conversion should start.
    // Default value is ozz::Skeleton::kNoParent, meaning the whole hierarchy is
    // updated. This parameter can be used to optimize update by limiting
    // conversion to part of the joint hierarchy. Note that "from" parent should
    // be a valid matrix, as it is going to be used as part of "from" joint
    // hierarchy update.
    from: c_int = kNoParent,

    // Defines "to" which joint the local-to-model conversion should go, "to"
    // included. Update will end before "to" joint is reached if "to" is not part
    // of the hierarchy starting from "from". Default value is
    // ozz::animation::Skeleton::kMaxJoints, meaning the hierarchy (starting from
    // "from") is updated to the last joint.
    to: c_int = kMaxJoints,

    // If true, "from" joint is not updated during job execution. Update starts
    // with all children of "from". This can be used to update a model-space
    // transform independently from the local-space one. To do so: set "from"
    // joint model-space transform matrix, and run this Job with "from_excluded"
    // to update all "from" children.
    // Default value is false.
    from_excluded: bool = false,

    // The input range that store local transforms.
    input: Span(SoaTransform),

    // Job output.
    // The output range to be filled with model-space matrices.
    output: Span(Float4x4),

    pub fn run(self: *@This()) bool {
        return LocalToModelJob_Run_c(@ptrCast(self));
    }
    pub extern fn LocalToModelJob_Run_c(?*anyopaque) callconv(.C) bool;
};

pub const Layer = extern struct {
    // Blending weight of this layer. Negative values are considered as 0.
    // Normalization is performed during the blending stage so weight can be in
    // any range, even though range [0:1] is optimal.
    weight: f32 = 0.0,

    // The range [begin,end[ of input layer posture. This buffer expect to store
    // local space transforms, that are usually outputted from a sampling job.
    // This range must be at least as big as the rest pose buffer, even though
    // only the number of transforms defined by the rest pose buffer will be
    // processed.
    transform: Span(SoaTransform) = .{},

    // Optional range [begin,end[ of blending weight for each joint in this
    // layer.
    // If both pointers are nullptr (default case) then per joint weight
    // blending is disabled. A valid range is defined as being at least as big
    // as the rest pose buffer, even though only the number of transforms
    // defined by the rest pose buffer will be processed. When a layer doesn't
    // specifies per joint weights, then it is implicitly considered as
    // being 1.f. This default value is a reference value for the normalization
    // process, which implies that the range of values for joint weights should
    // be [0,1]. Negative weight values are considered as 0, but positive ones
    // aren't clamped because they could exceed 1.f if all layers contains valid
    // joint weights.
    jointWeights: Span(SoaTransform) = .{},
};

pub const BlendingJob = extern struct {

    // The job blends the rest pose to the output when the accumulated weight of
    // all layers is less than this threshold value.
    // Must be greater than 0.f.
    threshold: f32 = 0.01,

    // Job input layers, can be empty or nullptr.
    // The range of layers that must be blended.
    layers: Span(Layer) = .{},

    // Job input additive layers, can be empty or nullptr.
    // The range of layers that must be added to the output.
    additive_layers: Span(Layer) = .{},

    // The skeleton rest pose. The size of this buffer defines the number of
    // transforms to blend. This is the reference because this buffer is defined
    // by the skeleton that all the animations belongs to.
    // It is used when the accumulated weight for a bone on all layers is
    // less than the threshold value, in order to fall back on valid transforms.
    rest_pose: Span(SoaTransform) = .{},

    // Job output.
    // The range of output transforms to be filled with blended layer
    // transforms during job execution.
    // Must be at least as big as the rest pose buffer, but only the number of
    // transforms defined by the rest pose buffer size will be processed.
    output: Span(SoaTransform) = .{},

    // Validates job parameters.
    // Returns true for a valid job, false otherwise:
    // -if layer range is not valid (can be empty though).
    // -if additive layer range is not valid (can be empty though).
    // -if any layer is not valid.
    // -if output range is not valid.
    // -if any buffer (including layers' content : transform, joint weights...) is
    // smaller than the rest pose buffer.
    // -if the threshold value is less than or equal to 0.f.
    pub fn validate(self: *const @This()) bool {
        return self.BlendingJob_Validate_c(@ptrCast(self));
    }

    // Runs job's blending task.
    // The job is validated before any operation is performed, see Validate() for
    // more details.
    // Returns false if *this job is not valid.
    pub fn run(self: *@This()) bool {
        return BlendingJob_Run_c(@ptrCast(self));
    }

    pub extern fn BlendingJob_Validate_c(?*anyopaque) callconv(.C) bool;
    pub extern fn BlendingJob_Run_c(?*anyopaque) callconv(.C) bool;
};

pub const std = @import("std");
