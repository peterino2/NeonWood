const std = @import("std");
const neonwood = @import("root").neonwood;
const core = neonwood.core;
const graphics = neonwood.graphics;
const assets = neonwood.assets;
const engine_log = core.engine_log;
const c = graphics.c;

const Vectorf = core.Vectorf;
const Vector2 = core.Vector2;
const Camera = graphics.render_object.Camera;
const RenderObject = graphics.render_objects.RenderObject;
const AssetReference = assets.AssetReference;
const AsyncAssetJobContext = assets.AyncAssetJobContext;
const MakeName = core.MakeName;
const mul = core.zm.mul;
const JobContext = core.JobContext;
const JobManager = core.JobManager;

var gGame: *GameContext = undefined;
const jobTestCount = 100;

// primarily a test file that exists to create a simple application for
// job dispatching.
const GameContext = struct {
    const Self = @This();
    pub var NeonObjectTable: core.RttiData = core.RttiData.from(Self);

    allocator: std.mem.Allocator,
    wakeCount: u32 = 100,
    timeTilWake: f64 = 2.0,
    count: std.atomic.Atomic(u32) = std.atomic.Atomic(u32).init(0),
    complete: [jobTestCount]bool = std.mem.zeroes([jobTestCount]bool),
    timeElapsed: f64 = 0.0,
    reinjectFired: bool = false,

    pub fn init(allocator: std.mem.Allocator) !*Self {
        var self = try allocator.create(@This());

        self.* = Self{
            .allocator = allocator,
        };

        return self;
    }

    pub fn prepare(self: *Self) !void {
        const Payload = struct {
            value: u32 = 42069,
        };

        const Lambda = struct {
            capturedValue: u32 = 43,
            payload: Payload,
            game: *GameContext,

            pub fn func(ctx: @This(), job: *JobContext) void {
                core.printInner("job started, payload: {any}\n", .{ctx.payload});
                std.time.sleep(1000 * 1000 * 1000);
                var v = ctx.game.count.fetchAdd(1, .SeqCst);
                core.printInner("job done!{d} {d}\n", .{ ctx.payload.value, v });
                ctx.game.complete[@intCast(ctx.payload.value)] = true;
                _ = job;
            }
        };

        var x: u32 = 0;
        while (x < jobTestCount) : (x += 1) {
            core.engine_log("creating job: {d}", .{x});
            try core.dispatchJob(Lambda{ .payload = .{ .value = x }, .game = self });
        }
    }

    pub fn tick(self: *Self, deltaTime: f64) void {
        self.timeElapsed += deltaTime;
        core.printInner("ticking\n", .{});

        if (self.timeTilWake <= 0) {
            self.timeTilWake = 0.5;
            self.wakeCount -= 1;
            core.engine_log("tick {d}", .{self.count.load(.SeqCst)});
            var i: usize = 0;

            while (i < jobTestCount) : (i += 1) {
                var d = @as(u1, @bitCast(self.complete[i]));
                core.printInner("{d}", .{d});
            }
            core.printInner("\n", .{});
            core.engine_logs("endTick");
        }

        // reinjected jobs test.
        const L = struct {
            jobId: usize,
            game: *GameContext,
            reInjected: bool = false,

            pub fn func(ctx: @This(), job: *JobContext) void {
                _ = job;

                if (ctx.jobId % 2 == 0) {
                    core.dispatchJob(@This(){
                        .game = ctx.game,
                        .jobId = 1,
                        .reInjected = true,
                    }) catch unreachable;
                }

                core.engine_logs("sample text this is an injected job");
                std.time.sleep(1000 * 1000 * 100);
                if (ctx.reInjected) {
                    core.engine_logs("reinjected job done");
                } else {
                    core.engine_logs("injected job done");
                }
            }
        };

        if (!self.reinjectFired and self.timeElapsed > 4.0) {
            var i: usize = 0;
            self.reinjectFired = true;

            while (i < 100) : (i += 1) {
                core.dispatchJob(L{ .game = self, .jobId = i }) catch unreachable;
            }
        }

        self.timeTilWake -= 0.1;
        std.time.sleep(1000 * 1000 * 100);

        if (self.count.load(.SeqCst) >= jobTestCount) {
            var i: usize = 0;
            while (i < jobTestCount) : (i += 1) {
                var d = @as(u1, @bitCast(self.complete[i]));
                core.printInner("{d}", .{d});
            }
            core.printInner("shutting down due to count loaded full\n", .{});

            core.gEngine.exit();
        }

        if (self.wakeCount <= 0) {
            core.printInner("shutting down due to wake count zero\n", .{});
            core.gEngine.exit();
        }
    }

    pub fn shutdown(self: *Self) void {
        _ = self;
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const cleanupStatus = gpa.deinit();
        if (cleanupStatus == .leak) {
            core.printInner("gpa cleanup leaked memory\n", .{});
        }
    }
    const allocator = gpa.allocator();
    engine_log("Starting up", .{});
    core.start_module(allocator);
    defer core.shutdown_module(allocator);

    try neonwood.platform.start_module(allocator, .{ .windowName = "jobTest" });

    // Setup the game
    var game = try core.createObject(GameContext, .{ .can_tick = true });
    try game.prepare();
    defer game.shutdown();

    // run the game
    try core.gEngine.run();

    while (!core.gEngine.exitSignal) {}
}
