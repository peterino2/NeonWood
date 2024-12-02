// TODO --- this should become it's own engine module
const std = @import("std");
const spng = @import("spng");

const core = @import("core.zig");

pub const PngContents = struct {
    path: []const u8,
    pixels: []u8,
    size: core.Vector2u,
    allocator: std.mem.Allocator,

    pub fn initFromFSCooked(fs: *core.FileSystem, allocator: std.mem.Allocator, path: []const u8) !@This() {
        const mapping = try fs.loadFile(path);
        defer fs.unmap(mapping);

        core.engine_log("loading cooked version of file: {s}", .{path});

        const rv: @This() = .{
            .size = .{
                .x = @as(u32, @bitCast(mapping.bytes[0..4].*)),
                .y = @as(u32, @bitCast(mapping.bytes[4..8].*)),
            },
            .path = try allocator.dupe(u8, path),
            .pixels = try allocator.dupe(u8, mapping.bytes[8..]),
            .allocator = allocator,
        };

        return rv;
    }

    pub fn toBuffer(self: @This()) !std.ArrayList(u8) {
        var buffer = std.ArrayList(u8).init(self.allocator);
        try buffer.appendSlice(&@as([4]u8, @bitCast(self.size.x)));
        try buffer.appendSlice(&@as([4]u8, @bitCast(self.size.y)));
        try buffer.appendSlice(self.pixels);

        return buffer;
    }

    pub fn initFromFS(fs: *core.FileSystem, allocator: std.mem.Allocator, path: []const u8) !@This() {
        // 1. check the fs to see if a cooked version of the file exists
        // 2. load that one if possible
        // 3. otherwise, load the other one.

        const mapping = try fs.loadFile(path);
        defer fs.unmap(mapping);

        return try initFromBytes(allocator, path, mapping.bytes);
    }

    pub fn initFromBytes(allocator: std.mem.Allocator, pathName: []const u8, pngFileContents: []const u8) !@This() {
        var decoder = try spng.SpngContext.newDecoder();
        defer decoder.deinit();

        try decoder.setBuffer(pngFileContents);
        const header = try decoder.getHeader();

        const imageSize = @as(usize, @intCast(header.width * header.height * 4));
        const pixels: []u8 = try allocator.alloc(u8, imageSize);
        const len = try decoder.decode(pixels, spng.SPNG_FMT_RGBA8, spng.SPNG_DECODE_TRNS);
        try core.assertf(len == pixels.len, "decoded pixel size not buffer size {d} != {d}", .{ len, pixels.len });

        return PngContents{
            .path = try core.dupe(u8, allocator, pathName),
            .pixels = pixels,
            .size = .{ .x = header.width, .y = header.height },
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.path);
        self.allocator.free(self.pixels);
    }
};
