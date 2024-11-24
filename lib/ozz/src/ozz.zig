pub fn hello() void {
    std.debug.print("whatsup\n", .{});
}

pub extern fn testFunc() callconv(.C) void;
pub extern fn startupOzz() callconv(.C) void;
pub extern fn shutdownOzz() callconv(.C) void;

pub const std = @import("std");
