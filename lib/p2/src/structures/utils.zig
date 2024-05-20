const std = @import("std");

pub fn createFileWithPath(filePath: []const u8) !std.fs.File {
    var splitEndIterator = std.mem.splitBackwardsAny(u8, filePath, "\\/");

    if (splitEndIterator.next()) |first| {
        const newSlice = filePath[0 .. filePath.len - first.len];
        std.debug.print("ensuring Dir is created {s}\n", .{newSlice});
        try std.fs.cwd().makePath(newSlice);
    }

    // create file
    const file = try std.fs.cwd().createFile(filePath, .{ .read = true, .truncate = true });
    return file;
}

pub fn loadFileAlloc(filename: []const u8, comptime alignment: usize, allocator: std.mem.Allocator) ![]u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    const filesize = (try file.stat()).size;
    const buffer: []u8 = try allocator.alignedAlloc(u8, alignment, filesize);
    try file.reader().readNoEof(buffer);
    return buffer;
}

pub fn grapvizDotToPng(allocator: std.mem.Allocator, vizFile: []const u8, pngFile: []const u8) !void {
    const sourceFile = try std.fmt.allocPrint(allocator, "Saved/{s}", .{vizFile});
    defer allocator.free(sourceFile);

    const imageFile = try std.fmt.allocPrint(allocator, "Saved/{s}", .{pngFile});
    defer allocator.free(imageFile);

    var childProc = std.ChildProcess.init(&.{ "dot", "-Tpng", sourceFile, "-o", imageFile }, allocator);
    try childProc.spawn();
}

pub fn dupeString(allocator: std.mem.Allocator, string: []const u8) ![]u8 {
    const dupe = try allocator.alloc(u8, string.len);

    std.mem.copyForwards(u8, dupe, string);

    return dupe;
}

pub const FileLog = struct {
    buffer: std.ArrayList(u8),
    allocator: std.mem.Allocator,
    fileName: []u8,

    pub fn init(allocator: std.mem.Allocator, fileName: []const u8) !@This() {
        return .{
            .buffer = std.ArrayList(u8).init(allocator),
            .allocator = allocator,
            .fileName = try dupeString(allocator, fileName),
        };
    }

    pub fn write(self: *@This(), comptime fmt: []const u8, args: anytype) !void {
        var writer = self.buffer.writer();
        try writer.print(fmt, args);
    }

    pub fn writeOut(self: @This()) !void {
        const cwd = std.fs.cwd();
        const ofile = try std.fmt.allocPrint(self.allocator, "Saved/{s}", .{self.fileName});
        defer self.allocator.free(ofile);
        try cwd.makePath("Saved");
        try cwd.writeFile(ofile, self.buffer.items);
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.fileName);
        self.buffer.deinit();
    }
};

pub fn assertf(eval: anytype, comptime fmt: []const u8, args: anytype) !void {
    if (!eval) {
        std.debug.print("\n\n[Error]: " ++ fmt ++ "\n\n", args);
        return error.AssertFailure;
    }
}

pub fn asserts(eval: anytype, comptime fmt: []const u8, args: anytype, comptime tag: []const u8) void {
    if (!eval) {
        std.debug.print("[Error]: " ++ fmt, args);
        std.debug.print("> " ++ tag, .{});
        @panic("assertion failed");
    }
}

pub fn assert(eval: anytype) !void {
    if (!eval) {
        return error.AssertFailure;
    }
}
