usingnamespace @import("misc.zig");
usingnamespace @import("logging.zig");
usingnamespace @import("algorithm.zig");
usingnamespace @import("engineTime.zig");
const engine = @import("engine.zig");
pub const zm = @import("lib/zmath/zmath.zig");
pub const math = @import("math.zig");
pub usingnamespace @cImport({
    @cInclude("stb/stb_image.h");
});
pub const Engine = engine.Engine;

const std = @import("std");
const tests = @import("tests.zig");

const logging = @import("logging.zig");

const logs = logging.engine_logs;
const log = logging.engine_log;

const vk = @import("vulkan");
const c = @This();

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

pub var gEngineAllocator: std.mem.Allocator = std.heap.c_allocator;
pub var gEngine: *Engine = undefined;
