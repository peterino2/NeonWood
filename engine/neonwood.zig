pub const assets = @import("assets");
pub const audio = @import("audio");
pub const core = @import("core");
pub const graphics = @import("graphics");
pub const platform = @import("platform");
pub const papyrus = @import("papyrus");
pub const ui = @import("ui");
pub const vkImgui = @import("vkImgui");

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

pub fn start_everything_imgui(allocator: std.mem.Allocator, params: platform.windowing.PlatformParams, maybeArgs: ?NwArgs) !void {
    if (maybeArgs) |args| {
        if (args.renderThread)
            graphics.setStartupSettings("useSeperateRenderThread", true);
        if (args.vulkanValidation)
            graphics.setStartupSettings("vulkanValidation", true);
    }

    graphics.setWindowName(params.windowName);

    core.engine_log("Starting up", .{});
    core.start_module(allocator); // 1
    try platform.start_module(allocator, params); // 2
    assets.start_module(allocator); // 3
    // audio.start_module(allocator); //4
    graphics.start_module(allocator); //5
    try ui.start_module(allocator); //6
    try vkImgui.start_module(allocator); //7 vkImgui doesn't work in the renderthread implementation yet
}

pub fn shutdown_everything_imgui(allocator: std.mem.Allocator) void {
    vkImgui.shutdown_module(allocator); //7
    ui.shutdown_module(); //6
    graphics.shutdown_module(); //5
    // audio.shutdown_module(); //4
    assets.shutdown_module(allocator); //3
    platform.shutdown_module(allocator); //2
    core.shutdown_module(allocator); // 1
}

pub fn start_everything(allocator: std.mem.Allocator, params: platform.windowing.PlatformParams, maybeArgs: ?NwArgs) !void {
    if (maybeArgs) |args| {
        if (args.renderThread)
            graphics.setStartupSettings("useSeperateRenderThread", true);
        if (args.vulkanValidation)
            graphics.setStartupSettings("vulkanValidation", true);
    }

    graphics.setWindowName(params.windowName);

    core.engine_log("Starting up", .{});
    core.start_module(allocator); // 1
    try platform.start_module(allocator, params); // 2
    assets.start_module(allocator); // 3
    // audio.start_module(allocator); //4
    graphics.start_module(allocator); //5
    try ui.start_module(allocator); //6
}

pub fn shutdown_everything(allocator: std.mem.Allocator) void {
    ui.shutdown_module(); //6
    graphics.shutdown_module(); //5
    // audio.shutdown_module(); //4
    assets.shutdown_module(allocator); //3
    platform.shutdown_module(allocator); //2
    core.shutdown_module(allocator); // 1
}

pub fn run_everything(comptime GameContext: type) !void {
    var gameContext = try core.createObject(GameContext, .{ .can_tick = true });
    try gameContext.prepare_game();

    try core.gEngine.run();

    while (!core.gEngine.exitFinished()) {
        const z = core.tracy.ZoneN(@src(), "shutdown poll");
        platform.getInstance().pollEvents();
        z.End();
    }
}

const StandardProgramOptions = struct {
    programName: []const u8,
};

pub fn initializeAndRunStandardProgram(comptime GameContext: type, opts: StandardProgramOptions) !void {
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

    try start_everything_imgui(allocator, .{ .windowName = opts.programName }, args);
    defer shutdown_everything_imgui(allocator);

    try run_everything(GameContext);
}
