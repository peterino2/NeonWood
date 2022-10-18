pub usingnamespace @import("core/misc.zig");
pub usingnamespace @import("core/logging.zig");
pub usingnamespace @import("core/algorithm.zig");
pub usingnamespace @import("core/engineTime.zig");
pub usingnamespace @import("core/rtti.zig");
pub usingnamespace @import("core/jobs.zig");
pub const engine = @import("core/engine.zig");
pub const tracy = @import("core/lib/Zig-Tracy/tracy.zig");
pub const zm = @import("core/lib/zmath/zmath.zig");
pub usingnamespace @import("core/math.zig");
pub usingnamespace @cImport({
    @cInclude("stb/stb_image.h");
});

pub const scene = @import("core/scene.zig");
pub const SceneSystem = scene.SceneSystem;

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

pub var gScene: *SceneSystem = undefined;

pub fn start_module() void {
    gEngine = gEngineAllocator.create(Engine) catch unreachable;
    gEngine.* = Engine.init(gEngineAllocator) catch unreachable;

    gScene = gEngine.createObject(scene.SceneSystem, .{.can_tick = true}) catch unreachable;

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

pub fn traceFmtDefault(comptime fmt: []const u8, args: anytype) !void {
    try traceFmt(DefaultName, fmt, args);
}

pub fn splitIntoLines(file_contents: []const u8) std.mem.SplitIterator(u8) {
    // find a \n and see if it has \r\n
    var index: u32 = 0;
    while (index < file_contents.len) : (index += 1) {
        if (file_contents[index] == '\n') {
            if (index > 0) {
                if (file_contents[index - 1] == '\r') {
                    return std.mem.split(u8, file_contents, "\r\n");
                } else {
                    return std.mem.split(u8, file_contents, "\n");
                }
            } else {
                return std.mem.split(u8, file_contents, "\n");
            }
        }
    }
    return std.mem.split(u8, file_contents, "\n");
}

pub fn loadFileAlloc(filename: []const u8, comptime alignment: usize, allocator: std.mem.Allocator) ![]const u8 {
    var file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    const filesize = (try file.stat()).size;
    var buffer: []u8 = try allocator.allocAdvanced(u8, @intCast(u29, alignment), @intCast(usize, filesize), .exact);
    try file.reader().readNoEof(buffer);
    return buffer;
}
