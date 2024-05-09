const std = @import("std");
const vk = @import("vulkan");

const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const memory = @import("../memory.zig");
const papyrus = @import("papyrus.zig");
const gpd = graphics.gpu_pipe_data;

const FontAtlas = papyrus.FontAtlas;
const DynamicMesh = graphics.DynamicMesh;
const ArrayListU = std.ArrayListUnmanaged;
const AutoHashMapU = std.AutoHashMapUnmanaged;

const Vector2f = core.Vector2f;
const Vectorf = core.Vectorf;
const Color = papyrus.Color;

pub const FontAtlasVk = struct {
    g: *graphics.NeonVkContext,
    allocator: std.mem.Allocator,
    isDefault: bool = false,
    atlas: *FontAtlas,
    texture: *graphics.Texture = undefined,
    textureSet: vk.DescriptorSet = undefined,
    fontName: core.Name = undefined,

    pub fn deinit(self: @This()) void {
        _ = self;
    }

    pub fn init(
        allocator: std.mem.Allocator,
        g: *graphics.NeonVkContext,
    ) !@This() {
        const self = @This(){
            .allocator = allocator,
            .atlas = undefined,
            .g = g,
        };

        return self;
    }

    pub fn loadFont(self: *@This(), papyrusCtx: *papyrus.Context, fontPath: []const u8) !void {
        self.atlas = try papyrusCtx.allocator.create(FontAtlas);
        self.atlas.* = try FontAtlas.initFromFileSDF(papyrusCtx.allocator, fontPath, 64);
    }

    pub fn prepareFont(self: *@This(), fontName: core.Name) !void {
        const pixels = try self.atlas.makeBitmapRGBA(self.allocator);
        defer self.allocator.free(pixels);
        const res = try graphics.createAndInstallTextureFromPixels(
            fontName,
            pixels,
            .{ .x = self.atlas.atlasSize.x, .y = self.atlas.atlasSize.y },
            self.g,
            false,
        );

        self.atlas.cleanUp();
        self.fontName = fontName;
        self.texture = res.texture;
        self.textureSet = res.descriptor;
    }
};

