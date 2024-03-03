const std = @import("std");
const c = @import("c.zig");

const core = @import("root").neonwood.core;
const Vector2i = core.Vector2i;
const Vector2f = core.Vector2f;
const Name = core.Name;

const colors = @import("colors.zig");
const ColorRGBA8 = colors.ColorRGBA8;
const Color = colors.Color;

const LocText = @import("localization.zig").LocText;

const utils = @import("utils.zig");
const loadFileAlloc = utils.loadFileAlloc;
const BmpWriter = @import("BmpRenderer.zig").BmpWriter;

name: Name,
atlas: *FontAtlas,

pub fn setRendererHash(self: *@This(), hash: u32) void {
    self.atlas.rendererHash = hash;
}

pub const FontCreateOpts = struct {
    isMonospace: bool = false,
    isSDF: bool = true,
};

pub const FontAtlas = struct {
    font: c.stbtt_fontinfo = undefined,
    allocator: std.mem.Allocator,
    isSDF: bool = false,
    fileContent: []const u8,
    filePath: []const u8,
    atlasBuffer: ?[]u8,
    fontSize: f32,
    atlasSize: Vector2i = .{},
    glyphMax: Vector2i = .{},
    glyphStride: i32 = 0,
    glyphMetrics: [256]Vector2i = undefined,
    glyphBox0: [256]Vector2i = undefined,
    glyphBox1: [256]Vector2i = undefined,
    scale: f32 = 0,
    lineSize: f32 = 0,
    hasGlyph: [256]bool = undefined,
    rendererHash: u32 = 0, // optional field to associate this atlas with an identifier to the renderer implementation
    isEmbedded: bool = false,
    isMonospace: bool = false,

    meshes: [256][4]Vector2f = undefined,
    glyphCoordinates: [256][2]Vector2f = undefined,

    pub fn makeBitmapRGBA(self: @This(), allocator: std.mem.Allocator) ![]u8 {
        var buf = try allocator.alloc(u8, self.atlasBuffer.?.len * 4);

        for (0..self.atlasBuffer.?.len) |i| {
            buf[(i * 4) + 0] = self.atlasBuffer.?[i];
            buf[(i * 4) + 1] = self.atlasBuffer.?[i];
            buf[(i * 4) + 2] = self.atlasBuffer.?[i];
            buf[(i * 4) + 3] = 1.0;
        }

        return buf;
    }

    const defaultFontEmbed = @embedFile("fonts/Roboto-Regular.ttf");
    const defaultMonoEmbed = @embedFile("fonts/FiraMono-Medium.ttf");

    pub fn initDefaultBitmapFont(allocator: std.mem.Allocator, fontSize: f32) !@This() {
        return try initEmbeddedFont(allocator, defaultFontEmbed, fontSize, .{ .isSDF = false });
    }

    pub fn initMonoFont(allocator: std.mem.Allocator, fontSize: f32) !@This() {
        return try initEmbeddedFont(allocator, defaultMonoEmbed, fontSize, .{ .isMonospace = true });
    }

    pub fn initDefaultFont(allocator: std.mem.Allocator, fontSize: f32) !@This() {
        return try initEmbeddedFont(allocator, defaultFontEmbed, fontSize, .{});
    }

    pub fn initEmbeddedFont(allocator: std.mem.Allocator, fontContent: []const u8, fontSize: f32, opts: FontCreateOpts) !@This() {
        var self = @This(){
            .allocator = allocator,
            .filePath = "embedded_file",
            .fileContent = fontContent,
            .atlasBuffer = null,
            .fontSize = fontSize,
            .isSDF = opts.isSDF,
            .isEmbedded = true,
            .isMonospace = opts.isMonospace,
        };

        _ = c.stbtt_InitFont(
            &self.font,
            self.fileContent.ptr,
            c.stbtt_GetFontOffsetForIndex(self.fileContent.ptr, 0),
        );

        try self.createAtlas();

        return self;
    }

    pub fn initFromFileSDF(allocator: std.mem.Allocator, file: []const u8, fontSize: f32, opts: FontCreateOpts) !@This() {
        var self = @This(){
            .allocator = allocator,
            .filePath = file,
            .fileContent = try loadFileAlloc(file, 8, allocator),
            .atlasBuffer = null,
            .fontSize = fontSize,
            .isSDF = true,
            .isMonospace = opts.isMonospace,
        };

        _ = c.stbtt_InitFont(
            &self.font,
            self.fileContent.ptr,
            c.stbtt_GetFontOffsetForIndex(self.fileContent.ptr, 0),
        );

        try self.createAtlas();

        return self;
    }

    // destroys all bitmaps created during the setup process.
    // if the bitmaps are already uploaded to the GPU, you wouldnt need to
    // keep them mapped
    pub fn cleanUp(self: *@This()) void {
        if (self.atlasBuffer) |buffer| {
            self.atlasBuffer = null;
            self.allocator.free(buffer);
        }
    }

    // creates a font atlas from
    pub fn initFromFile(allocator: std.mem.Allocator, file: []const u8, fontSize: f32, opts: FontCreateOpts) !@This() {
        var self = @This(){
            .allocator = allocator,
            .filePath = file,
            .fileContent = try loadFileAlloc(file, 8, allocator),
            .atlasBuffer = null,
            .fontSize = fontSize,
            .isMonospace = opts.isMonospace,
        };

        _ = c.stbtt_InitFont(&self.font, self.fileContent.ptr, c.stbtt_GetFontOffsetForIndex(self.fileContent.ptr, 0));

        try self.createAtlas();

        return self;
    }

    fn createAtlas(self: *@This()) !void {
        const glyphCount = 256;
        var glyphs: [glyphCount][*c]u8 = undefined;
        var max: Vector2i = .{};

        var ch: u32 = 0;

        self.scale = c.stbtt_ScaleForPixelHeight(&self.font, self.fontSize);

        while (ch < glyphCount) : (ch += 1) {
            self.glyphMetrics[ch] = .{ .x = 0, .y = 0 };
            self.glyphBox1[ch] = .{ .x = 0, .y = 0 };

            if (self.isSDF) {
                glyphs[ch] = c.stbtt_GetCodepointSDF(
                    &self.font,
                    c.stbtt_ScaleForPixelHeight(&self.font, self.fontSize),
                    @as(c_int, @intCast(ch)),
                    5,
                    180,
                    36,
                    &self.glyphMetrics[ch].x,
                    &self.glyphMetrics[ch].y,
                    &self.glyphBox1[ch].x,
                    &self.glyphBox1[ch].y,
                );
            } else {
                glyphs[ch] = c.stbtt_GetCodepointBitmap(
                    &self.font,
                    0,
                    c.stbtt_ScaleForPixelHeight(&self.font, self.fontSize),
                    @as(c_int, @intCast(ch)),
                    &self.glyphMetrics[ch].x,
                    &self.glyphMetrics[ch].y,
                    &self.glyphBox1[ch].x,
                    &self.glyphBox1[ch].y,
                );
            }

            if (self.glyphMetrics[ch].x > max.x) {
                //if (self.glyphMetrics[ch].x < 128) {
                max.x = self.glyphMetrics[ch].x;
                //}
            }

            if (self.glyphMetrics[ch].y > max.y) {
                //if (self.glyphMetrics[ch].y < 128) {
                max.y = self.glyphMetrics[ch].y;
                //}
            }
        }

        self.glyphMax = max;
        std.debug.print("creating atlas: {any}\n", .{self.glyphMax});
        // allocate the atlasBuffer, just a linear strip
        self.atlasSize = .{ .x = (max.x + 1) * glyphCount, .y = (max.y + 1) };
        self.glyphStride = max.x + 1;
        self.atlasBuffer = try self.allocator.alloc(u8, @as(usize, @intCast(self.atlasSize.x * self.atlasSize.y)));
        @memset(self.atlasBuffer.?, 0x0);

        // write bitmaps into the atlas buffer
        ch = 0;
        while (ch < glyphCount) : (ch += 1) {
            if (@intFromPtr(glyphs[ch]) == 0) {
                self.hasGlyph[ch] = false;
                continue;
            }
            self.hasGlyph[ch] = true;

            const tl = Vector2i{ .x = @as(i32, @intCast(ch)) * (max.x + 1), .y = 0 };
            const maxCol = self.glyphMetrics[ch].x;
            const maxRow = self.glyphMetrics[ch].y;
            var col: i32 = 0;
            var row: i32 = 0;

            // get floating point coordinates for rendering to opengl/vulkan
            // get top left coordinates
            self.glyphCoordinates[ch][0] = .{
                .x = @as(f32, @floatFromInt(tl.x)) / @as(f32, @floatFromInt(self.atlasSize.x)),
                .y = @as(f32, @floatFromInt(tl.y)) / @as(f32, @floatFromInt(self.atlasSize.y)),
            };

            // get bottom right coordinates
            self.glyphCoordinates[ch][1] = .{
                .x = @as(f32, @floatFromInt(tl.x + self.glyphMetrics[ch].x)) / @as(f32, @floatFromInt(self.atlasSize.x)),
                .y = @as(f32, @floatFromInt(tl.y + self.glyphMetrics[ch].y)) / @as(f32, @floatFromInt(self.atlasSize.y)),
            };

            while (row < maxRow) : (row += 1) {
                col = 0;
                while (col < maxCol) : (col += 1) {
                    const pixelOffset = @as(usize, @intCast(((row + tl.y) * self.atlasSize.x) + (col + tl.x)));
                    self.atlasBuffer.?[pixelOffset] = glyphs[ch][@as(usize, @intCast((row * maxCol) + col))];
                }
            }

            const xSize = @as(f32, @floatFromInt(self.glyphMetrics[ch].x)) * self.scale;
            const ySize = @as(f32, @floatFromInt(self.glyphMetrics[ch].y)) * self.scale;
            const xOff = @as(f32, @floatFromInt(self.glyphBox1[ch].x)) * self.scale;
            const yOff = @as(f32, @floatFromInt(self.glyphBox1[ch].y)) * self.scale;

            // create an appropriately proportioned mesh based on the scale.
            self.meshes[ch][0] = .{ .x = xOff, .y = ySize + yOff }; // TL
            self.meshes[ch][1] = .{ .x = xSize + xOff, .y = ySize + yOff }; // TR
            self.meshes[ch][2] = .{ .x = xSize + xOff, .y = 0 + yOff }; // BR
            self.meshes[ch][3] = .{ .x = xOff, .y = yOff }; // BL
        }

        ch = 0;
        while (ch < glyphCount) : (ch += 1) {
            if (glyphs[ch]) |ptr| {
                if (self.isSDF) {
                    c.stbtt_FreeSDF(ptr, null);
                } else {
                    c.stbtt_FreeBitmap(ptr, null);
                }
            }
        }

        if (self.isMonospace) {
            var i: usize = 0;

            var fixedSize = self.glyphBox1['a'].x + self.glyphMetrics['a'].x;

            while (i < self.glyphMetrics.len) : (i += 1) {
                self.glyphMetrics[i].x = fixedSize - self.glyphBox1[i].x;
            }
        }
    }

    pub fn dumpBufferToFile(self: *@This(), fileName: []const u8) !void {
        var renderer = try BmpWriter.init(std.testing.allocator, self.atlasSize);
        var row: i32 = 0;
        var col: i32 = 0;
        while (row < renderer.extent.y) : (row += 1) {
            col = 0;
            while (col < renderer.extent.x) : (col += 1) {
                const pixelOffset = @as(usize, @intCast((renderer.extent.x * (row)) + col));
                const pixelOffset2 = @as(usize, @intCast((renderer.extent.x * (self.atlasSize.y - row - 1)) + col));
                renderer.pixelBuffer[pixelOffset * 3 + 0] = self.atlasBuffer.?[pixelOffset2];
                renderer.pixelBuffer[pixelOffset * 3 + 1] = self.atlasBuffer.?[pixelOffset2];
                renderer.pixelBuffer[pixelOffset * 3 + 2] = self.atlasBuffer.?[pixelOffset2];
            }
        }

        try renderer.writeOut(fileName);
        defer renderer.deinit();
    }

    pub fn deinit(self: *@This()) void {
        if (self.atlasBuffer != null) {
            self.allocator.free(self.atlasBuffer.?);
        }
        if (!self.isEmbedded)
            self.allocator.free(self.fileContent);
    }
};
