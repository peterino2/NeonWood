const std = @import("std");
const NeonWood = @import("NeonWood");
const core = NeonWood.core;
const panickers = core.panickers;

const realMain = @import("main");

pub const std_options = std.Options{
    .enable_segfault_handler = false,
};

//pub const build_options = @import("build_options");
//pub const tracy_enabled = build_options.tracy_enabled;

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, x: ?usize) noreturn {
    core.forceFlush();
    std.debug.panicImpl(error_return_trace, x, msg);
}

pub fn main() !void {
    panickers.attachSegfaultHandler();
    try realMain.main();
}
