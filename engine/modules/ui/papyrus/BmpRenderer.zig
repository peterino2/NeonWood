const std = @import("std");
const PapyrusContext = @import("papyrus.zig").PapyrusContext;

const core = @import("root").neonwood.core;
const Vector2i = core.Vector2i;
const Vector2 = core.Vector2;

const colors = @import("colors.zig");
const ColorRGBA8 = colors.ColorRGBA8;
const Color = colors.Color;

const LocText = @import("localization.zig").LocText;

const PapyrusFont = @import("PapyrusFont.zig");
const FontAtlas = PapyrusFont.FontAtlas;

// Bmp software renderer
// This is a backend agnostic testing renderer which just renders outlines to a bmp file
// Used for testing Layouts.

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

    var drawList = PapyrusContext.DrawList.init(self.ui.allocator);
    try self.ui.makeDrawList(&drawList);
    defer drawList.deinit();

    const tend = timer.read();
    const duration = (@as(f64, @floatFromInt(tend - tstart)) / 1000);
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

pub const BmpWriter = struct {
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
        var pixelBuffer = try allocator.alloc(u8, @as(usize, @intCast(resolution.x * resolution.y * 3)));
        @memset(pixelBuffer, 0x8);
        return .{ .allocator = allocator, .pixelBuffer = pixelBuffer, .extent = resolution };
    }

    pub fn blitBlackWhite(self: *@This(), pixels: []const u8, width: i32, height: i32, xPos: i32, yPos: i32) void {
        var x: i32 = 0;
        var y: i32 = 0;

        while (y < height) : (y += 1) {
            x = 0;
            while (x < width) : (x += 1) {
                const i = (x + xPos + (@as(i32, @intCast(self.extent.y)) - y - yPos) * @as(i32, @intCast(self.extent.x))) * 3;
                const clamped = @as(usize, @intCast(@max(i, 0)));
                self.pixelBuffer[clamped + 0] = pixels[@as(usize, @intCast(y * width + x))];
                self.pixelBuffer[clamped + 1] = pixels[@as(usize, @intCast(y * width + x))];
                self.pixelBuffer[clamped + 2] = pixels[@as(usize, @intCast(y * width + x))];
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
                const pixelOffset = @as(usize, @intCast((atlas.glyphStride * ch) + col + row * atlas.atlasSize.x));
                const pixelOffset2 = @as(usize, @intCast(((self.extent.y - pos.y - row) * self.extent.x) + pos.x + col));

                const alpha = @as(f32, @floatFromInt(atlas.atlasBuffer.?[pixelOffset])) / 255;
                const old = Color.fromRGB2(
                    @as(f32, @floatFromInt(self.pixelBuffer[pixelOffset2 * 3 + 2])) / 255,
                    @as(f32, @floatFromInt(self.pixelBuffer[pixelOffset2 * 3 + 1])) / 255,
                    @as(f32, @floatFromInt(self.pixelBuffer[pixelOffset2 * 3 + 0])) / 255,
                );

                const new = ColorRGBA8{
                    .r = @as(u8, @intFromFloat(255 * (alpha * color.r + (1 - alpha) * old.r))),
                    .g = @as(u8, @intFromFloat(255 * (alpha * color.g + (1 - alpha) * old.g))),
                    .b = @as(u8, @intFromFloat(255 * (alpha * color.r + (1 - alpha) * old.b))),
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
                    .y = @as(i32, @intFromFloat(atlas.fontSize)),
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
                    const pixelOffset = @as(usize, @intCast(flippedRow * self.extent.x + col));

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
                    const pixelOffset = @as(usize, @intCast((flippedRow) * self.extent.x + col));

                    self.pixelBuffer[pixelOffset * 3 + 2] = r;
                    self.pixelBuffer[pixelOffset * 3 + 1] = g;
                    self.pixelBuffer[pixelOffset * 3 + 0] = b;
                }
            }

            {
                const col = topLeft.x + size.x;
                if (col >= 0 and col < self.extent.x) {
                    const pixelOffset = @as(usize, @intCast(flippedRow * self.extent.x + col));

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
            .filesize = @as(u32, @intCast(self.extent.x * self.extent.y * 3 + @as(u32, @intCast(@sizeOf(FileHeader))))),
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
            .width = @as(u32, @intCast(self.extent.x)),
            .height = @as(u32, @intCast(self.extent.y)),
            .imageSize = @as(u32, @intCast(self.extent.x * self.extent.y * 3)),
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
