// main public facing root file for core

const std = @import("std");

pub usingnamespace @import("misc.zig");
pub usingnamespace @import("logging.zig");
pub usingnamespace @import("engineTime.zig");
pub usingnamespace @import("rtti.zig");
pub usingnamespace @import("jobs.zig");
pub usingnamespace @import("file_utils.zig");
pub usingnamespace @import("string_utils.zig");
pub usingnamespace @import("type_utils.zig");
pub const engine = @import("engine.zig");
pub const tracy = @import("tracy");

pub const zm = @import("zmath");
pub usingnamespace @import("p2");
const algorithm = @import("p2");
pub const nfd = @import("nfd");
pub usingnamespace @import("math.zig");
pub usingnamespace @import("string.zig");
pub usingnamespace @import("args.zig");
pub usingnamespace @import("file_dialogue.zig");

pub const scene = @import("scene.zig");
pub const SceneSystem = scene.SceneSystem;

pub const Engine = engine.Engine;

const Name = algorithm.Name;
pub const spng = @import("spng");

pub const assert = std.debug.assert;

pub const MemoryTracker = @import("MemoryTracker.zig");

const logging = @import("logging.zig");
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
