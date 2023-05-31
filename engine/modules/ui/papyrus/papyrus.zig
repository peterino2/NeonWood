const std = @import("std");
const c = @cImport({
    @cInclude("stb_ttf.h");
});

// Mixed mode implementation agnostic UI library
//
// Intended for use with real time applications.
// This file only contains the core layout engine and events pump for the IO processor.
//
// Actual hook up of the IO Processor and graphics is done elsewhere.

// =================================== Document: How should the layout engine work ===========================
//
// In terms of goals I want to be able to support both screen space proportional UIs as well as UIs for
// creating general purpose applications.
//
//
// Notes on some other applications like remedybg.
//
// - Panels are either free floating or docked
// - Their position is described as an anchor offset
// - Elements have a minimum size which they are happy to shrink to.
//
// Docked:
// - when docked, the panel's size layout is described as a percentage of their parent's docking space
// - Text should stay the same and not proportionally follow the window.
// - Images and image based layouts should.
//
// Free:
//
// - Their size is absolute, and their position is relative to the reference anchor.
//
// Text:
// - Text should build their geometry requirements ahead of time, and only be looked up when we're ready to render.
// - For a given length of text and a maximum width, we should be able to figure out it's height requirements.
//
// Tasks:
//  - Panel Layout
//      - internal layout:
//          - free:
//          - grid:
//          - verticalList:
//          - horizontalList:
//
//  - Layout algorithm
//      - for each node
//          - get parent context
//          - create current layout context
//          - call into sub layout function with current context
//
// =================================== /Document: How should the layout engine work ===========================

// Bmp software renderer
// This is a backend agnostic testing renderer which just renders outlines to a bmp file
// Used for testing Layouts.

const BmpRenderer = struct {
    allocator: std.mem.Allocator,
    ui: *PapyrusContext,
    extent: Vector2i,
    r: BmpWriter,
    outFile: []const u8 = "Saved/frame.bmp",
    baseColor: ColorRGBA8 = ColorRGBA8.fromHex(0x080808ff),

    pub fn init(allocator: std.mem.Allocator, ui: *PapyrusContext, extent: Vector2i) !@This() {
        return .{
            .allocator = allocator,
            .ui = ui,
            .extent = extent,
            .r = try BmpWriter.init(allocator, extent),
        };
    }

    pub fn setRenderFile(self: *@This(), outFile: []const u8) void {
        self.outFile = outFile;
    }

    pub fn deinit(self: *@This()) void {
        self.r.deinit();
    }

    pub fn render(self: *@This()) !void {
        self.r.clear(self.baseColor);

        var timer = try std.time.Timer.start();
        const tstart = timer.read();

        var drawList = try self.ui.makeDrawList();
        defer drawList.deinit();

        const tend = timer.read();
        const duration = (@intToFloat(f64, tend - tstart) / 1000);
        std.debug.print(" drawList Assembly: {d}us\n", .{duration});

        var i: u32 = 0;
        while (i < drawList.items.len) : (i += 1) {
            const cmd = drawList.items[i];
            switch (cmd.primitive) {
                .Rect => |rect| {
                    var tl = Vector2i.fromVector2(rect.tl);
                    var size = Vector2i.fromVector2(rect.size);
                    const border = ColorRGBA8.fromColor(rect.borderColor);
                    const bg = ColorRGBA8.fromColor(rect.backgroundColor);

                    self.r.drawRectangle(.Line, tl, size, border.r, border.g, border.b);
                    self.r.drawRectangle(.Filled, tl.add(Vector2i{ .x = 1, .y = 1 }), size.add(.{ .x = -2, .y = -2 }), bg.r, bg.g, bg.b);
                },
                .Text => |t| {
                    var tl = Vector2i.fromVector2(t.tl);
                    self.r.drawText(self.ui.fallbackFont.atlas, tl, t.text, t.color);
                },
            }
        }

        try self.r.writeOut(self.outFile);
    }
};

const BmpWriter = struct {
    const FileHeader = extern struct {
        sig0: [2]u8 = .{ 'B', 'M' },
        filesize: u32 align(1) = 0,
        rsvd0: u32 align(1) = 0,
        pixelArrayOffset: u32 align(1) = 0,
    };

    const Windows31Info = extern struct {
        headerSize: u32 align(1) = @sizeOf(@This()),
        width: u32 align(1) = 0,
        height: u32 align(1) = 0,
        planes: u16 align(1) = 1,
        bitsPerPixel: u16 align(1) = 24,
        compression: u32 align(1) = 0,
        imageSize: u32 align(1) = 0,
        yPixelPerMeter: u32 align(1) = 0,
        xPixelPerMeter: u32 align(1) = 0,
        numColorsPallete: u32 align(1) = 0,
        mostImpColor: u32 align(1) = 0,
    };

    allocator: std.mem.Allocator,
    extent: Vector2i = .{ .x = 1920, .y = 1080 },
    pixelBuffer: []u8,

    pub fn init(allocator: std.mem.Allocator, resolution: Vector2i) !@This() {
        var pixelBuffer = try allocator.alloc(u8, @intCast(usize, resolution.x * resolution.y * 3));
        @memset(pixelBuffer, 0x8);
        return .{ .allocator = allocator, .pixelBuffer = pixelBuffer, .extent = resolution };
    }

    pub fn blitBlackWhite(self: *@This(), pixels: []const u8, width: i32, height: i32, xPos: i32, yPos: i32) void {
        var x: i32 = 0;
        var y: i32 = 0;

        while (y < height) : (y += 1) {
            x = 0;
            while (x < width) : (x += 1) {
                const i = (x + xPos + (@intCast(i32, self.extent.y) - y - yPos) * @intCast(i32, self.extent.x)) * 3;
                const clamped = @intCast(usize, std.math.max(i, 0));
                self.pixelBuffer[clamped + 0] = pixels[@intCast(usize, y * width + x)];
                self.pixelBuffer[clamped + 1] = pixels[@intCast(usize, y * width + x)];
                self.pixelBuffer[clamped + 2] = pixels[@intCast(usize, y * width + x)];
            }
        }
    }

    pub fn clear(self: *@This(), color: ColorRGBA8) void {
        var i: u32 = 0;
        while (i < self.pixelBuffer.len) : (i += 3) {
            self.pixelBuffer[i + 2] = color.r;
            self.pixelBuffer[i + 1] = color.g;
            self.pixelBuffer[i + 0] = color.b;
        }
    }

    pub fn addChar(self: *@This(), atlas: *const FontAtlas, pos: Vector2i, ch: u8, color: Color) void {
        const metrics = atlas.glyphMetrics[ch];

        var row: i32 = 0;
        while (row < metrics.y) : (row += 1) {
            var col: i32 = 0;
            while (col < metrics.x) : (col += 1) {
                const pixelOffset = @intCast(usize, (atlas.glyphStride * ch) + col + row * atlas.atlasSize.x);
                const pixelOffset2 = @intCast(usize, ((self.extent.y - pos.y - row) * self.extent.x) + pos.x + col);

                const alpha = @intToFloat(f32, atlas.atlasBuffer.?[pixelOffset]) / 255;
                const old = Color.fromRGB2(
                    @intToFloat(f32, self.pixelBuffer[pixelOffset2 * 3 + 2]) / 255,
                    @intToFloat(f32, self.pixelBuffer[pixelOffset2 * 3 + 1]) / 255,
                    @intToFloat(f32, self.pixelBuffer[pixelOffset2 * 3 + 0]) / 255,
                );

                const new = ColorRGBA8{
                    .r = @floatToInt(u8, 255 * (alpha * color.r + (1 - alpha) * old.r)),
                    .g = @floatToInt(u8, 255 * (alpha * color.g + (1 - alpha) * old.g)),
                    .b = @floatToInt(u8, 255 * (alpha * color.r + (1 - alpha) * old.b)),
                };

                self.pixelBuffer[pixelOffset2 * 3 + 2] = new.r;
                self.pixelBuffer[pixelOffset2 * 3 + 1] = new.g;
                self.pixelBuffer[pixelOffset2 * 3 + 0] = new.b;
            }
        }
    }

    pub fn drawText(self: *@This(), atlas: *const FontAtlas, topLeft: Vector2i, text: LocText, color: Color) void {
        // blit each character from the atlas onto the thing
        const str = text.getRead();

        var accum: i32 = 0;
        for (str, 0..) |ch, i| {
            _ = i;
            const box = atlas.glyphBox1[ch];
            self.addChar(
                atlas,
                topLeft.add(.{
                    .x = accum,
                    //.x = (atlas.glyphStride) * @intCast(i32, i),
                    .y = @floatToInt(i32, atlas.fontSize),
                }).add(.{ .x = box.x, .y = box.y }),
                ch,
                color,
            );
            accum += box.x + atlas.glyphMetrics[ch].x;
            if (ch == ' ') {
                accum += atlas.glyphStride;
            }
        }
    }

    pub fn drawRectangle(self: *@This(), style: enum { Filled, Line }, topLeft: Vector2i, size: Vector2i, r: u8, g: u8, b: u8) void {
        var i: i32 = 0;
        while (i < size.y) : (i += 1) {
            const row = i + topLeft.y;
            if (row < 0 or row >= self.extent.y) {
                continue;
            }
            const flippedRow = self.extent.y - row - 1;

            {
                const col = topLeft.x;
                if (col >= 0 and col < self.extent.x) {
                    const pixelOffset = @intCast(usize, flippedRow * self.extent.x + col);

                    self.pixelBuffer[pixelOffset * 3 + 2] = r;
                    self.pixelBuffer[pixelOffset * 3 + 1] = g;
                    self.pixelBuffer[pixelOffset * 3 + 0] = b;
                }
            }

            if (i == 0 or i == size.y - 1 or style == .Filled) {
                var col: i32 = topLeft.x + 1;
                while (col < topLeft.x + size.x) : (col += 1) {
                    if (col < 0 or col >= self.extent.x) {
                        continue;
                    }
                    const pixelOffset = @intCast(usize, (flippedRow) * self.extent.x + col);

                    self.pixelBuffer[pixelOffset * 3 + 2] = r;
                    self.pixelBuffer[pixelOffset * 3 + 1] = g;
                    self.pixelBuffer[pixelOffset * 3 + 0] = b;
                }
            }

            {
                const col = topLeft.x + size.x;
                if (col >= 0 and col < self.extent.x) {
                    const pixelOffset = @intCast(usize, flippedRow * self.extent.x + col);

                    self.pixelBuffer[pixelOffset * 3 + 2] = r;
                    self.pixelBuffer[pixelOffset * 3 + 1] = g;
                    self.pixelBuffer[pixelOffset * 3 + 0] = b;
                }
            }
        }
    }

    pub fn writeOut(self: @This(), outFile: []const u8) !void {
        var header: FileHeader = .{
            .rsvd0 = 0,
            .filesize = @intCast(u32, self.extent.x * self.extent.y * 3 + @intCast(u32, @sizeOf(FileHeader))),
            .pixelArrayOffset = @sizeOf(FileHeader) + @sizeOf(Windows31Info),
        };

        var info: Windows31Info = .{
            .planes = 1,
            .bitsPerPixel = 24,
            .compression = 0,
            .numColorsPallete = 0,
            .mostImpColor = 0,
            .xPixelPerMeter = 0x130B,
            .yPixelPerMeter = 0x130B,
            .width = @intCast(u32, self.extent.x),
            .height = @intCast(u32, self.extent.y),
            .imageSize = @intCast(u32, self.extent.x * self.extent.y * 3),
        };

        const cwd = std.fs.cwd();
        cwd.makePath("Saved") catch unreachable;
        var logFile = try cwd.createFile(outFile, .{});
        defer logFile.close();
        var writer = logFile.writer();
        try writer.writeAll(std.mem.asBytes(&header));
        try writer.writeAll(std.mem.asBytes(&info));
        try writer.writeAll(self.pixelBuffer);
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.pixelBuffer);
    }
};

