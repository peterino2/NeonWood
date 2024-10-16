const std = @import("std");
const logging = @import("logging.zig");

pub fn writeToFile(data: []const u8, path: []const u8) !void {
    const file = try std.fs.cwd().createFile(
        path,
        .{
            .read = true,
        },
    );

    const bytes_written = try file.writeAll(data);
    _ = bytes_written;
    logging.engine_log("written: bytes to {s}", .{path});
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
