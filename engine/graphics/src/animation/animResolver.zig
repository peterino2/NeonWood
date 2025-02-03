pub const AnimResolverRef = core.Reference(AnimResolverInterface);
pub const AnimResolverInterface = core.MakeInterface("AnimResolverVTable", struct {
    // this tick function should evaluate the current state of the resolver
    // and then update the animator's finals[] matrix list.
    resolve: *const fn (*anyopaque, f64, *Animator) void,
    onSkeletonSet: ?*const fn (*anyopaque, *Animator) void = null,

    create: *const fn (std.mem.Allocator) core.EngineDataEventError!*anyopaque,
    destroy: *const fn (*anyopaque) void,

    pub fn Implement(comptime TargetType: type) @This() {
        const Wrap = struct {
            pub fn create(allocator: std.mem.Allocator) core.EngineDataEventError!*anyopaque {
                const new = TargetType.create(allocator) catch return core.EngineDataEventError.BadInit;
                return @ptrCast(new);
            }

            pub fn destroy(p: *anyopaque) void {
                const ptr: *TargetType = @ptrCast(@alignCast(p));
                ptr.destroy();
            }

            pub fn onSkeletonSet(p: *anyopaque, a: *Animator) void {
                const ptr: *TargetType = @ptrCast(@alignCast(p));
                ptr.onSkeletonSet(a) catch unreachable;
            }

            pub fn resolve(p: *anyopaque, dt: f64, a: *Animator) void {
                const ptr: *TargetType = @ptrCast(@alignCast(p));
                ptr.resolve(dt, a) catch unreachable;
            }
        };
        return .{
            .destroy = Wrap.destroy,
            .create = Wrap.create,
            .resolve = Wrap.resolve,
        };
    }
});

// resolver helpers
pub const FloatHelpers = struct {
    pub inline fn updateTrackTime(target: *f32, dt: f64, rate: f32, endTime: f32) void {
        target.* += @as(f32, @floatCast(dt)) * rate;
        while (target.* > endTime) {
            target.* -= endTime;
        }
    }
};

// samples a single animation, same as the default behaviour.
// used as a test for the resolver system
pub const SingleAnimationResolver = struct {
    allocator: std.mem.Allocator,
    locals: std.ArrayListUnmanaged(ozz.SoaTransform) = .{},

    track: ?*AnimationTrack = null,
    playback: f32 = 0.0,
    playbackRate: f32 = 1.0,

    pub const AnimResolverVTable = AnimResolverInterface.Implement(@This());

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
        };

        return self;
    }

    pub fn onSkeletonSet(self: *@This(), animator: *Animator) !void {
        if (animator.skeleton) |skeleton| {
            try self.locals.resize(self.allocator, skeleton.sk.numSoaJoints());
        }
    }

    pub fn resolve(self: *@This(), dt: f64, animator: *Animator) !void {
        self.track = animator.track;
        if (self.track == null) {
            return;
        }

        const track = self.track.?;
        if (track.endTime < 0.01) {
            return;
        }

        FloatHelpers.updateTrackTime(&self.playback, dt, self.playbackRate, track.endTime);
        animator.sampleAnimation(self.playback, track, self.locals.items);
        animator.commitLocalToModel(self.locals.items);
        animator.modelToFinal();
    }

    pub fn destroy(self: *@This()) void {
        self.locals.deinit(self.allocator);
        self.allocator.destroy(self);
    }
};

const animation_system = @import("animationSystem.zig");
const Animator = animation_system.Animator;
const AnimationTrack = animation_system.AnimationTrack;

const core = @import("core");
const std = @import("std");
const ozz = @import("ozz");
