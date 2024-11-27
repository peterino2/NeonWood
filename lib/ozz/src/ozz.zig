pub fn hello() void {
    std.debug.print("whatsup\n", .{});
}

pub const Skeleton = opaque {
    pub fn create() *@This() {
        return @ptrCast(CreateSkeleton_c());
    }

    pub fn loadFromFile(self: *@This(), path: [*c]const u8) void {
        LoadSkeletonFromFile_c(self, path);
    }

    pub fn destroy(self: *@This()) void {
        DestroySkeleton_c(@ptrCast(self));
    }

    pub extern fn CreateSkeleton_c() callconv(.C) ?*anyopaque;
    pub extern fn DestroySkeleton_c(target: ?*anyopaque) callconv(.C) void;
    pub extern fn LoadSkeletonFromFile_c(s: ?*anyopaque, path: [*c]const u8) callconv(.C) void;
};

pub const Animation = opaque {
    pub fn create() *@This() {
        return @ptrCast(CreateAnimation_c());
    }

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
    ratio: f32, // float ratio;
    animation: *Animation, // const Animation* animation;
    context: *SamplingJobContext, //
    output: Span(SoaTransform), // ozz::span<SoaTransform>

    pub fn run(self: *@This()) bool {
        return SamplingJob_Run_c(self);
    }

    pub extern fn SamplingJob_Run_c(*anyopaque) bool;
};

pub fn Span(comptime T: type) type {
    return struct {
        start: [*]T,
        end: [*]T,

        pub fn fromArray(arr: []T) @This() {
            return .{ .start = arr.ptr, .end = arr.ptr + arr.len };
        }
    };
}

pub const SamplingJobContext = opaque {
    pub fn create() *@This() {}

    pub fn destroy(self: *@This()) void {
        _ = self;
    }
};

pub extern fn testFunc() callconv(.C) void;
pub extern fn startupOzz() callconv(.C) void;
pub extern fn shutdownOzz() callconv(.C) void;

pub const SimdFloat4 = @Vector(f32, 4);

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

pub const SoaTransform = extern struct {
    translation: SoaFloat3 = SoaFloat3.zero(),
    rotation: SoaQuaternion = SoaQuaternion.identity(),
    scale: SoaFloat3 = SoaFloat3.one(),
};

pub const std = @import("std");
