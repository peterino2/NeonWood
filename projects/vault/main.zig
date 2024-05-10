const std = @import("std");
const nw = @import("root").neonwood;
const core = nw.core;

var gExitSignal: bool = false;

const TaskError = error{ OutOfMemory, AssertFailed, Panic };

pub fn schedule(function: anytype, args: anytype) !void {
    _ = args;
    _ = function;

    core.engine_logs("scheduling new function");
}

pub fn newObject(
    comptime T: type,
    args: struct { allocator: std.mem.Allocator = std.heap.c_allocator },
) VaultRef {
    _ = args;
    _ = T;

    return .{};
}

const VaultRef = struct {
    handle: u32 = 0,
};

const Renderer = struct {
    frameCount: u32 = 0,

    pub fn renderFrame() !void {
        core.engine_logs("rendering frame");
        std.time.sleep(1000 * 1000 * 3);
    }
};

pub fn RenderTask(args: struct { v_renderer: VaultRef }) TaskError!void {
    var renderer = try args.v_renderer.extract(*Renderer);
    try renderer.do_render();
}

pub fn TickTask(args: struct { v_engine: VaultRef }) TaskError!void {
    var engine = try args.v_engine.extract(*core.Engine);
    _ = engine;
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .stack_trace_frames = 20,
    }){};

    defer {
        const cleanupStatus = gpa.deinit();
        if (cleanupStatus == .leak) {
            std.debug.print("gpa cleanup leaked memory\n", .{});
        }
    }

    core.start_module(gpa.allocator());
    defer core.shutdown_module(gpa.allocator());

    var rendererRef = newObject(Renderer, .{ .allocator = gpa.allocator() });

    while (!gExitSignal) {
        std.time.sleep(1000 * 1000 * 500);
        try schedule(RenderTask, rendererRef);
        try core.gEngine.tick();
    }
}
