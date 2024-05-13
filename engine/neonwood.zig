pub const assets = @import("assets");
pub const audio = @import("audio");
pub const core = @import("core");
pub const graphics = @import("graphics");
pub const platform = @import("platform");
pub const papyrus = @import("papyrus");
pub const ui = @import("ui");

const std = @import("std");

pub const NwArgs = struct {
    useGPA: bool = false,
    vulkanValidation: bool = true,
    fastTest: bool = false,
    renderThread: bool = false,
};

pub fn getArgs() !NwArgs {
    const a = try core.ParseArgs(NwArgs);

    return a;
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
    try platform.start_module(std.heap.c_allocator, params); // 2
    assets.start_module(allocator); // 3
    audio.start_module(allocator); //4
    graphics.start_module(allocator); //5
    try ui.start_module(allocator); //6
}

pub fn shutdown_everything(allocator: std.mem.Allocator) void {
    ui.shutdown_module(); //6
    graphics.shutdown_module(); //5
    audio.shutdown_module(); //4
    assets.shutdown_module(allocator); //3
    platform.shutdown_module(allocator); //2
    core.shutdown_module(allocator); // 1
}

pub fn run_everything(comptime T: type) !void {
    var gameContext = try core.createObject(T, .{ .can_tick = true });
    try gameContext.prepare_game();

    try core.gEngine.run();

    while (!core.gEngine.exitFinished()) {
        platform.getInstance().pollEvents();
        std.time.sleep(1000 * 1000 * 10);
    }
}
