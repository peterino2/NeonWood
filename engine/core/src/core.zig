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
pub const algorithm = @import("p2");
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

const logs = logging.engine_logs;
const log = logging.engine_log;

pub const packer = @import("packer");

pub const FileSystem = packer.PackerFS;
const PackerFS = packer.PackerFS;

var gPackerFS: *PackerFS = undefined;

pub var gScene: *SceneSystem = undefined;

pub const ecs = @import("ecs.zig");
pub usingnamespace ecs;

pub const script = @import("script.zig");

pub fn fs() *PackerFS {
    return gPackerFS;
}

pub const Module = ModuleDescription{
    .name = "core",
    .enabledByDefault = true,
};

pub fn start_module(comptime programSpec: anytype, args: anytype, allocator: std.mem.Allocator) !void {
    _ = args;
    _ = programSpec;
    _ = try algorithm.createNameRegistry(allocator);
    // LUA BEGIN -- what if i want to make the scripting integration optional?
    try script.start_lua(allocator);
    // LUA END
    gPackerFS = try PackerFS.init(allocator, .{});
    gEngine = try allocator.create(Engine);
    gEngine.* = try Engine.init(allocator);

    try logging.setupLogging(gEngine);

    try ecs.setup(allocator);

    gScene = try gEngine.createObject(scene.SceneSystem, .{ .can_tick = true });

    try algorithm.string_pool.setup(allocator);

    logs("core module starting up... ");
    return;
}

pub fn shutdown_module(_: std.mem.Allocator) void {
    logs("core module shutting down...");
    logging.shutdownLogging();
    ecs.shutdown();

    algorithm.destroyNameRegistry();
    gEngine.deinit();
    gPackerFS.destroy();
    // LUA BEGIN
    script.shutdown_lua();
    // LUA END
    algorithm.string_pool.shutdown();
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

pub fn exitNow() void {
    signalShutdown();
}

pub fn signalShutdown() void {
    gEngine.exit();
}

pub fn getEngine() *Engine {
    return gEngine;
}

pub fn BuildOption(comptime option: []const u8) bool {
    if (@hasDecl(@import("root"), "options")) {
        const r = @import("root").options;
        if (@hasDecl(r, option)) {
            return @field(r, option);
        } else {
            return false;
        }
    }
    return false;
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

const getEngineTime = @import("engineTime.zig").getEngineTime;

pub fn getEngineUptime() f64 {
    return getEngineTime() - gEngine.engineStartTime;
}

pub const modules = @import("modules.zig");
pub const isModuleEnabled = modules.isModuleEnabled;
pub const ModuleDescription = modules.ModuleDescription;
