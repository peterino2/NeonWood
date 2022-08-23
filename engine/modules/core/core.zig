pub usingnamespace @import("misc.zig");
pub usingnamespace @import("logging.zig");
pub usingnamespace @import("algorithm.zig");
pub usingnamespace @import("engineTime.zig");
pub usingnamespace @import("rtti.zig");
pub const engine = @import("engine.zig");
pub const zm = @import("lib/zmath/zmath.zig");
pub usingnamespace @import("math.zig");
pub usingnamespace @cImport({
    @cInclude("stb/stb_image.h");
});
pub const names = @import("names.zig");
pub const Name = names.Name;
pub const MakeName = names.MakeName;
pub const Engine = engine.Engine;
const std = @import("std");
const tests = @import("tests.zig");
const logging = @import("logging.zig");
const vk = @import("vulkan");
const c = @This();

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

pub var gEngineAllocator: std.mem.Allocator = std.heap.c_allocator;
pub var gEngine: *Engine = undefined;

pub const assert = std.debug.assert;