fn loadFileAlloc(filename: []const u8, comptime alignment: usize, allocator: std.mem.Allocator) ![]u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    const filesize = (try file.stat()).size;
    var buffer: []u8 = try allocator.alignedAlloc(u8, alignment, filesize);
    try file.reader().readNoEof(buffer);
    return buffer;
}

pub const FontAtlas = struct {
    font: c.stbtt_fontinfo = undefined,
    allocator: std.mem.Allocator,
    isSDF: bool = false,
    fileContent: []u8,
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

    meshes: [256][4]Vector2 = undefined,
    glyphCoordinates: [256][2]Vector2 = undefined,

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

    pub fn initFromFileSDF(allocator: std.mem.Allocator, file: []const u8, fontSize: f32) !@This() {
        var self = @This(){
            .allocator = allocator,
            .filePath = file,
            .fileContent = try loadFileAlloc(file, 8, allocator),
            .atlasBuffer = null,
            .fontSize = fontSize,
            .isSDF = true,
        };

        _ = c.stbtt_InitFont(&self.font, self.fileContent.ptr, c.stbtt_GetFontOffsetForIndex(self.fileContent.ptr, 0));

        try self.createAtlas();

        return self;
    }

    // creates a font atlas from
    pub fn initFromFile(allocator: std.mem.Allocator, file: []const u8, fontSize: f32) !@This() {
        var self = @This(){
            .allocator = allocator,
            .filePath = file,
            .fileContent = try loadFileAlloc(file, 8, allocator),
            .atlasBuffer = null,
            .fontSize = fontSize,
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
            if (self.isSDF) {
                glyphs[ch] = c.stbtt_GetCodepointSDF(
                    &self.font,
                    c.stbtt_ScaleForPixelHeight(&self.font, self.fontSize),
                    @intCast(c_int, ch),
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
                    @intCast(c_int, ch),
                    &self.glyphMetrics[ch].x,
                    &self.glyphMetrics[ch].y,
                    &self.glyphBox1[ch].x,
                    &self.glyphBox1[ch].y,
                );
            }

            if (self.glyphMetrics[ch].x > max.x) {
                max.x = self.glyphMetrics[ch].x;
            }

            if (self.glyphMetrics[ch].y > max.y)
                max.y = self.glyphMetrics[ch].y;
        }

        self.glyphMax = max;
        // allocate the atlasBuffer, just a linear strip
        self.atlasSize = .{ .x = (max.x + 1) * glyphCount, .y = (max.y + 1) };
        self.glyphStride = max.x + 1;
        self.atlasBuffer = try self.allocator.alloc(u8, @intCast(usize, self.atlasSize.x * self.atlasSize.y));
        @memset(self.atlasBuffer.?, 0x0);

        std.debug.print("creating atlas: {s}\n", .{self.filePath});

        // write bitmaps into the atlas buffer
        ch = 0;
        while (ch < glyphCount) : (ch += 1) {
            const tl = Vector2i{ .x = @intCast(i32, ch) * (max.x + 1), .y = 0 };
            const maxCol = self.glyphMetrics[ch].x;
            const maxRow = self.glyphMetrics[ch].y;
            var col: i32 = 0;
            var row: i32 = 0;

            // get floating point coordinates for rendering to opengl/vulkan
            // get top left coordinates
            self.glyphCoordinates[ch][0] = .{
                .x = @intToFloat(f32, tl.x) / @intToFloat(f32, self.atlasSize.x),
                .y = @intToFloat(f32, tl.y) / @intToFloat(f32, self.atlasSize.y),
            };

            // get bottom right coordinates
            self.glyphCoordinates[ch][1] = .{
                .x = @intToFloat(f32, tl.x + self.glyphMetrics[ch].x) / @intToFloat(f32, self.atlasSize.x),
                .y = @intToFloat(f32, tl.y + self.glyphMetrics[ch].y) / @intToFloat(f32, self.atlasSize.y),
            };

            while (row < maxRow) : (row += 1) {
                col = 0;
                while (col < maxCol) : (col += 1) {
                    const pixelOffset = @intCast(usize, ((row + tl.y) * self.atlasSize.x) + (col + tl.x));
                    self.atlasBuffer.?[pixelOffset] = glyphs[ch][@intCast(usize, (row * maxCol) + col)];
                }
            }

            const xSize = @intToFloat(f32, self.glyphMetrics[ch].x) * self.scale;
            const ySize = @intToFloat(f32, self.glyphMetrics[ch].y) * self.scale;
            const xOff = @intToFloat(f32, self.glyphBox1[ch].x) * self.scale;
            const yOff = @intToFloat(f32, self.glyphBox1[ch].y) * self.scale;

            // create an appropriately proportioned mesh based on the scale.
            self.meshes[ch][0] = .{ .x = xOff, .y = ySize + yOff }; // TL
            self.meshes[ch][1] = .{ .x = xSize + xOff, .y = ySize + yOff }; // TR
            self.meshes[ch][2] = .{ .x = xSize + xOff, .y = 0 + yOff }; // BR
            self.meshes[ch][3] = .{ .x = xOff, .y = yOff }; // BL
        }
    }

    pub fn dumpBufferToFile(self: *@This(), fileName: []const u8) !void {
        var renderer = try BmpWriter.init(std.testing.allocator, self.atlasSize);
        var row: i32 = 0;
        var col: i32 = 0;
        while (row < renderer.extent.y) : (row += 1) {
            col = 0;
            while (col < renderer.extent.x) : (col += 1) {
                const pixelOffset = @intCast(usize, (renderer.extent.x * (row)) + col);
                const pixelOffset2 = @intCast(usize, (renderer.extent.x * (self.atlasSize.y - row - 1)) + col);
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
        self.allocator.free(self.fileContent);
    }
};

fn grapvizDotToPng(allocator: std.mem.Allocator, vizFile: []const u8, pngFile: []const u8) !void {
    var sourceFile = try std.fmt.allocPrint(allocator, "Saved/{s}", .{vizFile});
    defer allocator.free(sourceFile);

    var imageFile = try std.fmt.allocPrint(allocator, "Saved/{s}", .{pngFile});
    defer allocator.free(imageFile);

    var childProc = std.ChildProcess.init(&.{ "dot", "-Tpng", sourceFile, "-o", imageFile }, allocator);
    try childProc.spawn();
}

pub fn dupeString(allocator: std.mem.Allocator, string: []const u8) ![]u8 {
    var dupe = try allocator.alloc(u8, string.len);

    std.mem.copy(u8, dupe, string);

    return dupe;
}

// ==== FileLog ====
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
        var ofile = try std.fmt.allocPrint(self.allocator, "Saved/{s}", .{self.fileName});
        defer self.allocator.free(ofile);
        try cwd.makePath("Saved");
        try cwd.writeFile(ofile, self.buffer.items);
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.fileName);
        self.buffer.deinit();
    }
};
// ==== FileLog ====

