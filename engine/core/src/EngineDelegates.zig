// contains various engine callbacks for other modules to hook into.
// these are ALL called on the system thread.

allocator: std.mem.Allocator,
onFrameDebugInfoEmitted: std.ArrayListUnmanaged(OnFrameDebugInfoEmitted) = .{},

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{
        .allocator = allocator,
    };
}

pub fn deinit(self: *@This()) void {
    self.onFrameDebugInfoEmitted.deinit(self.allocator);
}

const std = @import("std");
const engineObject = @import("engineObject.zig");
const EngineDataEventError = engineObject.EngineDataEventError;

// callback definition for a function which updates engine frametime.
const OnFrameDebugInfoEmitted = struct {
    ctx: *anyopaque,
    func: *const fn (
        *anyopaque, // active context
        f64, //
    ) EngineDataEventError!void,
};
