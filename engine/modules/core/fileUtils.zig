const std = @import("std");

// Higher level file functions.
pub fn load_file_alloc(filename: []const u8, comptime alignment: usize, allocator: std.mem.Allocator) ![]const u8 {
    var file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    const filesize = (try file.stat()).size;
    var buffer: []u8 = try allocator.allocAdvanced(u8, @intCast(u29, alignment), filesize, .exact);
    try file.reader().readNoEof(buffer);
    return buffer;
}

test "file-0-basic-load-file" {
    const x = try load_file_alloc("./file.zig", 1, std.testing.allocator);
    defer std.testing.allocator.free(x);

    std.debug.print("{s}", .{x});
}
