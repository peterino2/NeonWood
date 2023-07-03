const std = @import("std");
const core = @import("core.zig");
const spng = @import("core/lib/zig-spng/spng.zig");

pub const PngContents = struct {
    path: []const u8,
    pixels: []u8,
    size: core.Vector2u,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, filePath: []const u8) !@This() {
        var pngFileContents = try core.loadFileAlloc(filePath, 8, allocator);
        var decoder = try spng.SpngContext.newDecoder();
        defer decoder.deinit();

        try decoder.setBuffer(pngFileContents);
        const header = try decoder.getHeader();

        var imageSize = @as(usize, @intCast(header.width * header.height * 4));
        core.graphics_log("loaded png {s}, dimensions={d}x{d}", .{ filePath, header.width, header.height });
        var pixels: []u8 = try allocator.alloc(u8, imageSize);
        var len = try decoder.decode(pixels, spng.SPNG_FMT_RGBA8, spng.SPNG_DECODE_TRNS);
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
