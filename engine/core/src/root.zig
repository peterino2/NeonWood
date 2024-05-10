const std = @import("std");
const memory = @import("memory.zig");

pub usingnamespace @import("core/misc.zig");
pub usingnamespace @import("core/logging.zig");
pub usingnamespace @import("core/engineTime.zig");
pub usingnamespace @import("core/rtti.zig");
pub usingnamespace @import("core/jobs.zig");
pub usingnamespace @import("core/file_utils.zig");
pub usingnamespace @import("core/string_utils.zig");
pub usingnamespace @import("core/type_utils.zig");
pub const engine = @import("core/engine.zig");
pub const tracy = @import("core/lib/zig_tracy/tracy.zig");

pub const nfd = @import("core/lib/nfd/nfd.zig");
pub const zm = @import("core/lib/zmath/zmath.zig");
pub usingnamespace @import("core/lib/p2/algorithm.zig");
const algorithm = @import("core/lib/p2/algorithm.zig");
pub usingnamespace @import("core/math.zig");
pub usingnamespace @import("core/string.zig");
pub usingnamespace @import("core/args.zig");
pub usingnamespace @import("core/file_dialogue.zig");

// pub usingnamespace @import("core/mem_trackek.zig");
// pub const memory_tracker = @import("core/mem_tracker.zig");

pub const scene = @import("core/scene.zig");
pub const SceneSystem = scene.SceneSystem;

pub const Engine = engine.Engine;

const Name = algorithm.Name;
pub const spng = @import("core/lib/zig-spng/spng.zig");

pub const assert = std.debug.assert;

pub const MemoryTracker = @import("core/MemoryTracker.zig");

const tests = @import("core/tests.zig");
const logging = @import("core/logging.zig");
const vk = @import("vulkan");
const c = @This();

const logs = logging.engine_logs;
const log = logging.engine_log;

pub var gScene: *SceneSystem = undefined;

pub fn start_module(allocator: std.mem.Allocator) void {
    _ = algorithm.createNameRegistry(allocator) catch unreachable;
    gEngine = allocator.create(Engine) catch unreachable;
    gEngine.* = Engine.init(allocator) catch unreachable;

    gScene = gEngine.createObject(scene.SceneSystem, .{ .can_tick = true }) catch unreachable;

    logging.setupLogging(gEngine) catch unreachable;

    logs("core module starting up... ");
    memory.MTPrintStatsDelta();
    return;
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    _ = allocator;
    logs("core module shutting down...");
    logging.shutdownLogging();

    algorithm.destroyNameRegistry();
    gEngine.deinit();
    return;
}

pub fn dispatchJob(capture: anytype) !void {
    try gEngine.jobManager.newJob(capture);
}

pub var gEngine: *Engine = undefined;

pub fn createObject(comptime T: type, params: engine.NeonObjectParams) !*T {
    return gEngine.createObject(T, params);
}

pub fn setupEnginePoll(ctx: *anyopaque, func: engine.PollFuncFn) void {
    gEngine.platformPollFunc = func;
    gEngine.platformPollCtx = ctx;
}

pub fn signalShutdown() void {
    gEngine.exit();
}

pub fn getEngine() *Engine {
    return gEngine;
}
