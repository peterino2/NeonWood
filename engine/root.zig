pub const neonwood = @import("modules/neonwood.zig");
const std = @import("std");
const panickers = @import("modules/panickers.zig");
const core = @import("modules/core.zig");

const realMain = @import("main");

pub const std_options = struct {
    pub const enable_segfault_handler: bool = false;
};

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, x: ?usize) noreturn {
    core.forceFlush();
    std.debug.panicImpl(error_return_trace, x, msg);
}

pub fn main() !void {
    panickers.attachSegfaultHandler();
    try realMain.main();
}
