const nw = @import("NeonWood");
const core = nw.core;
const ozz = nw.graphics.ozz;
pub const std = @import("std");

pub const AnimationDemo = struct {
    animation: *ozz.Animation = undefined,
    skeleton: *ozz.Skeleton = undefined,
    samplingJobContext: *ozz.SamplingJobContext = undefined,
    locals: std.ArrayListUnmanaged(ozz.SoaTransform),
    models: std.ArrayListUnmanaged(ozz.Float4x4),

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
            .models = .{},
        };

        self.skeleton.loadFromFile("content/test_ozz/pab_skeleton.ozz");
        try self.locals.resize(self.allocator, self.skeleton.numSoaJoints());
        try self.models.resize(self.allocator, self.skeleton.numJoints());
        std.debug.assert(self.locals.items.len > 0);
        std.debug.assert(self.models.items.len > 0);

        self.animation.loadFromFile("content/test_ozz/pab_crossarms.ozz");
        self.samplingJobContext.resize(self.skeleton.numJoints());

        return self;
    }

    pub fn tick(self: *@This(), deltaTime: f64) !void {
        _ = deltaTime;
        var samplingJob: ozz.SamplingJob = .{
            .ratio = 0.5,
            .animation = self.animation,
            .context = self.samplingJobContext,
            .output = ozz.spanFromSlice(self.locals.items),
        };

        if (!samplingJob.run()) {
            core.engine_logs("sampling job failed");
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
