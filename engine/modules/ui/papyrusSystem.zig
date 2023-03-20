const std = @import("std");
const core = @import("../core.zig");

pub const UiSystem = struct {
    pub const NeonObjectTable = core.RttiData.from(@This());

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .allocator = allocator,
        };
    }

    pub fn uiTick(self: *@This(), deltaTime: f64) void {
        _ = self;
        _ = deltaTime;
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
    }

    pub fn processEvents(self: *@This(), frameNumber: u64) core.RtttiEventData!void {
        _ = frameNumber;
        _ = self;
    }
};
