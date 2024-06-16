// TODO --- this should become it's own engine module
const std = @import("std");
const spng = @import("spng");

const core = @import("core.zig");

pub const PngContents = struct {
    path: []const u8,
    pixels: []u8,
    size: core.Vector2u,
    allocator: std.mem.Allocator,

    pub fn initFromFS(fs: *core.FileSystem, allocator: std.mem.Allocator, path: []const u8) !@This() {
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