pub const DisplayText = struct {
    allocator: std.mem.Allocator,
    g: *graphics.NeonVkContext, // ref
    atlas: *FontAtlasVk, // ref
    mesh: *DynamicMesh, // we own this
    string: ?*const []const u8,
    stringHash: u32 = 0xffffffff,
    renderMode: papyrus.TextRenderMode,

    displaySize: f32 = 24.0,
    position: Vector2f = .{},
    boxSize: Vector2f = .{ .x = 10, .y = 10 },
    color: Color = .{ .r = 1.0, .g = 1.0, .b = 1.0 },
    wordWrap: bool = true,

    renderedSize: Vector2f = .{},

    renderedGeo: *papyrus.TextRenderGeometry,

    pub fn deinit(self: *@This()) void {
        self.mesh.deinit();
        self.allocator.destroy(self.mesh);
        self.renderedGeo.destroy();
    }

    pub fn getHash(self: *@This()) u32 {
        var hash: u32 = 5381;

        // todo: swap the hash into a new function.
        //
        // walk up the string list until we are alignment = 4,
        // sum everything using u32s
        // sum up the missing chars at the end.

        for (self.string.?) |c| {
            hash = @mulWithOverflow(hash, 33)[0];
            hash = @addWithOverflow(hash, @as(u32, @intCast(c)))[0];
        }

        hash = @addWithOverflow(hash, @as(u32, @bitCast(self.displaySize)))[0];
        hash = @mulWithOverflow(hash, @as(u32, @bitCast(self.position.x)))[0];
        hash = @addWithOverflow(hash, @as(u32, @bitCast(self.position.y)))[0];

        hash = @mulWithOverflow(hash, @as(u32, @bitCast(self.boxSize.x)))[0];
        hash = @mulWithOverflow(hash, @as(u32, @bitCast(self.boxSize.y)))[0];
        const color = self.color;
        hash = @mulWithOverflow(hash, @as(u32, @bitCast(color.r + color.g * 10 + color.b * 100)))[0];

        return hash;
    }

    pub fn init(
        allocator: std.mem.Allocator,
        atlas: *FontAtlasVk,
        opts: struct {
            charLimit: u32 = 8192,
        },
    ) !@This() {
        const self = @This(){
            .g = atlas.g,
            .allocator = allocator,
            .atlas = atlas,
            .renderMode = .Simple,
            .mesh = try graphics.DynamicMesh.init(atlas.g, atlas.g.allocator, .{
                .maxVertexCount = opts.charLimit * 4,
            }),
            .string = null,
            .renderedGeo = try papyrus.TextRenderGeometry.create(allocator),
        };

        return self;
    }

    pub fn draw(
        self: *@This(),
        frameIndex: usize,
        cmd: vk.CommandBuffer,
        textMaterial: *graphics.Material,
        ssboId: u32,
        textPipeData: gpd.GpuPipeData,
    ) void {
        var fontSet = self.atlas.textureSet;
        var vkd = self.g.vkd;
        var vertexBufferOffset: u64 = 0;

        vkd.cmdBindPipeline(cmd, .graphics, textMaterial.pipeline);
        vkd.cmdBindVertexBuffers(cmd, 0, 1, @ptrCast(&self.mesh.getVertexBuffer().buffer), @ptrCast(&vertexBufferOffset));
        vkd.cmdBindIndexBuffer(cmd, self.mesh.getIndexBuffer().buffer, 0, .uint32);
        vkd.cmdBindDescriptorSets(cmd, .graphics, textMaterial.layout, 0, 1, textPipeData.getDescriptorSet(frameIndex), 0, undefined);
        vkd.cmdBindDescriptorSets(cmd, .graphics, textMaterial.layout, 1, 1, @ptrCast(&fontSet), 0, undefined);
        vkd.cmdDrawIndexed(cmd, self.mesh.getIndexBufferLen(), 1, 0, 0, ssboId);
    }

    pub fn setMode(self: *@This(), mode: papyrus.TextParseMode) void {
        self.renderMode = mode;
    }

    pub fn setPosition(self: *@This(), position: Vector2f) void {
        self.position = position;
    }

    pub fn setBox(self: *@This(), boxSize: Vector2f) void {
        self.boxSize = boxSize;
    }

    pub fn setString(self: *@This(), str: *const []const u8) void {
        self.string = str;
    }

    const RenderState = struct {
        xOffset: f32 = 0,
        yOffset: f32 = 0,
    };

    pub fn updateMesh(self: *@This(), buildHitboxes: bool) !void {
        _ = buildHitboxes;
        self.mesh.clearVertices();
        try self.renderedGeo.resetAllLines();

        const atlas = self.atlas.atlas;
        const ratio = (self.displaySize) / atlas.fontSize;
        //const stride = @as(f32, @floatFromInt(atlas.glyphStride)) * ratio;
        const stride = @as(f32, @floatFromInt(atlas.glyphMetrics['l'].x)) * ratio;

        if (self.string.?.len <= 0) {
            return;
        }

        var xOffset: f32 = 0;
        var yOffset: f32 = 0;
        const fontHeight = @as(f32, @floatFromInt(atlas.glyphMetrics['l'].y)) * ratio;

        self.renderedGeo.setCharHeight(fontHeight);
        self.renderedGeo.setPosition(self.position);
        try self.renderedGeo.addGeoLine(yOffset + self.position.y, 0);

        var largestXOffset: f32 = 0;

        for (self.string.?.*, 0..) |ch, i| {
            if (i * 4 > self.mesh.maxVertexCount) {
                break;
            }

            if (!atlas.hasGlyph[ch]) {
                try self.renderedGeo.addCharGeo(self.position.x + xOffset, stride, @intCast(i));
                xOffset += stride;
                continue;
            }

            if (ch == 0 or ch == '\r') {
                continue;
            }

            if (ch == ' ' or (ch == '\n' and self.renderMode == .NoControl)) {
                try self.renderedGeo.addCharGeo(self.position.x + xOffset, stride, @intCast(i));
                xOffset += stride;
                continue;
            }

            // newline if we see newline and we're in simple or rich mode.
            if (ch == '\n' and (self.renderMode == .Simple or self.renderMode == .Rich)) {
                try self.renderedGeo.addCharGeo(self.position.x + xOffset, stride, @intCast(i));
                xOffset = 0;
                yOffset += fontHeight * 1.2;
                try self.renderedGeo.addGeoLine(yOffset + self.position.y, @intCast(i));
                continue;
            }

            if (ch == ' ') {
                try self.renderedGeo.addCharGeo(self.position.x + xOffset, stride, @intCast(i));
                xOffset += stride;
                continue;
            }

            const box = Vector2f.from(atlas.glyphBox1[ch]).fmul(ratio);
            const metrics = Vector2f.from(atlas.glyphMetrics[ch]).fmul(ratio);
            const baseMetrics = Vector2f.from(atlas.glyphMetrics[ch]);

            const uv_tl = atlas.glyphCoordinates[ch][0];

            xOffset += box.x;

            //if (xOffset + box.x + metrics.x > self.boxSize.x) {
            if (xOffset + box.x + metrics.x > self.boxSize.x) {
                xOffset = 0;
                yOffset += fontHeight * 1.2;
                try self.renderedGeo.addGeoLine(yOffset + self.position.y, @intCast(i));
            }

            const color = self.color;

            const topLeft = .{
                // .x = self.position.x + xOffset + box.x,
                // .y = yOffset + self.position.y + box.y + fontHeight,
                .x = xOffset,
                .y = yOffset + box.y + fontHeight,
            };

            const metric_size = .{ .x = metrics.x, .y = metrics.y, .z = 0 };

            self.mesh.addQuad2D(
                topLeft,
                metric_size,
                .{ .x = uv_tl.x, .y = uv_tl.y }, // uv topleft
                .{
                    .x = baseMetrics.x / @as(f32, @floatFromInt(atlas.atlasSize.x)),
                    .y = baseMetrics.y / @as(f32, @floatFromInt(atlas.atlasSize.y)),
                }, // uv size
                .{ .r = color.r, .g = color.g, .b = color.b }, // color
            );

            // todo insert geo
            //try self.renderedGeo.addCharGeo(self.position.x + xOffset, box.x + metrics.x, @intCast(i));
            //xOffset += box.x + metrics.x;

            try self.renderedGeo.addCharGeo(self.position.x + xOffset, metrics.x, @intCast(i));
            xOffset += metrics.x;

            if (xOffset > largestXOffset) {
                largestXOffset = xOffset;
            }
        }

        try self.renderedGeo.addCharGeo(self.position.x + xOffset, 200.0, @intCast(self.string.?.len));
        self.renderedSize = .{
            .x = largestXOffset,
            .y = yOffset + fontHeight * 1.2,
        };

        self.renderedGeo.setBoundsX(self.position.x, self.position.x + self.renderedSize.x);
    }
};

