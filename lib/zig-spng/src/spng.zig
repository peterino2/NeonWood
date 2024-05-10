const std = @import("std");

const c = @cImport({
    @cInclude("stdlib.h");
    @cInclude("spng.h");
});

pub const spng_decode_flags = c.spng_decode_flags;

pub const SPNG_FMT_RGBA8 = c.SPNG_FMT_RGBA8;
pub const SPNG_FMT_RGBA16 = c.SPNG_FMT_RGBA16;
pub const SPNG_FMT_RGB8 = c.SPNG_FMT_RGB8;

pub const SPNG_DECODE_TRNS = c.SPNG_DECODE_TRNS;
pub const SPNG_DECODE_GAMMA = c.SPNG_DECODE_GAMMA;
pub const SPNG_DECODE_PROGRESSIVE = c.SPNG_DECODE_PROGRESSIVE;

pub const spng_ihdr = c.spng_ihdr;

const spng_errno = c.spng_errno;
const spng_text_type = c.spng_text_type;
const spng_color_type = c.spng_color_type;
const spng_filter = c.spng_filter;
const spng_filter_choice = c.spng_filter_choice;
const spng_interace_method = c.spng_interace_method;
const spng_format = c.spng_format;
const spng_ctx_flags = c.spng_ctx_flags;
const spng_crc_action = c.spng_crc_action;
const spng_encode_flags = c.spng_encode_flags;
const spng_plte_entry = c.spng_plte_entry;
const spng_plte = c.spng_plte;
const spng_trns = c.spng_trns;
const spng_chrm_int = c.spng_chrm_int;
const spng_iccp = c.spng_iccp;
const spng_sbit = c.spng_sbit;
const spng_text = c.spng_text;
const spng_bkgd = c.spng_bkgd;
const spng_hist = c.spng_hist;
const spng_phys = c.spng_phys;
const spng_splt_entry = c.spng_splt_entry;
const spng_splt = c.spng_splt;
const spng_time = c.spng_time;
const spng_offs = c.spng_offs;
const spng_exif = c.spng_exif;
const spng_chunk = c.spng_chunk;
const spng_location = c.spng_location;
const song_unknown_chunk = c.spng_unknown_chunk;
const spng_option = c.spng_option;

const spng_ctx = c.spng_ctx;

fn checkResult(res: c_int) !void {
    if (res != 0) {
        std.debug.print("string: {s}\n", .{std.mem.span(c.spng_strerror(res))});
        return error.InvalidResult;
    }
}

pub const SpngContext = struct {
    _ctx: *spng_ctx,

    pub fn newDecoder() !@This() {
        return .{
            ._ctx = c.spng_ctx_new(0) orelse return error.UnableToCreateSpngContext,
        };
    }

    pub fn newEncoder() !@This() {
        return .{
            ._ctx = c.spng_ctx_new(c.SPNG_CTX_ENCODER) orelse return error.UnableToCreateSpngContext,
        };
    }

    pub fn setBuffer(self: *@This(), buffer: []u8) !void {
        try checkResult(c.spng_set_png_buffer(self._ctx, buffer.ptr, buffer.len));
    }

    pub fn setFileRaw(self: @This(), file: *c.FILE) !void {
        const res = c.spng_set_png_file(self._ctx, file);
        try checkResult(res);
    }

    pub fn setFile(self: @This(), path: []const u8) !void {
        const file = c.fopen(path.ptr, "r");
        if (file == null) {
            return error.FileNotOpen;
        }
        _ = c.fseek(file, 0, c.SEEK_END);
        const sz = c.ftell(file);
        std.debug.print("file size: {s} {d}\n", .{ path, sz });
        c.rewind(file);

        try self.setFileRaw(file);
    }

    // decodes the image and writes to the out buffer.
    pub fn decode(self: *@This(), out: []u8, fmt: c_int, flags: c_int) !usize {
        var res = c.spng_decode_image(self._ctx, out.ptr, out.len, fmt, flags);
        try checkResult(res);
        var size: usize = 0;

        res = c.spng_decoded_image_size(self._ctx, fmt, &size);
        try checkResult(res);

        return size;
    }

    pub fn getHeader(self: *@This()) !spng_ihdr {
        var outHeader: spng_ihdr = undefined;

        try checkResult(c.spng_get_ihdr(self._ctx, &outHeader));

        return outHeader;
    }

    // TODO: sets png stream
    // pub fn setPngStream(self: *@This(), : spng_rw_fn) !void {
    //     try checkResult(c.spng_set_png_buffer(self._ctx, buffer.ptr, buffer.len));
    // }

    pub fn deinit(self: *@This()) void {
        c.spng_ctx_free(self._ctx);
    }
};

pub fn loadFileAlloc(filename: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    const filesize = (try file.stat()).size;
    const buffer: []u8 = try allocator.alignedAlloc(u8, 8, filesize);
    try file.reader().readNoEof(buffer);
    return buffer;
}

test "spngtest" {
    const allocator = std.testing.allocator;
    const pngBuffer = try allocator.alloc(u8, 1000 * 1000 * 100);
    defer allocator.free(pngBuffer);

    var decoder = try SpngContext.newDecoder();
    defer decoder.deinit();
    try decoder.setBuffer(pngBuffer);

    const decodeBuffer = try allocator.alloc(u8, 500 * 1000 * 1000);
    defer allocator.free(decodeBuffer);

    var decoder2 = try SpngContext.newDecoder();
    defer decoder2.deinit();
    const buffer = try loadFileAlloc("testpng.png", allocator);
    defer allocator.free(buffer);

    try decoder2.setBuffer(buffer);

    const header = try decoder2.getHeader();

    std.debug.print("this is an error", .{});

    try std.testing.expect(header.width == 383);
    try std.testing.expect(header.height == 345);

    const len = try decoder2.decode(decodeBuffer, SPNG_FMT_RGBA8, SPNG_DECODE_TRNS);
    try std.testing.expect(len == 528540);

    var encoder = try SpngContext.newDecoder();
    defer encoder.deinit();
}
