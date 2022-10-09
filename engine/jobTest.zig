const std = @import("std");
const neonwood = @import("modules/neonwood.zig");
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
const MakeName = core.MakeName;
const mul = core.zm.mul;
const JobContext = core.JobContext;
const JobWorker = core.JobWorker;
const JobManager = core.JobManager;

const TextureAssets = [_]AssetReference{
    .{ .name = core.MakeName("t_sprite"), .path = "content/singleSpriteTest.png" },
    .{ .name = core.MakeName("t_lost_empire"), .path = "content/lost_empire-RGBA.png" },
};

const MeshAssets = [_]AssetReference{
    .{ .name = core.MakeName("m_monkey"), .path = "content/monkey.obj" },
    .{ .name = core.MakeName("m_room"), .path = "content/SCUFFED_Room.obj" },
    .{ .name = core.MakeName("m_empire"), .path = "content/lost_empire.obj" },
};

var gGame: *GameContext = undefined;
const jobTestCount = 1000;

// primarily a test file that exists to create a simple application for
// basic engine onboarding
const GameContext = struct {
    const Self = @This();
    pub const NeonObjectTable = core.RttiData.from(Self);

    allocator: std.mem.Allocator,
    wakeCount: u32 = 100,
    jobContext: JobContext,
    timeTilWake: f64 = 2.0,
    jobComplete: bool = false,
    jobWorker: *JobWorker,
    count: std.atomic.Atomic(u32) = std.atomic.Atomic(u32).init(0),
    complete: [jobTestCount]bool = std.mem.zeroes([jobTestCount]bool),

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .jobComplete = false,
            .allocator = allocator,
            .jobWorker = JobWorker.init(allocator) catch unreachable,
            .jobContext = undefined,
        };

        self.jobWorker.workerId = 0xffff;

        return self;
    }

    pub fn prepare(self: *Self) !void {
        self.jobComplete = true;
        const Wanker = struct {
            value: u32 = 42069,
        };

        var wanker = Wanker{};

        const Lambda = struct {
            capturedValue: u32 = 43,
            wanker: Wanker,
            game: *GameContext,

            pub fn func(ctx: @This(), job: *JobContext) void {
                std.debug.print("nice this is a job: {any}\n", .{ctx.wanker});
                std.time.sleep(1000 * 1000 * 1000);
                var v = ctx.game.count.fetchAdd(1, .SeqCst);
                std.debug.print("job done!{d} {d}\n", .{ ctx.wanker.value, v });
                ctx.game.complete[@intCast(usize, ctx.wanker.value)] = true;
                _ = job;
            }
        };

        self.jobContext = try JobContext.new(
            std.heap.c_allocator,
            Lambda,
            .{
                .wanker = wanker,
                .game = self,
            },
        );

        var x: u32 = 0;
        while (x < jobTestCount) : (x += 1) {
            core.engine_log("creating job: {d}", .{x});
            try core.dispatchJob(Lambda{ .wanker = .{ .value = x }, .game = self });
        }
    }

    pub fn tick(self: *Self, deltaTime: f64) void {
        _ = deltaTime;

        core.traceFmtDefault("ticking!", .{}) catch unreachable;

        if (self.timeTilWake <= 0) {
            self.timeTilWake = 0.5;
            self.wakeCount -= 1;
            core.engine_log("tick {d}", .{self.count.load(.SeqCst)});
            var i: usize = 0;

            while (i < jobTestCount) : (i += 1) {
                var d = @bitCast(u1, self.complete[i]);
                std.debug.print("{d}", .{d});
            }
            std.debug.print("\n", .{});
            core.engine_logs("endTick");
        }

        self.timeTilWake -= 0.1;
        std.time.sleep(1000 * 1000 * 100);

        if (self.count.load(.SeqCst) >= jobTestCount) {
            var i: usize = 0;
            while (i < jobTestCount) : (i += 1) {
                var d = @bitCast(u1, self.complete[i]);
                std.debug.print("{d}", .{d});
            }
            std.debug.print("\n", .{});

            core.gEngine.tracesContext.defaultTrace.printTraceStats(self.allocator);
            core.gEngine.exit();
        }

        if (self.wakeCount <= 0) {
            core.gEngine.exit();
        }
    }

    pub fn shutdown(self: *Self) void {
        _ = self;
    }
};

pub fn main() anyerror!void {
    engine_log("Starting up", .{});
    core.start_module();
    defer core.shutdown_module();

    // Setup the game
    var game = try core.createObject(GameContext, .{ .can_tick = true });
    try game.prepare();
    defer game.shutdown();

    // run the game
    core.gEngine.run();
}
