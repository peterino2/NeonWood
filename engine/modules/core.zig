pub usingnamespace @import("core/misc.zig");
pub usingnamespace @import("core/logging.zig");
pub usingnamespace @import("core/algorithm.zig");
pub usingnamespace @import("core/engineTime.zig");
pub usingnamespace @import("core/rtti.zig");
pub usingnamespace @import("core/jobs.zig");
pub const engine = @import("core/engine.zig");
pub const zm = @import("core/lib/zmath/zmath.zig");
pub usingnamespace @import("core/math.zig");
pub usingnamespace @cImport({
    @cInclude("stb/stb_image.h");
});
pub const names = @import("core/names.zig");
pub const Name = names.Name;
pub const MakeName = names.MakeName;
pub const Engine = engine.Engine;

pub const assert = std.debug.assert;
pub const DefaultName = MakeName("default");

const trace = @import("core/trace.zig");
pub const TracesContext = trace.TracesContext;

const std = @import("std");
const tests = @import("core/tests.zig");
const logging = @import("core/logging.zig");
const vk = @import("vulkan");
const c = @This();

pub fn assertf(eval: anytype, comptime fmt: []const u8, args: anytype) !void
{
    if(!eval)
    {
        logging.engine_err(fmt, args);
        return error.AssertFailure;
    }
}


const logs = logging.engine_logs;
const log = logging.engine_log;

pub fn start_module() void {
    gEngine = gEngineAllocator.create(Engine) catch unreachable;
    gEngine.* = Engine.init(gEngineAllocator) catch unreachable;

    logs("core module starting up... ");
    return;
}

pub fn run() void {}

pub fn shutdown_module() void {
    gEngineAllocator.destroy(gEngine);
    logs("core module shutting down...");
    return;
}

pub fn dispatchJob(capture: anytype) !void {
    try gEngine.jobManager.newJob(capture);
}

pub var gEngineAllocator: std.mem.Allocator = std.heap.c_allocator;
pub var gEngine: *Engine = undefined;

pub const createObject = engine.createObject;

pub fn traceFmt(name: Name, comptime fmt: []const u8, args: anytype) !void {
    try gEngine.tracesContext.traces.getEntry(name.hash).?.value_ptr.*.traceFmt(
        gEngine.tracesContext.allocator,
        fmt,
        args,
    );
}

pub fn traceFast(name: Name, comptime fmt: )
{
    trace.DefaultTrace.trace
}

pub fn traceFmtDefault(comptime fmt: []const u8, args: anytype) !void {
    try traceFmt(DefaultName, fmt, args);
}
