// big main system for animation

const ozz = @import("ozz");
const core = @import("core");
const std = @import("std");

pub const Skeleton = struct {
    sk: *ozz.Skeleton,
    inverseBinds: std.ArrayListUnmanaged(core.Mat) = .{},

    pub fn deinit(self: *@This()) void {
        self.sk.destroy();
    }
};

pub const AnimationTrack = struct {
    animation: *ozz.Animation,
    endTime: f32 = 1.0,
    pub fn deinit(self: *@This()) void {
        self.animation.destroy();
    }
};

pub const Animator = struct {
    animationName: ?core.Name = null,
    skeleton: ?*Skeleton = null,
    skeletonName: ?core.Name = null,
    sjc: *ozz.SamplingJobContext = undefined,

    track: ?*AnimationTrack = null,
    playback: f32 = 0.0,
    playbackRate: f32 = 1.0,
    // todo.. implement blending
    // animations: [4]*ozz.Animation = undefined,
    // timelines: [4]f32 = .{ 0, 0, 0, 0 },
    animationCount: u32 = 0,

    finals: std.ArrayListUnmanaged(core.Mat) = .{},
    locals: std.ArrayListUnmanaged(ozz.SoaTransform) = .{},
    models: std.ArrayListUnmanaged(ozz.Float4x4) = .{},
    finalsSpan: core.Span = undefined,

    entity: core.Entity = undefined,

    pub var allocator: std.mem.Allocator = undefined;
    // oh god if I want to support multiple animation blending...
    // maybe the kernel should contain a fixed amount of animations?

    pub fn initECS(self: *@This(), handle: core.SetHandle) void {
        // get the mesh component
        self.entity = core.Entity{ .handle = handle };

        if (self.entity.get(graphics.StaticMesh)) |mesh| {
            // mesh.animated = true; //todo
            mesh.animator = self;
            self.sjc = ozz.SamplingJobContext.createMaxTracks(256);
        } else {
            @panic("animator added to an entity that does not have a mesh");
        }
    }

    pub fn setSkeletonByName(self: *@This(), skName: core.Name) !void {
        if (self.skeleton != null) {
            // return the previous span and allocate a new one.
            gAnimationSys.slots.removeSpan(self.finalsSpan);
        }

        self.skeletonName = skName;
        self.skeleton = gAnimationSys.skeletons.get(self.skeletonName.?.handle()).?;
        const numJoints = self.skeleton.?.sk.numJoints();

        self.sjc.resize(@intCast(numJoints));
        try self.locals.resize(allocator, self.skeleton.?.sk.numSoaJoints());
        try self.models.resize(allocator, numJoints);
        try self.finals.resize(allocator, numJoints);
        self.finalsSpan = try gAnimationSys.slots.allocate(@intCast(numJoints));
    }

    pub fn setSkeleton(self: *@This(), skeleton: []const u8) void {
        self.setSkeletonByName(core.MakeName(skeleton)) catch unreachable;
    }

    pub fn update(self: *@This(), dt: f64) void {
        if (self.skeleton == null)
            return;

        if (self.track == null)
            return;

        const track = self.track.?;
        if (track.endTime < 0.01)
            return;

        const skeleton = self.skeleton.?;
        self.playback += @as(f32, @floatCast(dt)) * self.playbackRate;

        while (self.playback > track.endTime) {
            self.playback -= track.endTime;
        }

        var samplingJob: ozz.SamplingJob = .{
            .ratio = self.playback / track.endTime,
            .animation = track.animation,
            .context = self.sjc,
            .output = ozz.makeSpan(self.locals.items),
        };

        if (!samplingJob.run()) {
            core.engine_errs("sampling job failed");
            return;
        }

        var ltmJob: ozz.LocalToModelJob = .{
            .skeleton = skeleton.sk,
            .input = ozz.makeSpan(self.locals.items),
            .output = ozz.makeSpan(self.models.items),
        };

        if (!ltmJob.run()) {
            core.engine_errs("local to model job failed");
            return;
        }

        for (self.models.items, 0..) |model, i| {
            const transform: core.Mat = @bitCast(model);
            const final = core.zm.mul(skeleton.inverseBinds.items[i], transform);
            self.finals.append(allocator, final) catch unreachable;
        }
    }

    pub fn setAnimationByName(self: *@This(), name: core.Name) !void {
        self.track = gAnimationSys.animTracks.get(name.handle());
    }

    pub fn setAnimation(self: *@This(), path: []const u8) void {
        const name = core.MakeName(path);
        self.setAnimationByName(name) catch unreachable;
    }

    pub var BaseContainer: *core.SparseMap(@This()) = undefined;
    pub const ComponentName = "Animator";
    pub const ScriptExports: []const []const u8 = &.{};
};