// ========================= Color =========================

pub const ColorRGBA8 = struct {
    r: u8 = 0x0,
    g: u8 = 0x0,
    b: u8 = 0x0,
    a: u8 = 0xff,

    pub fn fromHex(hex: u32) @This() {
        return .{
            .r = @intCast(u8, (hex >> 24) & 0xFF),
            .g = @intCast(u8, (hex >> 16) & 0xFF),
            .b = @intCast(u8, (hex >> 8) & 0xFF),
            .a = @intCast(u8, (hex) & 0xFF),
        };
    }

    pub fn fromColor(o: Color) @This() {
        return .{
            .r = @floatToInt(u8, std.math.clamp(o.r, 0, 1.0) * 255),
            .g = @floatToInt(u8, std.math.clamp(o.g, 0, 1.0) * 255),
            .b = @floatToInt(u8, std.math.clamp(o.b, 0, 1.0) * 255),
            .a = @floatToInt(u8, std.math.clamp(o.a, 0, 1.0) * 255),
        };
    }
};

pub const Color = struct {
    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,
    a: f32 = 1.0,

    pub const White = fromRGB(0xFFFFFF);
    pub const Red = fromRGB(0xFF0000);
    pub const Yellow = fromRGB(0xFFFF00);
    pub const Orange = fromRGB(0xFF5500);
    pub const Green = fromRGB(0x00FF00);
    pub const Blue = fromRGB(0x0000FF);
    pub const Cyan = fromRGB(0x00FFFF);
    pub const Magenta = fromRGB(0xFF00FF);

    pub fn intoRGBA(self: @This()) Color32 {
        return ((@floatToInt(u32, self.r) * 0xFF) << 24) |
            ((@floatToInt(u32, self.g) & 0xFF) << 16) |
            ((@floatToInt(u32, self.b) & 0xFF) << 8) |
            ((@floatToInt(u32, self.a) & 0xFF));
    }

    pub fn fromRGB2(r: anytype, g: anytype, b: anytype) @This() {
        return @This(){ .r = r, .g = g, .b = b, .a = 1.0 };
    }

    pub fn fromRGBA2(r: anytype, g: anytype, b: anytype, a: anytype) @This() {
        return @This(){ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn fromRGB(rgb: u32) @This() {
        return @This(){
            .r = @intToFloat(f32, (rgb >> 16) & 0xFF) / 255,
            .g = @intToFloat(f32, (rgb >> 8) & 0xFF) / 255,
            .b = @intToFloat(f32, (rgb) & 0xFF) / 255,
            .a = 1.0,
        };
    }

    pub fn fromRGBA(rgba: u32) @This() {
        return @This(){
            .r = @intToFloat(f32, (rgba >> 24) & 0xFF) / 255,
            .g = @intToFloat(f32, (rgba >> 16) & 0xFF) / 255,
            .b = @intToFloat(f32, (rgba >> 8) & 0xFF) / 255,
            .a = @intToFloat(f32, (rgba) & 0xFF) / 255,
        };
    }
};

// Color style used for my text editor
pub const BurnStyle = struct {
    pub const Comment = Color.fromRGB(0x90c480);
    pub const DarkComment = Color.fromRGB(0x243120);
    pub const Normal = Color.fromRGB(0xe2e2e5);
    pub const Highlight1 = Color.fromRGB(0x90c480);
    pub const Highlight2 = Color.fromRGB(0x75e1eb);
    pub const Highlight3 = Color.fromRGB(0xff9900);
    pub const Bright1 = Color.fromRGB(0xfaf4c6);
    pub const Bright2 = Color.fromRGB(0xffff00);
    pub const Statement = Color.fromRGB(0xff00f2);
    pub const LineTerminal = Color.fromRGB(0x87aefa);
    pub const SlateGrey = Color.fromRGB(0x141414);
    pub const DarkSlateGrey = Color.fromRGB(0x101010);
};

// Color Style generated from some website
pub const ModernStyle = struct {
    pub const Grey = Color.fromRGB(0x333348);
    pub const GreyLight = Color.fromRGB(0x44445F);
    pub const GreyDark = Color.fromRGB(0x222230);
    pub const Yellow = Color.fromRGB(0xf0cc56);
    pub const Orange = Color.fromRGB(0xcf5c36);
    pub const BrightGrey = Color.fromRGB(0x90a9b7);
    pub const Blue = Color.fromRGB(0x3c91e6);
};

// RGBA format for color
pub const Color32 = u32;

// ========================= Localization ======================
pub const HashStr = struct {
    utf8: []const u8,
    hash: u32,

    pub fn fromUtf8(source: []const u8) @This() {
        var hash: u32 = 5381;

        for (source) |ch| {
            hash = @mulWithOverflow(hash, 33)[0];
            hash = @addWithOverflow(hash, @intCast(u32, ch))[0];
        }

        var self = .{
            .utf8 = source,
            .hash = hash,
        };
        return self;
    }
};

pub fn MakeHash(comptime utf8: []const u8) HashStr {
    @setEvalBranchQuota(100000);
    return comptime HashStr.fromUtf8(utf8);
}

pub var gLocDbRef: ?*anyopaque = null;
pub var gLocDbInterface: *LocDbInterface = undefined;

pub const LocDbErrors = error{
    OutOfMemory,
    UnableToSetLocalization,
    UnknownError,
};

pub const LocDbInterface = struct {

    // Fetches the localized version of the string if it exists
    setLocalization: *const fn (*anyopaque, HashStr) LocDbErrors!void,
    getLocalized: *const fn (*anyopaque, u32) ?[]const u8,
    createEntry: *const fn (*anyopaque, u32, []const u8) LocDbErrors!u32,

    pub fn from(comptime TargetType: type) void {
        const W = struct {
            pub fn getLocalized(pointer: *anyopaque, key: u32) ?[]const u8 {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                return ptr.getLocalized(key);
            }

            pub fn createEntry(pointer: *anyopaque, key: u32, source: []const u8) LocDbErrors!u32 {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                try ptr.createEntry(key, source);
            }

            pub fn setLocalization(pointer: *anyopaque, name: HashStr) LocDbErrors!void {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                try ptr.setLocalization(name);
            }
        };

        return @This(){
            .getLocalized = W.getLocalized,
            .createEntry = W.createEntry,
            .setLocalization = W.setLocalization,
        };
    }
};

pub fn setupLocDb(ref: *anyopaque, interface: *LocDbInterface) void {
    gLocDbRef = ref;
    gLocDbInterface = interface;
}

// Anything display should probably be utilizing Text instead of just a normal []const u8,
pub const LocText = struct {
    utf8: []const u8,
    localized: ?[]const u8 = null,
    locKey: u32 = 0,

    pub fn getRead(self: @This()) []const u8 {
        if (self.localized) |localized| {
            return localized;
        }

        if (gLocDbRef) |locdb| {
            return gLocDbInterface.getLocalized(locdb, self.locKey).?;
        }

        return self.utf8;
    }

    pub fn get(self: *@This()) []const u8 {
        if (self.localized) |localized| {
            return localized;
        }

        if (gLocDbRef) |locdb| {
            self.localized = gLocDbInterface.getLocalized(locdb, self.locKey);
            return self.localized.?;
        }

        return self.utf8;
    }

    pub fn fromUtf8(text: []const u8) @This() {
        return .{
            .utf8 = text,
        };
    }
};

// text construction macro
pub fn Text(comptime utf8: []const u8) LocText {
    return LocText.fromUtf8(utf8);
}

// ========================================== /End Localization ==========================

// ========================================== Ring Queue =========================
pub const RingQueueError = error{
    QueueIsFull,
    QueueIsEmpty,
    AllocSizeTooSmall,
};

// managed version of the ringqueue, includes a mutex
pub fn RingQueue(comptime T: type) type {
    return struct {
        const _InnerType = RingQueueU(T);

        queue: _InnerType,
        allocator: std.mem.Allocator,
        mutex: std.Thread.Mutex = .{},

        pub fn init(allocator: std.mem.Allocator, size: usize) !@This() {
            var newSelf = @This(){
                .queue = try _InnerType.init(allocator, size),
                .allocator = allocator,
                .mutex = .{},
            };

            return newSelf;
        }

        pub fn pushLocked(self: *@This(), newValue: T) RingQueueError!void {
            self.mutex.lock();
            try self.queue.push(newValue);
            defer self.mutex.unlock();
        }

        // only call this if you have locked already
        pub fn popFromUnlocked(self: *@This()) ?T {
            return self.queue.pop();
        }

        pub fn lock(self: *@This()) void {
            self.mutex.lock();
        }

        pub fn unlock(self: *@This()) void {
            self.mutex.unlock();
        }

        pub fn popFromLocked(self: *@This()) ?T {
            try self.mutex.lock();
            defer self.mutex.unlock();
            const val = self.queue.pop();
            return val;
        }

        pub fn count(self: @This()) usize {
            return self.queue.count();
        }

        pub fn deinit(self: *@This()) void {
            self.queue.deinit();
        }
    };
}

// tail points to next free
// head points to next one to read
// unmanaged ring queue
pub fn RingQueueU(comptime T: type) type {
    return struct {
        buffer: []T = undefined,
        head: usize = 0, // resets upon resizes
        tail: usize = 0, // resets upon resizes

        pub fn init(allocator: std.mem.Allocator, size: usize) !@This() {
            var self = @This(){
                .buffer = try allocator.alloc(T, size + 1),
            };

            return self;
        }

        pub fn push(self: *@This(), value: T) RingQueueError!void {
            const next = (self.tail + 1) % self.buffer.len;

            if (next == self.head) {
                return error.QueueIsFull;
            }
            self.buffer[self.tail] = value;
            self.tail = next;
        }

        pub fn pushFront(self: *@This(), value: T) !void {
            var iHead = @intCast(isize, self.head) - 1;

            if (iHead < 0) {
                iHead = @intCast(isize, self.buffer.len) + iHead;
            }

            if (iHead == @intCast(isize, self.tail)) {
                return error.QueueIsFull;
            }

            self.head = @intCast(usize, iHead);
            self.buffer[self.head] = value;
        }

        pub fn count(self: @This()) usize {
            if (self.head == self.tail)
                return 0;

            if (self.head < self.tail)
                return self.tail - self.head;

            // head > tail means we looped around.
            return (self.buffer.len - self.head) + self.tail;
        }

        pub fn pop(self: *@This()) ?T {
            if (self.head == self.tail)
                return null;

            var r = self.buffer[self.head];
            self.head = ((self.head + 1) % self.buffer.len);

            return r;
        }

        pub fn peek(self: *@This()) ?*T {
            return self.at(0);
        }

        pub fn peekBack(self: @This()) ?*T {
            return self.atBack(1);
        }

        // reference an element at an offset from the back of the queue
        // similar to python's negative number syntax.
        // gets you an element at an offset from the tail.
        // given the way the tail works, this will return null on zero
        pub fn atBack(self: @This(), offset: usize) ?*T {
            const cnt = self.count();

            if (offset > cnt or offset == 0) {
                return null;
            }

            var x: isize = @intCast(isize, self.tail) - @intCast(isize, offset);

            if (x < 0) {
                x = @intCast(isize, self.buffer.len) + x;
            }

            return &self.buffer[@intCast(usize, x)];
        }

        pub fn at(self: *@This(), offset: usize) ?*T {
            const cnt = self.count();

            if (cnt == 0) {
                return null;
            }

            if (offset >= c) {
                return null;
            }

            var index = (self.head + offset) % self.buffer.len;

            return &self.buffer[index];
        }

        // returns the number of elements this buffer can hold.
        // you should rarely ever need to use this.
        pub fn capacity(self: *@This()) usize {
            return self.buffer.len - 1;
        }

        pub fn resize(self: *@This(), allocator: std.mem.Allocator, size: usize) !void {
            const cnt = self.count();

            // new size needs to be greater than current size by 1, tail always points to an empty
            if (cnt >= size) {
                return error.AllocSizeTooSmall;
            }

            var buffer: []T = try allocator.alloc(T, size + 1);
            var index: usize = 0;

            while (self.pop()) |v| {
                buffer[index] = v;
                index += 1;
            }

            allocator.free(self.buffer);

            self.buffer = buffer;
            self.head = 0;
            self.tail = index;
        }

        pub fn isEmpty(self: @This()) bool {
            return self.head == self.tail;
        }

        pub fn empty(self: *@This()) void {
            self.head = 0;
            self.tail = 0;
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.buffer);
        }
    };
}

// ========================================== End Of RingQueue ==================================

// ========================================== Dynamic pool ===============================
pub fn DynamicPool(comptime T: type) type {
    return struct {
        pub const Handle = u32;

        allocator: std.mem.Allocator,
        active: std.ArrayListUnmanaged(?T),
        dead: std.ArrayListUnmanaged(Handle),

        pub fn init(allocator: std.mem.Allocator) @This() {
            return .{
                .allocator = allocator,
                .active = .{},
                .dead = .{},
            };
        }

        pub fn new(self: *@This(), initVal: T) !Handle {
            if (self.dead.items.len > 0) {
                const revivedIndex = @intCast(Handle, self.dead.items[self.dead.items.len - 1]);

                try assertf(
                    revivedIndex < self.active.items.len,
                    "tried to revive index {d} which does not exist in pool of size {d}\n",
                    .{ revivedIndex, self.active.items.len },
                );

                self.active.items[revivedIndex] = initVal;
                self.dead.shrinkRetainingCapacity(self.dead.items.len - 1);
                return revivedIndex;
            }

            try self.active.append(self.allocator, initVal);
            return @intCast(Handle, self.active.items.len - 1);
        }

        pub fn isValid(self: @This(), handle: Handle) bool {
            if (handle >= self.active.items.len) {}
        }

        pub fn get(self: *@This(), handle: Handle) ?*T {
            if (handle >= self.active.items.len) {
                return null;
            }

            if (self.active.items[handle] == null) {
                return null;
            }

            return &(self.active.items[handle].?);
        }

        pub fn getRead(self: @This(), handle: Handle) ?*const T {
            if (handle >= self.active.items.len) {
                return null;
            }

            return &(self.active.items[handle].?);
        }

        pub fn destroy(self: *@This(), destroyHandle: Handle) void {
            self.active.items[destroyHandle] = null;
            self.dead.append(self.allocator, destroyHandle) catch unreachable;
        }

        pub fn deinit(self: *@This()) void {
            self.active.deinit(self.allocator);
            self.dead.deinit(self.allocator);
        }
    };
}

// ===================================  End of Dynamic pool =========================

pub const Vector2i = struct {
    x: i32 = 0,
    y: i32 = 0,

    pub fn add(self: @This(), o: @This()) @This() {
        return .{ .x = self.x + o.x, .y = self.y + o.y };
    }

    pub fn sub(self: @This(), o: @This()) @This() {
        return .{ .x = self.x - o.x, .y = self.y - o.y };
    }

    pub fn fromVector2(o: Vector2) @This() {
        return .{ .x = @floatToInt(i32, o.x), .y = @floatToInt(i32, o.y) };
    }
};

pub const Vector2 = struct {
    x: f32 = 0,
    y: f32 = 0,

    pub const Ones = @This(){ .x = 1, .y = 1 };

    pub inline fn dot(self: @This(), o: @This()) f32 {
        return std.math.sqrt(self.x * o.x + self.y * o.y);
    }

    pub inline fn sub(self: @This(), o: @This()) @This() {
        return .{ .x = self.x - o.x, .y = self.y - o.y };
    }

    pub inline fn add(self: @This(), o: @This()) @This() {
        return .{ .x = self.x + o.x, .y = self.y + o.y };
    }

    pub inline fn mul(self: @This(), o: @This()) @This() {
        return .{ .x = self.x * o.x, .y = self.y * o.y };
    }

    pub inline fn fmul(self: @This(), o: anytype) @This() {
        return .{ .x = self.x * @floatCast(f32, o), .y = self.y * @floatCast(o, f32) };
    }

    pub inline fn fadd(self: @This(), o: anytype) @This() {
        return .{ .x = self.x + @floatCast(f32, o), .y = self.y + @floatCast(o, f32) };
    }

    pub inline fn fsub(self: @This(), o: anytype) @This() {
        return .{ .x = self.x - @floatCast(f32, o), .y = self.y - @floatCast(o, f32) };
    }

    pub fn fromVector2i(o: anytype) @This() {
        return .{ .x = @intToFloat(f32, o.x), .y = @intToFloat(f32, o.x) };
    }
};

fn assertf(eval: anytype, comptime fmt: []const u8, args: anytype) !void {
    if (!eval) {
        std.debug.print("[Error]: " ++ fmt, args);
        return error.AssertFailure;
    }
}

pub var gPapyrusContext: *PapyrusContext = undefined;
pub var gPapyrusIsInitialized: bool = false;

pub const PapyrusEvent = struct {};

pub const PapyrusAnchorNode = enum {
    // zig fmt: off
    Free,       // Anchored to 0,0 absolute on the screen
    TopLeft,    // Anchored such that 0,0 corresponds to the top left corner of the parent node
    MidLeft,    // Anchored such that 0,0 corresponds to the left edge midpoint of the parent node
    BotLeft,    // Anchored such that 0,0 corresponds to the bottom left corner of the parent node
    TopMiddle,  // Anchored such that 0,0 corresponds to the top edge midpoint of the parent node
    MidMiddle,  // Anchored such that 0,0 corresponds to the center of the parent node
    BotMiddle,  // Anchored such that 0,0 corresponds to the bottom edge midpoint of the parent node
    TopRight,   // Anchored such that 0,0 corresponds to the top right corner of the parent node
    MidRight,   // Anchored such that 0,0 corresponds to the right edge midpoint of the parent node
    BotRight,   // Anchored such that 0,0 corresponds to the bottom right corner of the parent node
    // zig fmt: on
};

pub const PapyrusFillMode = enum {
    // zig fmt: off
    None,       // Size will be absolute as specified by content
    FillX,  // Size will scale to X scaling of the parent (relative to reference), if set, then the size value of x will be interpreted as a percentage of the parent
    FillY,  // Size will scale to Y scaling of the parent (relative to reference), if set, then the size value of y will be interpreted as a percentage of the parent
    FillXY, // Size will scale to both X and Y of the parent (relative to reference), if set, then the size value of both x and y will be interpreted as a percentage of the parent
    // zig fmt: on
};

pub const PapyrusHitTestability = enum {
    Testable,
    NotTestable,
};

pub const PapyrusState = enum {
    Visible,
    Collapsed,
    Hidden,
};

pub const ChildLayout = enum { Free, Vertical, Horizontal };

pub const NodeProperty_Slot = struct {
    layoutMode: ChildLayout = .Free,
};

pub const NodeProperty_Button = struct {
    textSignal: LocText,
    onPressedSignal: u32,
    genericListener: u32,
};

pub const NodeProperty_Text = struct {
    pos: Vector2,
    size: Vector2,
    font: PapyrusFont,
};

pub const NodeProperty_Panel = struct {
    titleColor: Color = Color.White,
    layoutMode: ChildLayout = .Free, // when set to anything other than free, we will override anchors from inferior nodes.
    hasTitle: bool = false,
};

pub const NodePropertiesBag = union(enum(u8)) {
    Slot: NodeProperty_Slot,
    DisplayText: NodeProperty_Text,
    Button: NodeProperty_Button,
    Panel: NodeProperty_Panel,
};

pub const NodePadding = union(enum(u8)) {
    topLeft: Vector2,
    botLeft: Vector2,
    all: f32,
    allSides: [2]Vector2,
};

pub const PapyrusNodeStyle = struct {
    foregroundColor: Color = BurnStyle.Normal,
    backgroundColor: Color = BurnStyle.SlateGrey,
    borderColor: Color = BurnStyle.Bright2,
};

// this is going to follow a pretty object-oriented-like user facing api
pub const PapyrusNode = struct {
    text: LocText = Text("hello world"),
    parent: u32 = 0, // 0 corresponds to true root

    // all children of the same parent operate as a doubly linked list
    child: u32 = 0,
    end: u32 = 0,
    next: u32 = 0, //
    prev: u32 = 0,

    zOrder: i32 = 0, // higher order goes first

    // Not sure what's the best way to go about this.
    // I want to provide good design time metrics
    // which can scale into good runtime metrics

    // Resolutions and scalings are a real headspinner
    // DPI awareness and content scaling is also a huge problem.
    size: Vector2 = .{ .x = 0, .y = 0 },
    pos: Vector2 = .{ .x = 0, .y = 0 },
    anchor: PapyrusAnchorNode = .TopLeft,
    fill: PapyrusFillMode = .None,

    // padding is the external
    padding: NodePadding = .{ .all = 0 },

    state: PapyrusState = .Visible,
    hittest: PapyrusHitTestability = .Testable,
    dockingPolicy: enum { Dockable, NotDockable } = .Dockable,

    // standard styling options that all nodes have
    style: PapyrusNodeStyle = .{},

    nodeType: NodePropertiesBag,

    pub fn getSize(self: @This()) Vector2 {
        _ = self;
        return .{};
    }
};

pub const PapyrusFont = struct {
    name: HashStr,
    atlas: *FontAtlas,
};

pub const PapyrusContext = struct {
    allocator: std.mem.Allocator,
    nodes: DynamicPool(PapyrusNode),
    fonts: std.AutoHashMap(u32, PapyrusFont),
    fallbackFont: PapyrusFont,
    extent: Vector2i = .{ .x = 1920, .y = 1080 },

    // internals
    _drawOrder: DrawOrderList,
    _layout: std.AutoHashMap(u32, PosSize),

    pub fn create(backingAllocator: std.mem.Allocator) !*@This() {
        const fallbackFontName: []const u8 = "ProggyClean";
        const fallbackFontFile: []const u8 = "fonts/ComicMono.ttf";

        var self = try backingAllocator.create(@This());

        self.* = .{
            .allocator = backingAllocator,
            .nodes = DynamicPool(PapyrusNode).init(backingAllocator),
            .fonts = std.AutoHashMap(u32, PapyrusFont).init(backingAllocator),
            .fallbackFont = PapyrusFont{
                .name = HashStr.fromUtf8(fallbackFontName),
                .atlas = try backingAllocator.create(FontAtlas),
            },
            ._drawOrder = DrawOrderList.init(backingAllocator),
            ._layout = std.AutoHashMap(u32, PosSize).init(backingAllocator),
        };

        self.fallbackFont.atlas.* = try FontAtlas.initFromFile(backingAllocator, fallbackFontFile, 18);
        try self.fonts.put(self.fallbackFont.name.hash, self.fallbackFont);

        // constructing the root node
        _ = try self.nodes.new(.{
            .text = Text("root"),
            .parent = 0,
            .nodeType = .{ .Slot = .{} },
        });

        return self;
    }

    pub fn deinit(self: *@This()) void {
        var iter = self.fonts.iterator();
        while (iter.next()) |i| {
            i.value_ptr.atlas.deinit();
            self.allocator.destroy(i.value_ptr.atlas);
        }

        self.fonts.deinit();
        self.nodes.deinit();
        self._drawOrder.deinit();
        self._layout.deinit();
        self.allocator.destroy(self);
    }

    pub fn getPanel(self: *@This(), handle: u32) *NodeProperty_Panel {
        return &(self.nodes.get(handle).?.nodeType.Panel);
    }

    pub fn getText(self: *@This(), handle: u32) *NodeProperty_Text {
        return &(self.nodes.get(handle).?.nodeType.DisplayText);
    }

    // converts a handle to a node pointer
    // invalid after AddNode
    pub fn get(self: *@This(), handle: u32) *PapyrusNode {
        return self.nodes.get(handle).?;
    }

    // gets a node as read only
    pub fn getRead(self: @This(), handle: u32) *const PapyrusNode {
        return self.nodes.getRead(handle).?;
    }

    fn newNode(self: *@This(), node: PapyrusNode) !u32 {
        return try self.nodes.new(node);
    }

    pub fn addSlot(self: *@This(), parent: u32) !u32 {
        var slotNode = PapyrusNode{ .nodeType = .{ .Slot = .{} } };
        var slot = try self.newNode(slotNode);

        try self.setParent(slot, parent);

        return slot;
    }

    pub fn addText(self: *@This(), parent: u32, text: []const u8) !u32 {
        var slotNode = PapyrusNode{ .text = LocText.fromUtf8(text), .nodeType = .{ .DisplayText = .{
            .pos = .{},
            .size = .{},
            .font = self.fallbackFont,
        } } };
        var slot = try self.newNode(slotNode);

        try self.setParent(slot, parent);

        return slot;
    }

    pub fn addPanel(self: *@This(), parent: u32) !u32 {
        var slotNode = PapyrusNode{ .nodeType = .{ .Panel = .{} } };

        if (parent == 0) {
            slotNode.anchor = .Free;
        }
        var slot = try self.nodes.new(slotNode);

        try self.setParent(slot, parent);

        return slot;
    }

    pub fn setParent(self: *@This(), node: u32, parent: u32) !void {
        try assertf(self.nodes.get(parent) != null, "tried to assign node {d} to parent {d} but parent does not exist", .{ node, parent });
        try assertf(self.nodes.get(node) != null, "tried to assign node {d} to parent {d} but node does not exist", .{ node, parent });

        var parentNode = self.nodes.get(parent).?;
        var thisNode = self.nodes.get(node).?;

        // if we have a previous parent, remove ourselves
        if (thisNode.*.parent != 0) {
            // remove myself from that parent.
            var oldParentNode = self.nodes.get(thisNode.*.parent).?;

            // special case for when we're the first child element
            if (oldParentNode.*.child == node) {
                oldParentNode.*.child = thisNode.next;
            } else {
                // otherwise remove ourselves from the linked list
                self.nodes.get(thisNode.prev).?.*.next = thisNode.next;
            }
        }

        // assign ourselves the new parent
        self.nodes.get(node).?.*.parent = parent;

        if (parentNode.*.child == 0) {
            parentNode.*.child = node;
        } else {
            self.nodes.get(parentNode.*.end).?.*.next = node;
            thisNode.*.prev = parentNode.*.end;
        }

        parentNode.*.end = node;
    }

    // helper functions for a whole bunch of shit
    pub fn addButton(self: *@This(), text: LocText) !u32 {
        var button = NodeProperty_Button{ .text = text };
        return try self.nodes.new(.{ .nodeType = .{ .Button = button } });
    }

    pub fn removeFromParent(self: *@This(), node: u32) !void {
        // this also deletes all children
        // 1. gather all children.
        try assertf(node != 0, "removeFromParent CANNOT be called on the root node", .{});

        var killList = std.ArrayList(u32).init(self.allocator);
        defer killList.deinit();
        self.walkNodesToRemove(node, &killList) catch {
            for (killList.items) |n| {
                std.debug.print("{d}, ", .{n});
            }
            return error.BadWalk;
        };

        var thisNode = self.getRead(node);
        self.get(thisNode.next).prev = thisNode.prev;
        self.get(thisNode.prev).next = thisNode.next;

        {
            var parent = self.get(thisNode.parent);

            if (parent.child == node) {
                parent.child = thisNode.next;
            }

            if (parent.end == node) {
                parent.end = thisNode.prev;
            }
        }

        for (killList.items) |killed| {
            self.nodes.destroy(killed);
        }
    }

    fn walkNodesToRemove(self: @This(), root: u32, killList: *std.ArrayList(u32)) !void {
        try killList.append(root);

        var next = self.getRead(root).child;

        while (next != 0) {
            try self.walkNodesToRemove(next, killList);
            next = self.getRead(next).next;
        }
    }

    pub fn tick(self: *@This(), deltaTime: f32) void {
        _ = self;
        _ = deltaTime;
    }

    // ============================= Rendering and Layout ==================

    pub const DrawCommand = struct {
        node: u32,
        primitive: union(enum(u8)) {
            Rect: struct {
                tl: Vector2,
                size: Vector2,
                borderColor: Color,
                backgroundColor: Color,
            },
            Text: struct {
                tl: Vector2,
                text: LocText,
                color: Color,
            },
        },
    };
    pub const DrawList = std.ArrayList(DrawCommand);
    const DrawOrderList = std.ArrayList(u32);

    fn assembleDrawOrderListForNode(self: @This(), node: u32, list: *DrawOrderList) !void {
        var next: u32 = self.getRead(node).child;
        while (next != 0) : (next = self.getRead(next).next) {
            try list.append(next);
            try self.assembleDrawOrderListForNode(next, list);
        }
    }

    fn assembleDrawOrderList(self: @This(), list: *DrawOrderList) !void {
        var rootNodes = std.ArrayList(u32).init(self.allocator);
        defer rootNodes.deinit();

        var next: u32 = self.getRead(0).child;
        while (next != 0) : (next = self.getRead(next).next) {
            try rootNodes.append(next);
        }

        const SortFunc = struct {
            pub fn lessThan(ctx: PapyrusContext, lhs: u32, rhs: u32) bool {
                return ctx.getRead(lhs).zOrder < ctx.getRead(rhs).zOrder;
            }
        };

        std.sort.insertion(
            u32,
            rootNodes.items,
            self,
            SortFunc.lessThan,
        );

        for (rootNodes.items) |rootNode| {
            try list.append(rootNode);
            try self.assembleDrawOrderListForNode(rootNode, list);
        }
    }

    const PosSize = struct {
        pos: Vector2,
        size: Vector2,
    };

    fn resolveAnchoredPosition(parent: PosSize, node: *const PapyrusNode) Vector2 {
        switch (node.anchor) {
            .Free => {
                return node.pos;
            },
            .TopLeft => {
                return parent.pos.add(node.pos);
            },
            .MidLeft => {
                return parent.pos.add(.{ .y = parent.size.y / 2 }).add(node.pos);
            },
            .BotLeft => {
                return parent.pos.add(.{ .y = parent.size.y }).add(node.pos);
            },
            .TopMiddle => {
                return parent.pos.add(.{ .x = parent.size.x / 2 }).add(node.pos);
            },
            .MidMiddle => {
                return parent.pos.add(.{ .x = parent.size.x / 2, .y = parent.size.y / 2 }).add(node.pos);
            },
            .BotMiddle => {
                return parent.pos.add(.{ .x = parent.size.x / 2, .y = parent.size.y }).add(node.pos);
            },
            .TopRight => {
                return parent.pos.add(.{ .x = parent.size.x }).add(node.pos);
            },
            .MidRight => {
                return parent.pos.add(.{ .x = parent.size.x, .y = parent.size.y / 2 }).add(node.pos);
            },
            .BotRight => {
                return parent.pos.add(.{ .x = parent.size.x, .y = parent.size.y }).add(node.pos);
            },
        }
    }

    fn resolveAnchoredSize(parent: PosSize, node: *const PapyrusNode) Vector2 {
        switch (node.fill) {
            .None => {
                return node.size;
            },
            .FillX => {
                return .{ .x = node.size.x * parent.size.x, .y = node.size.y };
            },
            .FillY => {
                return .{ .x = node.size.x, .y = node.size.y * parent.size.y };
            },
            .FillXY => {
                return node.size.mul(parent.size);
            },
        }
    }

    pub fn makeDrawList(self: *@This()) !DrawList {
        // do not re allocate these, instead use a preallocated pool
        self._drawOrder.clearRetainingCapacity();
        self._layout.clearRetainingCapacity();

        try self.assembleDrawOrderList(&self._drawOrder);

        var layout = std.AutoHashMap(u32, PosSize).init(self.allocator);
        defer layout.deinit();

        try layout.put(0, .{ .pos = .{ .x = 0, .y = 0 }, .size = Vector2.fromVector2i(self.extent) });

        var drawList = DrawList.init(self.allocator);

        for (self._drawOrder.items) |node| {
            var n = self.getRead(node);

            var parentInfo = layout.get(n.parent).?;

            var resolvedPos = resolveAnchoredPosition(parentInfo, n);
            var resolvedSize = resolveAnchoredSize(parentInfo, n);

            switch (n.nodeType) {
                .Panel => |panel| {
                    if (panel.hasTitle) {
                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = resolvedPos.add(.{ .y = 24 }),
                                .size = resolvedSize.sub(.{ .y = 24 }),
                                .borderColor = n.style.borderColor,
                                .backgroundColor = n.style.backgroundColor,
                            },
                        } });

                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = resolvedPos,
                                .size = .{ .x = resolvedSize.x, .y = 24 },
                                .borderColor = n.style.borderColor,
                                .backgroundColor = n.style.borderColor,
                            },
                        } });

                        try drawList.append(.{ .node = node, .primitive = .{
                            .Text = .{
                                .tl = resolvedPos.add(.{ .x = 3, .y = 1 }),
                                .text = n.text,
                                .color = panel.titleColor,
                            },
                        } });

                        try layout.put(node, .{
                            .pos = resolvedPos.add(.{ .y = 24 }).add(Vector2.Ones),
                            .size = resolvedSize.sub(.{ .y = -24 }).add(Vector2.Ones),
                        });
                    } else {
                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = resolvedPos,
                                .size = resolvedSize,
                                .borderColor = n.style.borderColor,
                                .backgroundColor = n.style.backgroundColor,
                            },
                        } });

                        try layout.put(node, .{
                            .pos = resolvedPos.add(Vector2.Ones),
                            .size = resolvedSize.add(Vector2.Ones),
                        });
                    }
                },
                .DisplayText => |txt| {
                    var render = try layoutTextBox(
                        self.allocator,
                        resolvedSize,
                        n.text.getRead(),
                        txt.font.atlas,
                        .WrapLimited,
                    );

                    defer render.deinit();
                },
                .Slot, .Button => {},
            }
        }

        return drawList;
    }

    pub fn printTree(self: @This(), root: u32) void {
        std.debug.print("\n ==== tree ==== \n", .{});
        self.printTreeInner(root, 0);
        std.debug.print(" ==== /tree ====   \n\n", .{});
    }

    fn printTreeInner(self: @This(), root: u32, indentLevel: u32) void {
        var i: u32 = 0;
        while (i < indentLevel) : (i += 1) {
            std.debug.print(" ", .{});
        }

        const node = self.getRead(root);
        std.debug.print("> {d}: {s}\n", .{ root, node.text.getRead() });

        var next = node.child;
        while (next != 0) {
            self.printTreeInner(next, indentLevel + 1);
            next = self.getRead(next).*.next;
        }
    }

    pub fn writeTree(self: @This(), root: u32, outFile: []const u8) !void {
        var log = try FileLog.init(self.allocator, outFile);
        defer log.deinit();

        try log.write("digraph G {{\n", .{});
        try self.writeTreeInner(root, &log);
        try log.write("}}\n", .{});

        try log.writeOut();
    }

    fn writeTreeInner(self: @This(), root: u32, log: *FileLog) !void {
        var node = self.getRead(root);
        try log.write("  {s}->{s}", .{ self.getRead(node.parent).text.getRead(), node.text.getRead() });

        var next = node.child;
        while (next != 0) {
            try self.writeTreeInner(next, log);
            next = self.getRead(next).*.next;
        }
    }

    // ============
    pub const TextLayoutMode = enum {
        Wrap,
        NoWrap,
        WrapLimited,
    };

    pub const TextRender = struct {
        size: Vector2,
        geometry: std.ArrayList(Vector2),
        uv: std.ArrayList(Vector2),

        pub fn init(allocator: std.mem.Allocator, baseSize: Vector2) @This() {
            return .{
                .size = baseSize,
                .geometry = std.ArrayList(Vector2).init(allocator),
                .uv = std.ArrayList(Vector2).init(allocator),
            };
        }

        pub fn deinit(self: *@This()) void {
            self.geometry.deinit();
            self.uv.deinit();
        }
    };

    // Layouts a out a textbox from the text and the font given.
    pub fn layoutTextBox(
        allocator: std.mem.Allocator,
        size: Vector2,
        text: []const u8,
        font: *FontAtlas,
        wrap: TextLayoutMode,
    ) !TextRender {
        const verticalAdvance = font.glyphMax.y;
        var rendered = TextRender.init(allocator, size);
        var ch: u32 = 0;

        while (ch < text.len) : (ch += 1) {
            try rendered.geometry.append(font.meshes[text[ch]][0]);
            try rendered.geometry.append(font.meshes[text[ch]][1]);
            try rendered.geometry.append(font.meshes[text[ch]][2]);
            try rendered.geometry.append(font.meshes[text[ch]][3]);

            try rendered.uv.append(font.glyphCoordinates[text[ch]][0]);
            try rendered.uv.append(font.glyphCoordinates[text[ch]][1]);
        }

        _ = verticalAdvance;
        _ = wrap;

        return rendered;
    }
};

