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

pub const AnimSampler = struct {
    name: ?core.Name = null,
    track: ?*AnimationTrack = null,
    playbackRate: f32 = 1.0,
    time: f32 = 0.0,
    outputLocals: std.ArrayListUnmanaged(ozz.SoaTransform) = .{},

    // other features
    // paused: bool = false,
    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.outputLocals.deinit(allocator);
    }

    pub fn getOutput(self: *@This()) []ozz.SoaTransform {
        return self.outputLocals.items;
    }

    pub fn sampleAndAdvance(self: *@This(), allocator: std.mem.Allocator, dt: f64, animator: *Animator) void {
        self.sample(allocator, animator);
        self.advance(dt);
    }

    pub fn advance(self: *@This(), dt: f64) void {
        if (self.track == null) {
            return;
        }

        FloatHelpers.updateTrackTime(&self.time, dt, self.playbackRate, self.track.?.endTime);
    }

    pub fn setName(self: *@This(), name: core.Name) void {
        self.name = name;
        self.track = null;
    }

    pub fn sample(self: *@This(), allocator: std.mem.Allocator, animator: *Animator) void {
        if (self.name == null) {
            return;
        }

        if (self.track == null) {
            self.track = animation_system.gAnimationSys.animTracks.get(self.name.?.handle());
        }

        self.outputLocals.resize(allocator, animator.jointLength) catch return;

        if (self.track) |track| {
            if (track.endTime < 0.01) {
                return;
            }

            animator.sampleAnimation(self.time, track, self.outputLocals.items);
        }
    }
};

pub const BlenderList = struct {
    backing: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    jobLayers: std.ArrayListUnmanaged(ozz.Layer) = .{},
    jobLayersAdditive: std.ArrayListUnmanaged(ozz.Layer) = .{},
    useAdditive: bool = false,

    threshold: f32 = 0.01,
    jointLength: usize = 0,
    blendingJob: ozz.BlendingJob = .{},

    pub fn create(backingAllocator: std.mem.Allocator) !*@This() {
        const self = try backingAllocator.create(@This());
        self.* = .{
            .backing = backingAllocator,
            .arena = std.heap.ArenaAllocator.init(backingAllocator),
        };

        return self;
    }

    pub fn destroy(self: *@This()) void {
        self.arena.deinit();
        self.backing.destroy(self);
    }

    pub fn updateRestPose(self: *@This(), animator: *Animator) !void {
        if (animator.skeleton) |skeleton| {
            self.jointLength = skeleton.sk.numJoints();
            self.blendingJob.rest_pose = skeleton.sk.getRestPoseModel();
        }
    }

    pub fn clearLayers(self: *@This()) void {
        self.jobLayersAdditive.clearRetainingCapacity();
        self.jobLayers.clearRetainingCapacity();
    }

    pub fn addLayer(self: *@This(), transform: []ozz.SoaTransform, weight: f32, settings: anytype) void {
        const layer = self.jobLayers.addOne(self.arena.allocator()) catch unreachable;
        layer.* = .{
            .weight = weight,
            .transform = ozz.makeSpan(transform),
        };
        _ = settings;
    }

    pub fn updateAndRun(self: *@This(), output: []ozz.SoaTransform) void {
        self.updateBlendingJob();
        self.runBlendingJob(output) catch return;
    }

    pub fn updateBlendingJob(self: *@This()) void {
        self.blendingJob.threshold = self.threshold;
        self.blendingJob.layers = ozz.makeSpan(self.jobLayers.items);
        //self.blendingJob.additive_layers = if (self.useAdditive) ozz.makeSpan(self.jobLayersAdditive.items) else .{};
        self.blendingJob.additive_layers = .{};
    }

    pub fn runBlendingJob(self: *@This(), output: []ozz.SoaTransform) !void {
        self.blendingJob.output = ozz.makeSpan(output);
        if (!self.blendingJob.run()) {
            core.engine_logs("blending job failed");
            return;
        }
    }
};

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
