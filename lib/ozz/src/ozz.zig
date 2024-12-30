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

    pub extern fn CreateSkeleton_c() callconv(.C) ?*anyopaque;
    pub extern fn DestroySkeleton_c(target: ?*anyopaque) callconv(.C) void;
    pub extern fn LoadSkeletonFromFile_c(s: ?*anyopaque, path: [*c]const u8) callconv(.C) void;
};

pub const Animation = opaque {
    pub fn create() *@This() {
        return @ptrCast(CreateAnimation_c());
    }

    // todo add error messages
    pub fn loadFromFile(self: *@This(), path: [*c]const u8) void {
        LoadAnimationFromFile_c(self, path);
    }

    pub fn destroy(self: *@This()) void {
        DestroyAnimation_c(@ptrCast(self));
    }

    pub extern fn CreateAnimation_c() callconv(.C) ?*anyopaque;
    pub extern fn LoadAnimationFromFile_c(s: ?*anyopaque, path: [*c]const u8) void;
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
    return .{ .start = slice.ptr, .end = slice.ptr + slice.len };
}

pub fn Span(comptime T: type) type {
    return extern struct {
        start: [*c]T = null,
        end: [*c]T = null,

        pub fn fromArray(arr: []T) @This() {
            return .{ .start = arr.ptr, .end = arr.ptr + arr.len };
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

pub const std = @import("std");
