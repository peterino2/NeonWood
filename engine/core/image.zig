// TODO --- this should become it's own engine library?
const std = @import("std");
const spng = @import("spng");

const core = @import("core.zig");

pub const PngContents = struct {
    path: []const u8,
    pixels: []u8,
    size: core.Vector2u,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, filePath: []const u8) !@This() {
        const pngFileContents = try core.loadFileAlloc(filePath, 1, allocator);
        defer allocator.free(pngFileContents);
        var decoder = try spng.SpngContext.newDecoder();
        defer decoder.deinit();

        try decoder.setBuffer(pngFileContents);
        const header = try decoder.getHeader();

        const imageSize = @as(usize, @intCast(header.width * header.height * 4));
        core.graphics_log("loaded png {s}, dimensions={d}x{d}", .{ filePath, header.width, header.height });
        const pixels: []u8 = try allocator.alloc(u8, imageSize);
        const len = try decoder.decode(pixels, spng.SPNG_FMT_RGBA8, spng.SPNG_DECODE_TRNS);
        try core.assertf(len == pixels.len, "decoded pixel size not buffer size {d} != {d}", .{ len, pixels.len });

        return PngContents{
            .path = try core.dupe(u8, allocator, filePath),
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
