const std = @import("std");

const vk_renderer = @import("vk_renderer.zig");
const core = @import("../core.zig");

const DebugUiContext = struct {
    pub const InterfaceUiTable = core.InterfaceUiData.from(@This());

    show: bool = false,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) @This() {
        var self = .{
            .show = false,
            .allocator = allocator,
        };

        return self;
    }

    pub fn uiTick(self: *@This(), deltaTime: f64) void {
        _ = self;
        _ = deltaTime;
    }

    pub fn showDebug(self: *@This()) void {
        self.show = true;
    }
};
