// big main system for animation

const ozz = @import("ozz");
const core = @import("core");
const std = @import("std");

pub const Skeleton = struct {
    sk: *ozz.Skeleton,
    inverseBinds: std.ArrayListUnmanaged(core.Mat) = .{},
    jointMapping: std.StringHashMapUnmanaged(u8) = .{},

    pub fn buildJointMap(self: *@This(), allocator: std.mem.Allocator) !void {
        for (self.sk.getJointsList(), 0..) |jointName, i| {
            const str = std.mem.span(jointName);
            try self.jointMapping.put(allocator, str, @intCast(i));
        }
    }

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
            mesh.animated = true; //todo
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

        var jointRemap: ?[]u8 = null;
        if (self.entity.get(graphics.StaticMesh)) |meshComponent| {
            if (meshComponent.mesh) |mesh| {
                jointRemap = mesh.jointRemap;
            }
        }

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

            const p: core.zm.Vec = .{ 0, 0, 0, 1 };
            graphics.debugSphere(core.Vectorf.fromZm(core.zm.mul(p, transform)), 0.03, .{
                .color = if (i == 3) .{ .x = 1 } else .{ .y = 1 },
            });

            const final = core.zm.mul(skeleton.inverseBinds.items[i], transform);
            // joint remap ozz -> gltf
            if (jointRemap) |jr| {
                self.finals.items[@intCast(jr[i])] = final;
            } else {
                self.finals.items[i] = final;
            }
            // core.engine_log(
            //     "[{d}] {d} {d} {d} {d}, {d} {d} {d} {d}",
            //     .{ i, transform[0][0], transform[0][1], transform[0][2], transform[0][3], transform[1][0], transform[1][1], transform[1][2], transform[1][3] },
            // );
        }
    }

    pub fn setAnimationByName(self: *@This(), _name: core.Name) !void {
        var name = _name;
        self.track = gAnimationSys.animTracks.get(name.handle());
    }

    pub fn setAnimation(self: *@This(), path: []const u8) void {
        const name = core.MakeName(path);
        self.setAnimationByName(name) catch unreachable;
    }

    pub fn deinit(self: *@This()) void {
        self.sjc.destroy();
        self.finals.deinit(allocator);
        self.locals.deinit(allocator);
        self.models.deinit(allocator);
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

    sharedArena: [2]std.heap.ArenaAllocator, // could be a good usecase for a fat bump arena
    shared: [2]std.ArrayListUnmanaged(MatrixUploads) = .{ .{}, .{} },
    sharedLocks: [2]std.Thread.Mutex = .{ .{}, .{} }, // could be a good usecase for a fat bump arena

    pub const MatrixUploads = struct {
        offset: u32,
        matrices: std.ArrayListUnmanaged(core.Mat) = .{},
    };

    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());
    pub const RendererInterfaceVTable = graphics.RendererInterface.from(@This());

    pub fn preTick(self: *@This(), dt: f64) !void {
        _ = self;

        for (Animator.BaseContainer.list.items) |animator| {
            animator.update(dt);
        }
    }

    pub fn newAnimTrack(self: *@This(), _name: core.Name, anim: *ozz.Animation) !void {
        var name = _name;
        const new = try self.arenaAllocator().create(AnimationTrack);
        new.* = .{
            .animation = anim,
            .endTime = anim.getDuration(),
        };
        try self.animTracks.put(self.backingAllocator, name.handle(), new);
    }

    pub fn newSkeleton(self: *@This(), _name: core.Name, sk: *ozz.Skeleton) !void {
        const new = try self.arenaAllocator().create(Skeleton);
        new.* = .{
            .sk = sk,
        };
        var name = _name;

        try new.buildJointMap(self.arenaAllocator());

        try new.inverseBinds.resize(self.arenaAllocator(), new.sk.numJoints());

        if (new.inverseBinds.items.len > 256) {
            @panic("too many bones in skeleton, not supported");
        }

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
            // const p: core.zm.Vec = .{ 0, 0, 0, 1 };
            // graphics.debugSphere(core.Vectorf.fromZm(core.zm.mul(p, @as(core.Mat, @bitCast(bind)))), 0.1, .{ .duration = 100 });

            new.inverseBinds.items[i] = core.zm.inverse(@as(core.Mat, @bitCast(bind)));
        }

        try self.skeletons.put(self.backingAllocator, name.handle(), new);
    }

    pub fn arenaAllocator(self: *@This()) std.mem.Allocator {
        return self.arena.allocator();
    }

    pub fn getShared(self: @This(), fi: u32) []const MatrixUploads {
        return self.shared[fi].items;
    }

    pub fn sendShared(self: *@This(), frameIndex: u32) void {
        const fi: usize = @intCast(frameIndex);

        self.sharedLocks[fi].lock();
        defer self.sharedLocks[fi].unlock();

        _ = self.sharedArena[fi].reset(.retain_capacity);

        const allocator = self.sharedArena[fi].allocator();
        const shared = &self.shared[fi];
        shared.* = .{};

        for (Animator.BaseContainer.list.items) |animator| {
            var upload: MatrixUploads = .{ .offset = animator.finalsSpan.start };
            // core.engine_log("finalsSpan size offset{d} {d} animator finals {d}\n", .{ animator.finalsSpan.start, animator.finalsSpan.size, animator.finals.items.len });

            upload.matrices.resize(allocator, animator.finalsSpan.size) catch unreachable;

            for (animator.finals.items, 0..) |final, i| {
                upload.matrices.items[i] = final;
            }

            shared.append(allocator, upload) catch unreachable;
        }
    }

    pub fn init(alloc: std.mem.Allocator) !*@This() {
        const self = try alloc.create(@This());
        self.* = .{
            .backingAllocator = alloc,
            .arena = std.heap.ArenaAllocator.init(alloc),
            .sharedArena = .{
                std.heap.ArenaAllocator.init(alloc),
                std.heap.ArenaAllocator.init(alloc),
            },
            .slots = try MergedSpans.init(alloc, vk_constants.MAX_SKIN_SLOTS),
        };

        gAnimationSys = self;
        Animator.allocator = alloc;

        try core.defineComponent(Animator, alloc);
        return self;
    }

    pub fn deinit(self: *@This()) void {
        core.engine_logs("deinitializaing animation system");
        {
            core.engine_log("skeleton count {d}", .{self.skeletons.count()});
            var iter = self.skeletons.iterator();
            while (iter.next()) |i| {
                i.value_ptr.*.deinit();
            }
        }

        {
            core.engine_log("animTracks count {d}", .{self.animTracks.count()});
            var iter = self.animTracks.iterator();
            while (iter.next()) |i| {
                i.value_ptr.*.deinit();
            }
        }

        for (self.sharedArena) |arena| {
            arena.deinit();
        }

        for (Animator.BaseContainer.list.items) |animator| {
            animator.deinit();
        }
        self.slots.deinit();
        core.undefineComponent(Animator);
        self.arena.deinit();
        self.skeletons.deinit(self.backingAllocator);
        self.animTracks.deinit(self.backingAllocator);
        self.backingAllocator.destroy(self);
    }
};

pub var gAnimationSys: *AnimationSystem = undefined;

pub fn getSkeletonByName(_name: core.Name) ?*Skeleton {
    var name = _name;
    return gAnimationSys.skeletons.get(name.handle());
}

const graphics = @import("../graphics.zig");
const MergedSpans = core.MergedSpans;
const vk_constants = @import("../vk_constants.zig");
