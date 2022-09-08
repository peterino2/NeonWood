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

// primarily a test file that exists to create a simple application for
// basic engine onboarding
const GameContext = struct {
    const Self = @This();
    pub const NeonObjectTable = core.RttiData.from(Self);

    allocator: std.mem.Allocator,
    jobComplete: bool = false,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{ .jobComplete = false, .allocator = allocator };

        return self;
    }

    pub fn prepare(self: *Self) !void {
        self.jobComplete = true;
        const Wanker = struct {
            value: u32 = 42069,
        };

        var wanker = Wanker{};
        std.debug.print("what the func\n", .{});

        _ = Wanker;
        _ = wanker;
        const Lambda = struct {
            capturedValue: u32 = 43,
            wanker: *const Wanker,

            pub fn func(ctx: @This(), job: *JobContext) void {
                std.debug.print("nice {any}\n", .{ctx});
                _ = job;
            }
        };
        _ = Lambda;

        var jobContext = try JobContext.new(
            std.heap.c_allocator,
            Lambda,
            .{
                .wanker = &wanker,
            },
        );
        _ = jobContext;

        jobContext.func(jobContext.capture.ptr, &jobContext);

        defer jobContext.deinit();
    }

    pub fn tick(self: *Self, deltaTime: f64) void {
        _ = deltaTime;

        if (self.jobComplete)
            core.gEngine.exit();
    }
};

pub fn main() anyerror!void {
    engine_log("Starting up", .{});
    core.start_module();
    defer core.shutdown_module();

    // Setup the game
    var game = try core.createObject(GameContext, .{ .can_tick = true });
    try game.prepare();

    // run the game
    core.gEngine.run();
}
