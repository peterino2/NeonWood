pub const core = @import("core");
pub const platform = @import("platform");
pub const assets = @import("assets");
pub const audio = @import("audio");
pub const graphics = @import("graphics");
pub const vkImgui = @import("vkImgui");
pub const ui = @import("ui");

pub const papyrus = @import("papyrus");

const modulelist = @import("modulelist.zig").list;

const std = @import("std");

pub const NwArgs = struct {
    useGPA: bool = true,
    vulkanValidation: bool = true,
    fastTest: bool = false,
    renderThread: bool = false,
};

pub fn getArgs() !NwArgs {
    const a = try core.ParseArgs(NwArgs);

    return a;
}

// entry function for a neonwood program
// when this function is called it will use the settings specified by the program spec
// to conditionally start up feature modules within the engine

var shutdownList: std.ArrayListUnmanaged(*const fn (std.mem.Allocator) void) = .{};

pub fn start_modules(comptime programSpec: anytype, args: anytype, allocator: std.mem.Allocator) !void {
    const NeonWood = @This();

    inline for (modulelist) |feature| {
        if (@hasDecl(NeonWood, feature)) {
            const Struct = @field(NeonWood, feature);
            if (comptime core.isModuleEnabled(Struct.Module, programSpec)) {
                try Struct.start_module(programSpec, args, allocator);
                try shutdownList.append(allocator, Struct.shutdown_module);
                core.engine_logs("module started >>>> " ++ feature ++ " <<<<");
            }
        }
    }
}

pub fn shutdown_modules(allocator: std.mem.Allocator) void {
    var i: isize = @intCast(shutdownList.items.len - 1);
    while (i >= 0) : (i -= 1) {
        shutdownList.items[@intCast(i)](allocator);
    }
    shutdownList.deinit(allocator);
}

pub fn start_everything(comptime spec: anytype, allocator: std.mem.Allocator, maybeArgs: ?NwArgs) !void {
    if (maybeArgs) |args| {
        if (args.renderThread)
            graphics.setStartupSettings("useSeperateRenderThread", true);
        if (args.vulkanValidation)
            graphics.setStartupSettings("vulkanValidation", true);
    }

    try start_modules(spec, maybeArgs, allocator);
}

pub fn shutdown_everything(allocator: std.mem.Allocator) void {
    shutdown_modules(allocator);
}

pub fn run_everything(comptime GameContext: type) !void {
    var canTick: bool = false;

    if (@hasDecl(GameContext, "tick")) {
        canTick = true;
    }

    var gameContext = try core.createObject(GameContext, .{ .can_tick = canTick });

    if (@hasDecl(GameContext, "prepare_game")) {
        gameContext.prepare_game() catch @panic("Unable to run base level prepare script");
    } else if (@hasDecl(GameContext, "prepare")) {
        gameContext.prepare() catch @panic("Unable to run base level prepare script");
    }

    try core.gEngine.run();

    while (!core.gEngine.exitFinished()) {
        const z = core.tracy.ZoneN(@src(), "shutdown poll");
        platform.getInstance().pollEvents();
        z.End();
    }
}

pub fn initializeAndRunStandardProgram(comptime GameContext: type, comptime spec: anytype) !void {
    const args = try getArgs();

    var backingAllocator: std.mem.Allocator = std.heap.c_allocator;
    var gpa: std.heap.GeneralPurposeAllocator(.{
        .stack_trace_frames = 20,
    }) = .{};

    defer {
        const cleanupStatus = gpa.deinit();
        if (cleanupStatus == .leak) {
            std.debug.print("gpa cleanup leaked memory\n", .{});
        }
    }

    if (args.useGPA) {
        backingAllocator = gpa.allocator();
    }

    const memory = core.MemoryTracker;
    memory.MTSetup(backingAllocator);
    defer memory.MTShutdown();

    var tracker = memory.MTGet().?;
    const allocator = tracker.allocator();

    if (args.vulkanValidation) {
        core.engine_logs("Using vulkan validation");
    }

    graphics.setStartupSettings("vulkanValidation", args.vulkanValidation);

    try start_everything(spec, allocator, args);
    defer shutdown_everything(allocator);

    try run_everything(GameContext);
}