pub fn getContext() *PapyrusContext {
    try assertf(gPapyrusIsInitialized == true, "Unable to initialize Papyrus, already initialized", .{});
    return gPapyrusContext;
}

pub fn initialize(allocator: std.mem.Allocator) !*PapyrusContext {
    try assertf(gPapyrusIsInitialized == false, "Unable to initialize Papyrus, already initialized", .{});
    gPapyrusIsInitialized = true;
    gPapyrusContext = try PapyrusContext.create(allocator);
    return gPapyrusContext;
}

pub fn deinitialize() void {
    gPapyrusContext.deinit();
}

// ========================  unit tests for papyrus ==========================

test "hierarchy test" {
    var ctx = try PapyrusContext.create(std.testing.allocator);
    defer ctx.deinit();

    std.debug.print(
        "\nsizeof PapyrusNode={d} for a context with 10k widgets, memory usage = {d}M, {d}K\n",
        .{ @sizeOf(PapyrusNode), @sizeOf(PapyrusNode) * 10_000 / 1024 / 1024, (@sizeOf(PapyrusNode) * 10_000 % (1024 * 1024)) / 1024 },
    );

    // example implementation of something mid-sized in this ui.
    {
        // This adds a default slot to the ui library
        // Slots can have children and can set up a few policies such as docking, etc...
        // by default this slot will be free
        var slot = try ctx.addSlot(0);
        ctx.get(slot).text = Text("slot1");

        var slot2 = try ctx.addSlot(slot);
        ctx.get(slot2).text = Text("slot2");

        var slot3 = try ctx.addSlot(slot);
        ctx.get(slot3).text = Text("slot3");

        var slot5 = try ctx.addSlot(slot);
        ctx.get(slot5).text = Text("slot5");

        var slot4 = try ctx.addSlot(slot2);
        ctx.get(slot4).text = Text("slot4");

        try ctx.writeTree(0, "before.viz");
        try grapvizDotToPng(std.testing.allocator, "before.viz", "before.png");

        try ctx.removeFromParent(slot2);
        ctx.get(try ctx.addSlot(slot3)).text = Text("slot7");

        var x = try ctx.addSlot(slot3);

        ctx.get(x).text = Text("slot8");
        ctx.get(try ctx.addSlot(x)).text = Text("slot9");
        ctx.get(try ctx.addSlot(x)).text = Text("slot10");

        try ctx.writeTree(0, "after.viz");
        try grapvizDotToPng(std.testing.allocator, "after.viz", "after.png");
    }

    ctx.tick(0.0016);
}