pub const AnimationSystem = struct {
    backingAllocator: std.mem.Allocator,

    arena: std.heap.ArenaAllocator,
    slots: MergedSpans,

    // Only AnimationTrack and Skeletons are made using the ArenaAllocator
    animTracks: std.AutoHashMapUnmanaged(u32, *AnimationTrack) = .{},
    skeletons: std.AutoHashMapUnmanaged(u32, *Skeleton) = .{},

    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    pub fn tick(self: *@This(), dt: f64) void {
        _ = self;

        for (Animator.BaseContainer.list.items) |animator| {
            animator.update(dt);
        }
    }

    pub fn newAnimTrack(self: *@This(), name: core.Name, anim: *ozz.Animation) !void {
        const new = try self.arenaAllocator().create(AnimationTrack);
        new.* = .{
            .animation = anim,
            .endTime = anim.getDuration(),
        };
        try self.animTracks.put(self.backingAllocator, name.handle(), new);
    }

    pub fn newSkeleton(self: *@This(), name: core.Name, sk: *ozz.Skeleton) !void {
        const new = try self.arenaAllocator().create(Skeleton);
        new.* = .{
            .sk = sk,
        };

        try new.inverseBinds.resize(self.arenaAllocator(), new.sk.numJoints());

        var bindModels = std.ArrayList(ozz.Float4x4).init(self.backingAllocator);
        defer bindModels.deinit();

        try bindModels.resize(new.sk.numJoints());

        var ltmJob: ozz.LocalToModelJob = .{
            .skeleton = new.sk,
            .input = new.sk.getRestPoseModel(),
            .output = ozz.makeSpan(bindModels.items),
        };

        core.engine_log("creating bind pose {d} joints", .{new.inverseBinds.items.len});

        if (!ltmJob.run()) {
            core.engine_logs("unable to get bind pose");
            return error.UnableToLoad;
        }

        for (bindModels.items, 0..) |bind, i| {
            new.inverseBinds.items[i] = core.zm.inverse(@as(core.Mat, @bitCast(bind)));
        }

        try self.skeletons.put(self.backingAllocator, name.handle(), new);
    }

    pub fn arenaAllocator(self: *@This()) std.mem.Allocator {
        return self.arena.allocator();
    }

    pub fn init(alloc: std.mem.Allocator) !*@This() {
        const self = try alloc.create(@This());
        self.* = .{
            .backingAllocator = alloc,
            .arena = std.heap.ArenaAllocator.init(alloc),
            .slots = try MergedSpans.init(alloc, vk_constants.MAX_SKIN_SLOTS),
        };

        gAnimationSys = self;
        Animator.allocator = alloc;

        try core.defineComponent(Animator, alloc);
        return self;
    }

    pub fn deinit(self: *@This()) void {
        {
            var iter = self.skeletons.iterator();
            while (iter.next()) |i| {
                i.value_ptr.*.deinit();
            }
        }

        {
            var iter = self.animTracks.iterator();
            while (iter.next()) |i| {
                i.value_ptr.*.deinit();
            }
        }
        core.undefineComponent(Animator);
        self.arena.deinit();
        self.skeletons.deinit(self.backingAllocator);
        self.animTracks.deinit(self.backingAllocator);
        self.backingAllocator.destroy(self);
    }
};

pub var gAnimationSys: *AnimationSystem = undefined;

const graphics = @import("../graphics.zig");
const MergedSpans = core.MergedSpans;
const vk_constants = @import("../vk_constants.zig");
