const nw = @import("NeonWood");
const core = nw.core;
const graphics = nw.graphics;
const ozz = nw.graphics.ozz;
pub const std = @import("std");

pub const AnimationDemo = struct {
    animation: *ozz.Animation = undefined,
    skeleton: *ozz.Skeleton = undefined,
    samplingJobContext: *ozz.SamplingJobContext = undefined,
    locals: std.ArrayListUnmanaged(ozz.SoaTransform),
    models: std.ArrayListUnmanaged(ozz.Float4x4),
    inverseBinds: std.ArrayListUnmanaged(core.Mat),
    ratio: f64 = 0.0,
    bindModels: std.ArrayListUnmanaged(ozz.Float4x4),

    allocator: std.mem.Allocator,

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        const sjc = ozz.SamplingJobContext.createMaxTracks(420);
        self.* = .{
            .allocator = allocator,
            .samplingJobContext = sjc,
            .skeleton = ozz.Skeleton.create(),
            .animation = ozz.Animation.create(),
            .locals = .{},
            .inverseBinds = .{},
            .bindModels = .{},
            .models = .{},
        };

        self.skeleton.loadFromFile("content/gltf-samples/Fox/glTF/skeleton.ozz");
        try self.locals.resize(self.allocator, self.skeleton.numSoaJoints());
        try self.models.resize(self.allocator, self.skeleton.numJoints());
        std.debug.assert(self.locals.items.len > 0);
        std.debug.assert(self.models.items.len > 0);

        self.animation.loadFromFile("content/gltf-samples/Fox/glTF/Run.ozz");
        self.samplingJobContext.resize(self.skeleton.numJoints());

        try self.inverseBinds.resize(self.allocator, self.skeleton.numJoints());
        try self.bindModels.resize(self.allocator, self.skeleton.numJoints());

        var ltmJob: ozz.LocalToModelJob = .{
            .skeleton = self.skeleton,
            .input = self.skeleton.getRestPoseModel(),
            .output = ozz.makeSpan(self.bindModels.items),
        };

        core.engine_log("creating bind pose {d} joints", .{self.inverseBinds.items.len});

        if (!ltmJob.run()) {
            core.engine_logs("unable to get bind pose");
        }

        for (self.bindModels.items, 0..) |bind, i| {
            self.inverseBinds.items[i] = core.zm.inverse(@as(core.Mat, @bitCast(bind)));
        }

        return self;
    }

    pub fn tick(self: *@This(), deltaTime: f64) !void {
        self.ratio += deltaTime;
        if (self.ratio > 1.0) {
            self.ratio = 0;
        }
        var samplingJob: ozz.SamplingJob = .{
            .ratio = @floatCast(self.ratio),
            .animation = self.animation,
            .context = self.samplingJobContext,
            .output = ozz.makeSpan(self.locals.items),
        };

        if (!samplingJob.run()) {
            core.engine_logs("sampling job failed");
        }

        var ltmJob: ozz.LocalToModelJob = .{
            .skeleton = self.skeleton,
            .input = ozz.makeSpan(self.locals.items),
            .output = ozz.makeSpan(self.models.items),
        };

        if (!ltmJob.run()) {
            core.engine_logs("local to model job failed");
            return;
        }

        const gc = graphics.getContext();
        const rt = &gc.renderthread;

        rt.skinningLock.lock();
        defer rt.skinningLock.unlock();

        rt.skinning.clearRetainingCapacity();
        for (self.models.items, 0..) |x, i| {
            const transform: core.Mat = @bitCast(x);
            const final = core.zm.mul(self.inverseBinds.items[i], transform);
            try rt.skinning.append(rt.allocator, final);
            const offset = core.zm.mul(core.zm.Vec{ 0, 0, 0, 1 }, transform);
            core.debugSphere(core.Vectorf.fromZm(offset), 5, .{});
        }
    }

    pub fn destroy(self: *@This()) void {
        self.samplingJobContext.destroy();
        self.skeleton.destroy();
        self.animation.destroy();

        self.locals.deinit(self.allocator);
        self.models.deinit(self.allocator);

        self.allocator.destroy(self);
    }
};