test "Testing a fullscreen render" {
    var ctx = try PapyrusContext.create(std.testing.allocator);
    defer ctx.deinit();

    var rend = try BmpRenderer.init(std.testing.allocator, ctx, ctx.extent);
    rend.baseColor = ColorRGBA8.fromHex(0x888888ff);
    defer rend.deinit();
    rend.setRenderFile("Saved/frame_fs00.bmp");

    var panel = try ctx.addPanel(0);
    ctx.getPanel(panel).hasTitle = true;
    ctx.getPanel(panel).titleColor = ModernStyle.GreyDark;
    ctx.get(panel).style.backgroundColor = ModernStyle.Grey;
    ctx.get(panel).style.foregroundColor = ModernStyle.BrightGrey;
    ctx.get(panel).style.borderColor = ModernStyle.Yellow;
    ctx.get(panel).pos = .{ .x = 1920 / 4 - 300, .y = 1080 / 4 };
    ctx.get(panel).size = .{ .x = 1920 / 2, .y = 1080 / 2 };

    {
        var panel2 = try ctx.addPanel(panel);
        ctx.getPanel(panel2).hasTitle = false;
        ctx.get(panel2).style = ctx.getRead(panel).style;
        ctx.get(panel2).anchor = .TopLeft;
        ctx.get(panel2).fill = .FillXY;
        ctx.get(panel2).pos = .{ .x = 1, .y = 1 };
        ctx.get(panel2).size = .{ .x = 0.80, .y = 0.80 };
        ctx.getPanel(panel2).titleColor = ModernStyle.GreyDark;
    }

    var panel2 = try ctx.addPanel(panel);
    {
        ctx.getPanel(panel2).hasTitle = false;
        ctx.get(panel2).style = ctx.getRead(panel).style;
        ctx.get(panel2).anchor = .TopRight;
        ctx.get(panel2).fill = .FillY;
        ctx.get(panel2).pos = .{ .x = -105, .y = 1 };
        ctx.get(panel2).size = .{ .x = 100, .y = 0.9 };
        ctx.getPanel(panel2).titleColor = ModernStyle.GreyDark;

        // add some text to this panel
        const text = try ctx.addText(panel, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.");
        ctx.get(text).style.foregroundColor = ModernStyle.Orange;
        ctx.get(text).pos = .{ .x = 32, .y = 32 };
        ctx.get(text).size = .{ .x = 300, .y = 400 };
    }

    {
        var panel3 = try ctx.addPanel(panel2);
        ctx.getPanel(panel3).hasTitle = true;
        ctx.getPanel(panel3).titleColor = ModernStyle.GreyDark;
        ctx.get(panel3).style = ctx.getRead(panel).style;
        ctx.get(panel3).anchor = .TopLeft;
        ctx.get(panel3).fill = .FillXY;
        ctx.get(panel3).pos = .{ .x = 0, .y = 25 };
        ctx.get(panel3).size = .{ .x = 0.9, .y = 0.9 };
    }

    try rend.render();

    rend.setRenderFile("Saved/frame_fs01.bmp");
    ctx.get(panel).pos = ctx.get(panel).pos.add(.{ .x = 300 });
    try rend.render();

    rend.setRenderFile("Saved/frame_fs02.bmp");
    ctx.get(panel).size = ctx.get(panel).size.add(.{ .x = 300, .y = 200 });
    try rend.render();
}

test "Testing a render" {
    var ctx = try PapyrusContext.create(std.testing.allocator);
    defer ctx.deinit();

    var rend = try BmpRenderer.init(std.testing.allocator, ctx, ctx.extent);
    rend.baseColor = ColorRGBA8.fromHex(0x888888ff);
    defer rend.deinit();
    rend.setRenderFile("Saved/frame.bmp");
    try ctx.fallbackFont.atlas.dumpBufferToFile("Saved/Fallback.bmp");

    var panel = try ctx.addPanel(0);
    ctx.get(panel).style.backgroundColor = ModernStyle.Grey;
    ctx.get(panel).style.foregroundColor = ModernStyle.GreyDark;
    ctx.get(panel).style.borderColor = ModernStyle.Yellow;
    ctx.get(panel).pos = .{ .x = 100, .y = 300 };
    ctx.get(panel).size = .{ .x = 400, .y = 400 };

    var panel2 = try ctx.addPanel(0);
    ctx.get(panel2).text = Text("wanker window");
    ctx.getPanel(panel2).hasTitle = true;
    ctx.get(panel2).style = ctx.get(panel).style;
    ctx.get(panel2).pos = .{ .x = 700, .y = 300 };
    ctx.get(panel2).size = .{ .x = 400, .y = 400 };

    var panel3 = try ctx.addPanel(0);
    ctx.get(panel3).text = Text("panel 3");
    ctx.getPanel(panel3).hasTitle = true;
    ctx.get(panel3).style = ctx.get(panel).style;
    ctx.get(panel3).pos = .{ .x = 1200, .y = 300 };
    ctx.get(panel3).size = .{ .x = 400, .y = 400 };

    try rend.render();
}

test "basic bmp renderer test" {
    var renderer = try BmpWriter.init(std.testing.allocator, .{ .x = 1980, .y = 1080 });

    renderer.drawRectangle(.Line, .{ .x = 500, .y = 200 }, .{ .x = 700, .y = 500 }, 255, 255, 0);
    renderer.drawRectangle(.Filled, .{}, .{ .x = 420, .y = 69 * 10 }, 69, 42, 69);

    defer renderer.deinit();

    var timer = try std.time.Timer.start();

    const startTime = timer.read();
    var atlas = try FontAtlas.initFromFile(std.testing.allocator, "fonts/ShareTechMono-Regular.ttf", 36);
    try atlas.dumpBufferToFile("Saved/atlas.bmp");
    defer atlas.deinit();

    var atlas2 = try FontAtlas.initFromFile(std.testing.allocator, "fonts/ProggyClean.ttf", 36);
    try atlas2.dumpBufferToFile("Saved/ProggyClean.bmp");
    defer atlas2.deinit();

    const endTime = timer.read();
    const duration = (@intToFloat(f64, endTime - startTime) / 1000000000);
    std.debug.print(" duration: {d}\n", .{duration});

    try renderer.writeOut("Saved/test.bmp");
}

test "dynamic pool test" {
    const TestStruct = struct {
        value1: u32 = 0,
        value4: u32 = 0,
        value2: u32 = 0,
        value3: u32 = 0,
    };

    var dynPool = DynamicPool(TestStruct).init(std.testing.allocator);
    defer dynPool.deinit();

    {
        // insert some objects objects
        var count: u32 = 1000000;
        while (count > 0) : (count -= 1) {
            _ = try dynPool.new(.{});
        }

        // Insert 1 randomly add and delete objects another million objects in groups
        var prng = std.rand.DefaultPrng.init(0x1234);
        var rand = prng.random();

        var workBuffer: [5]u32 = .{ 0, 0, 0, 0, 0 };

        count = 1000000;
        while (count > 0) : (count -= 1) {
            const index = rand.int(u32) % 5;
            var i: u32 = 0;
            while (i < index) : (i += 1) {
                workBuffer[i] = try dynPool.new(.{});
            }

            i = 0;
            while (i < index) : (i += 1) {
                dynPool.get(workBuffer[i]).?.*.value1 = 2;
                dynPool.destroy(workBuffer[i]);
            }
        }
    }
}

test "sdf fontAtlas generation" {
    var allocator = std.testing.allocator;
    var atlas = try FontAtlas.initFromFileSDF(allocator, "fonts/ShareTechMono-Regular.ttf", 65);
    defer atlas.deinit();

    try atlas.dumpBufferToFile("Saved/ComicMonoSDF.bmp");
}

test "sdf texture generation" {
    var allocator = std.testing.allocator;
    var font: c.stbtt_fontinfo = undefined;

    var fileContent = try loadFileAlloc("fonts/ComicMono.ttf", 8, allocator);
    defer allocator.free(fileContent);

    _ = c.stbtt_InitFont(&font, fileContent.ptr, c.stbtt_GetFontOffsetForIndex(fileContent.ptr, 0));

    var width: c_int = 0;
    var height: c_int = 0;
    var xoff: c_int = 0;
    var yoff: c_int = 0;

    var pixels = c.stbtt_GetCodepointSDF(
        &font,
        c.stbtt_ScaleForPixelHeight(&font, 50),
        @intCast(c_int, 'a'),
        5,
        180,
        36,
        &width,
        &height,
        &xoff,
        &yoff,
    );

    var writer = try BmpWriter.init(std.testing.allocator, .{ .x = 1980, .y = 1080 });
    defer writer.deinit();

    var pixelSlice: []const u8 = undefined;
    pixelSlice.ptr = pixels;
    pixelSlice.len = @intCast(usize, width * height);

    writer.blitBlackWhite(pixelSlice, @intCast(i32, width), @intCast(i32, height), 32, 32);
    std.debug.print("\n{d}x{d}\n", .{ width, height });

    try writer.writeOut("Saved/sdf_single_char.bmp");
}
