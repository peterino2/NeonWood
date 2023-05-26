const std = @import("std");

pub fn slowPrintln(comptime fmt: []const u8, args: anytype) void {
    std.io.getStdOut().writer().print(fmt ++ "\n", args) catch unreachable;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var currentPath = try std.fs.cwd().realpathAlloc(allocator, "./");
    defer allocator.free(currentPath);

    slowPrintln("hello nerd {s}", .{currentPath});
}
