const std = @import("std");
const core = @import("core");
const windowing = @import("windowing.zig");

// GameInput implements the RawInputListenerInterface
// This is a data driven input system where mappings are defined,
// and keys are assigned to mapping contexts

pub const GameInputSystem = struct {
    pub const RawInputListenerVTable = windowing.RawInputListenerInterface.from(@This());

    stub: u32 = 0,

    pub fn OnIoEvent(self: *@This(), event: windowing.IOEvent) windowing.InputListenerError!void {
        _ = event;
        _ = self;
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
    }
};
