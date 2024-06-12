// main public facing root file for core

const std = @import("std");

pub usingnamespace @import("misc.zig");
pub usingnamespace @import("logging.zig");
pub usingnamespace @import("engineTime.zig");
pub usingnamespace @import("engineObject.zig");
pub usingnamespace @import("jobs.zig");
pub usingnamespace @import("file_utils.zig");
pub usingnamespace @import("string_utils.zig");
pub usingnamespace @import("type_utils.zig");
pub const engine = @import("engine.zig");
pub const tracy = @import("tracy");
pub const png = @import("png.zig");

pub const colors = @import("colors.zig");

pub const zm = @import("zmath");
pub usingnamespace @import("p2");
const algorithm = @import("p2");
pub const nfd = @import("nfd");
pub usingnamespace @import("math.zig");
pub usingnamespace @import("args.zig");
pub usingnamespace @import("file_dialogue.zig");

pub const panickers = @import("panickers.zig");
pub const scene = @import("scene.zig");
pub const SceneSystem = scene.SceneSystem;

pub const Engine = engine.Engine;

const Name = algorithm.Name;
pub const spng = @import("spng");

pub const MemoryTracker = @import("MemoryTracker.zig");

const logging = @import("logging.zig");
const c = @This();

//pub const build_options = @import("root").build_options;

const logs = logging.engine_logs;
const log = logging.engine_log;

pub const packer = @import("packer");

pub const FileSystem = packer.PackerFS;
const PackerFS = packer.PackerFS;

var gPackerFS: *PackerFS = undefined;

pub var gScene: *SceneSystem = undefined;

pub fn fs() *PackerFS {
    return gPackerFS;
}

pub fn start_module(allocator: std.mem.Allocator) void {
    _ = algorithm.createNameRegistry(allocator) catch unreachable;
    gPackerFS = PackerFS.init(allocator, .{}) catch @panic("unable to initialize packerfs");
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
    gPackerFS.destroy();
    return;
}

pub fn dispatchJob(capture: anytype) !void {
    try gEngine.jobManager.newJob(capture);
}

pub var gEngine: *Engine = undefined;

pub fn createObject(comptime T: type, params: engine.NeonObjectParams) !*T {
    return gEngine.createObject(T, params);
}

pub fn setupEnginePlatform(ctx: *anyopaque, poll: engine.PollFuncFn, proc: engine.ProcEventsFn) void {
    gEngine.platformPollFunc = poll;
    gEngine.platformCtx = ctx;
    gEngine.platformProcEventsFunc = proc;
}

pub fn signalShutdown() void {
    gEngine.exit();
}

pub fn getEngine() *Engine {
    return gEngine;
}

const EngineDelegates = @import("EngineDelegates.zig");

// binds a function + a context to
pub fn addEngineDelegateBinding(comptime event: []const u8, func: anytype, ctx: *anyopaque) !usize {
    if (!@hasField(EngineDelegates, event)) {
        @compileError("Engine does not have delegate " ++ event);
    }

    const handle = @field(gEngine.delegates, event).items.len;
    try @field(gEngine.delegates, event).append(gEngine.delegates.allocator, .{ .func = func, .ctx = ctx });

    return handle;
}

// pub fn removeBinding todo...