// list of texts to display
pub const TextRenderer = struct {
    g: *graphics.NeonVkContext,
    allocator: std.mem.Allocator,
    backingAllocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    displays: ArrayListU(*DisplayText) = .{},
    smallDisplays: ArrayListU(*DisplayText) = .{},
    fonts: AutoHashMapU(u32, *FontAtlasVk) = .{},
    small_limit: u32,
    papyrusCtx: *papyrus.Context,

    pub fn init(backingAllocator: std.mem.Allocator, g: *graphics.NeonVkContext, papyrusCtx: *papyrus.Context) !*@This() {
        var self = try backingAllocator.create(@This());

        self.* = .{
            .allocator = undefined,
            .backingAllocator = backingAllocator,
            .arena = std.heap.ArenaAllocator.init(backingAllocator),
            .g = g,
            .papyrusCtx = papyrusCtx,
            .small_limit = 512,
        };

        self.allocator = self.arena.allocator();

        var new = try self.allocator.create(FontAtlasVk);
        new.* = try FontAtlasVk.init(self.allocator, self.g);
        new.isDefault = true;
        new.atlas = papyrusCtx.defaultFont.atlas; // use default font instead of loading a font from text file
        const defaultName = core.MakeName("default");
        try new.prepareFont(defaultName);
        try self.fonts.put(self.allocator, defaultName.handle(), new);
        self.papyrusCtx.defaultFont.atlas.rendererHash = defaultName.handle();

        var newMono = try self.allocator.create(FontAtlasVk);
        newMono.* = try FontAtlasVk.init(self.allocator, self.g);
        newMono.isDefault = true;
        newMono.atlas = papyrusCtx.defaultMonoFont.atlas;

        const monoName = core.MakeName("monospace");
        try newMono.prepareFont(monoName);
        try self.fonts.put(self.allocator, monoName.handle(), newMono);
        self.papyrusCtx.defaultMonoFont.atlas.rendererHash = monoName.handle();

        {
            var newbitmap = try self.allocator.create(FontAtlasVk);
            newbitmap.* = try FontAtlasVk.init(self.allocator, self.g);
            newbitmap.isDefault = true;
            newbitmap.atlas = papyrusCtx.defaultBitmapFont.atlas;

            const bitmapName = core.MakeName("bitmap");

            try newbitmap.prepareFont(bitmapName);
            try self.fonts.put(self.allocator, bitmapName.handle(), newbitmap);
            self.papyrusCtx.defaultBitmapFont.setRendererHash(bitmapName.handle());
        }

        var k: u32 = 0;
        // we can support up to 32 large text displays and 256 small displays
        // displayText with default settings is for large renders. eg. pages. code editors, etc..
        for (0..4) |i| {
            _ = i;
            const newDisplay = try self.addDisplayText(core.MakeName("default"), .{
                .charLimit = 8192,
            });

            k += 1;
            try self.displays.append(self.allocator, newDisplay);
        }

        for (0..64) |i| {
            _ = i;
            const newDisplay = try self.addDisplayText(core.MakeName("default"), .{
                .charLimit = 512,
            });

            k += 1;
            try self.smallDisplays.append(self.allocator, newDisplay);
        }

        return self;
    }

    pub fn addFont(self: *@This(), ttfPath: []const u8, name: core.Name) !*FontAtlasVk {
        var new = try self.allocator.create(FontAtlasVk);

        const textureName = try std.fmt.allocPrint(self.allocator, "texture.font.{s}", .{name.utf8()});
        defer self.allocator.free(textureName);

        new.* = try FontAtlasVk.init(
            self.allocator,
            self.g,
        );

        try new.loadFont(self.papyrusCtx, ttfPath);
        try new.prepareFont(core.Name.fromUtf8(textureName));
        new.atlas.rendererHash = name.handle();
        try self.papyrusCtx.installFontAtlas(name.utf8(), new.atlas);
        try self.fonts.put(self.allocator, name.handle(), new);

        return new;
    }

    pub fn addDisplayText(self: *@This(), fontName: core.Name, opts: anytype) !*DisplayText {
        const new = try self.allocator.create(DisplayText);

        new.* = try DisplayText.init(
            self.allocator,
            self.fonts.get(fontName.handle()).?,
            opts,
        );

        return new;
    }

    pub const TextFrameContext = struct {
        allocated: u32 = 0,
        allocated_small: u32 = 0,
    };

    pub const TextFrameAlloc =
        struct { index: u32, small: bool };

    pub fn startRendering(_: @This()) TextFrameContext {
        return .{};
    }

    pub fn getNextSlot(self: *@This(), len: usize, frameContext: *TextFrameContext) TextFrameAlloc {
        if (len >= self.small_limit) {
            const rv: TextFrameAlloc = .{ .small = false, .index = frameContext.allocated };
            frameContext.allocated += 1;
            return rv;
        }

        const rv: TextFrameAlloc = .{ .small = true, .index = frameContext.allocated_small };
        frameContext.allocated_small += 1;
        return rv;
    }

    pub fn deinit(self: *@This(), backingAllocator: std.mem.Allocator) void {
        for (self.displays.items) |display| {
            display.deinit();
        }

        for (self.smallDisplays.items) |display| {
            display.deinit();
        }

        self.arena.deinit();
        backingAllocator.destroy(self);
    }
};
