pub const core = @import("core.zig");
pub const graphics = @import("graphics.zig");
pub const assets = @import("assets.zig");
pub const audio = @import("audio.zig");
pub const platform = @import("platform.zig");
pub const ui = @import("ui.zig");
pub const memory = @import("memory.zig");

const std = @import("std");

const c = graphics.c;

pub const NwArgs = struct {
    useGPA: bool = false,
    vulkanValidation: bool = true,
};

pub fn getArgs() !NwArgs {
    var a = try core.ParseArgs(NwArgs);

    return a;
}

var gTestFileDialogue: bool = false;

pub fn testFileDialogue() void {
    core.engine_logs("testing");
    gTestFileDialogue = true;
}

pub fn start_everything(allocator: std.mem.Allocator, params: platform.windowing.PlatformParams) !void {
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

pub fn run_with_context(comptime T: type, input_callback: anytype) !void {
    var gameContext = try core.createObject(T, .{ .can_tick = true });
    try gameContext.prepare_game();

    // run the game
    core.gEngine.run();
    _ = platform.c.glfwSetKeyCallback(platform.getInstance().window, input_callback);

    while (!core.gEngine.exitConfirmed) {
        if (gTestFileDialogue) {
            gTestFileDialogue = false;
            var x: [*c]u8 = null;
            _ = core.nfd.c.NFD_PickFolder(".", &x);
        }
        graphics.getContext().pollEventsFunc();
    }
}

pub fn run_no_input_tickable(comptime T: type) !void {
    var gameContext = try core.createObject(T, .{ .can_tick = true });
    try gameContext.prepare_game();

    // run the game
    try core.gEngine.run();

    while (!core.gEngine.exitConfirmed) {
        if (gTestFileDialogue) {
            core.engine_logs("Opening file picker");
            gTestFileDialogue = false;
            var x: [*c]u8 = null;
            _ = core.nfd.c.NFD_PickFolder("C:\\", &x);
            core.engine_log("selected folder: {s}", .{x});
        }
        platform.getInstance().pollEvents();
        std.time.sleep(1000 * 1000 * 10);
    }
}

pub fn run_no_input(comptime T: type) !void {
    var gameContext = try core.createObject(T, .{});
    try gameContext.prepare_game();

    // run the game
    try core.gEngine.run();

    while (!core.gEngine.exitSignal) {
        if (gTestFileDialogue) {
            core.engine_logs("Opening file picker");
            gTestFileDialogue = false;
            var x: [*c]u8 = null;
            _ = core.nfd.c.NFD_PickFolder(".", &x);
        }
        platform.getInstance().pollEvents();
    }
}
