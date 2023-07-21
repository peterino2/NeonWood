const std = @import("std");
const vk = @import("vulkan");

const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const papyrus = @import("papyrus/papyrus.zig");

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
    textureSet: *vk.DescriptorSet = undefined,

    pub fn deinit(self: @This()) void {
        _ = self;
    }

    pub fn init(
        allocator: std.mem.Allocator,
        g: *graphics.NeonVkContext,
    ) !@This() {
        var self = @This(){
            .allocator = allocator,
            .atlas = undefined,
            .g = g,
        };

        return self;
    }

    pub fn loadFont(self: *@This(), fontPath: []const u8) !void {
        self.atlas = try self.allocator.create(FontAtlas);
        self.atlas.* = try FontAtlas.initFromFileSDF(self.allocator, fontPath, 64);
    }

    pub fn prepareFont(self: *@This(), fontName: core.Name) !void {
        var pixels = try self.atlas.makeBitmapRGBA(self.allocator);
        defer self.allocator.free(pixels);
        var res = try graphics.createTextureFromPixelsSync(
            fontName,
            pixels,
            .{ .x = self.atlas.atlasSize.x, .y = self.atlas.atlasSize.y },
            self.g,
            false,
        );

        self.texture = res.texture;
        self.textureSet = res.descriptor;
    }
};

pub const DisplayText = struct {
    allocator: std.mem.Allocator,
    g: *graphics.NeonVkContext, // ref
    atlas: *FontAtlasVk, // ref
    mesh: *DynamicMesh,
    string: std.ArrayList(u8),
    stringHash: u32 = 0xffffffff,

    displaySize: f32 = 24.0,
    position: Vector2f = .{},
    boxSize: Vector2f = .{ .x = 10, .y = 10 },
    color: Color = .{ .r = 1.0, .g = 1.0, .b = 1.0 },
    wordWrap: bool = true,

    pub fn deinit(self: *@This()) void {
        self.mesh.deinit();
        self.string.deinit();
    }

    pub fn getHash(self: *@This()) u32 {
        var hash: u32 = 5381;

        for (self.string.items) |c| {
            hash = @mulWithOverflow(hash, 33)[0];
            hash = @addWithOverflow(hash, @as(u32, @intCast(c)))[0];
        }

        hash = @addWithOverflow(hash, @as(u32, @intFromFloat(self.displaySize)))[0];
        hash = @mulWithOverflow(hash, @as(u32, @intFromFloat(self.position.x)))[0];
        hash = @addWithOverflow(hash, @as(u32, @intFromFloat(self.position.y)))[0];

        hash = @mulWithOverflow(hash, @as(u32, @intFromFloat(self.boxSize.x)))[0];
        hash = @mulWithOverflow(hash, @as(u32, @intFromFloat(self.boxSize.y)))[0];
        const color = self.color;
        hash = @mulWithOverflow(hash, @as(u32, @intFromFloat(color.r + color.g * 10 + color.b * 100)))[0];

        return hash;
    }

    pub fn init(
        allocator: std.mem.Allocator,
        atlas: *FontAtlasVk,
        opts: struct {
            charLimit: u32 = 8192,
        },
    ) !@This() {
        var self = @This(){
            .g = atlas.g,
            .allocator = allocator,
            .atlas = atlas,
            .mesh = try graphics.DynamicMesh.init(atlas.g, atlas.g.allocator, .{
                .maxVertexCount = opts.charLimit * 4,
            }),
            .string = std.ArrayList(u8).init(allocator),
        };

        return self;
    }

    pub fn draw(self: *@This(), cmd: vk.CommandBuffer, textMaterial: *graphics.Material, ssboId: u32) void {
        var fontSet = self.atlas.textureSet;
        var vkd = self.g.vkd;
        var vertexBufferOffset: u64 = 0;

        vkd.cmdBindPipeline(cmd, .graphics, textMaterial.pipeline);
        vkd.cmdBindVertexBuffers(cmd, 0, 1, core.p_to_a(&self.mesh.getVertexBuffer().buffer), core.p_to_a(&vertexBufferOffset));
        vkd.cmdBindIndexBuffer(cmd, self.mesh.getIndexBuffer().buffer, 0, .uint32);
        vkd.cmdBindDescriptorSets(cmd, .graphics, textMaterial.layout, 1, 1, core.p_to_a(fontSet), 0, undefined);
        vkd.cmdDrawIndexed(cmd, self.mesh.getIndexBufferLen(), 1, 0, 0, ssboId);
    }

    pub fn setPosition(self: *@This(), position: Vector2f) void {
        self.position = position;
    }

    pub fn setBox(self: *@This(), boxSize: Vector2f) void {
        self.boxSize = boxSize;
    }

    pub fn setString(self: *@This(), str: []const u8) !void {
        self.string.clearRetainingCapacity();
        try self.string.appendSlice(str);
    }

    pub fn updateMesh(self: *@This()) !void {
        self.mesh.clearVertices();

        const atlas = self.atlas.atlas;
        const ratio = (self.displaySize) / atlas.fontSize;
        const stride = @as(f32, @floatFromInt(atlas.glyphStride)) * ratio;

        var xOffset: f32 = 0;
        var yOffset: f32 = 0;

        for (self.string.items) |ch| {
            if (!atlas.hasGlyph[ch]) {
                xOffset += stride / 2;
                continue;
            }

            if (ch == 0 or ch == '\r') {
                continue;
            }

            if (ch == ' ' or ch == '\n') {
                xOffset += stride / 2;
                continue;
            }

            if (ch == ' ') {
                xOffset += stride / 2;
                continue;
            }

            const Vector2 = papyrus.Vector2;
            const box = Vector2.fromVector2i(atlas.glyphBox1[ch]).fmul(ratio);
            const metrics = Vector2.fromVector2i(atlas.glyphMetrics[ch]).fmul(ratio);
            const baseMetrics = Vector2.fromVector2i(atlas.glyphMetrics[ch]);
            const fontHeight = @as(f32, @floatFromInt(atlas.glyphMetrics['A'].y)) * ratio;

            const uv_tl = atlas.glyphCoordinates[ch][0];

            if (xOffset + box.x > self.boxSize.x) {
                xOffset = 0;
                yOffset += fontHeight * 1.2;
            }

            var color = self.color;

            var topLeft = .{
                .x = self.position.x + xOffset + box.x,
                .y = yOffset + self.position.y + box.y + fontHeight,
            };

            var metric_size = .{ .x = metrics.x, .y = metrics.y, .z = 0 };

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

            xOffset += box.x + metrics.x;
        }
    }
};

// list of texts to display
pub const TextRenderer = struct {
    g: *graphics.NeonVkContext,
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    displays: ArrayListU(*DisplayText) = .{},
    smallDisplays: ArrayListU(*DisplayText) = .{},
    fonts: AutoHashMapU(u32, *FontAtlasVk) = .{},
    small_limit: u32,
    papyrusCtx: *papyrus.PapyrusContext,

    pub fn init(backingAllocator: std.mem.Allocator, g: *graphics.NeonVkContext, papyrusCtx: *papyrus.PapyrusContext) !*@This() {
        var self = try backingAllocator.create(@This());
        var arena = std.heap.ArenaAllocator.init(backingAllocator);
        var allocator = arena.allocator();

        self.* = .{
            .allocator = backingAllocator,
            .arena = arena,
            .g = g,
            .papyrusCtx = papyrusCtx,
            .small_limit = 256,
        };

        var new = try self.allocator.create(FontAtlasVk);
        new.* = try FontAtlasVk.init(self.allocator, self.g);
        new.isDefault = true;
        new.atlas = papyrusCtx.fallbackFont.atlas; // use default font instead of loading a font from text file
        const defaultName = core.MakeName("default");
        try new.prepareFont(defaultName);
        try self.fonts.put(allocator, defaultName.hash, new);
        self.papyrusCtx.fallbackFont.atlas.rendererHash = defaultName.hash;

        _ = try self.addFont("fonts/Roboto-Regular.ttf", core.MakeName("roboto"));

        // we can support up to 8 large text displays and 256 small displays
        // displayText with default settings is for large renders. eg. pages. code editors, etc..
        for (0..8) |i| {
            _ = i;
            _ = try self.addDisplayText(core.MakeName("default"), .{
                .charLimit = 8192 * 2,
            });
        }

        for (0..256) |i| {
            _ = i;
            _ = try self.addDisplayText(core.MakeName("default"), .{
                .charLimit = 256,
            });
        }

        return self;
    }

    pub fn addFont(self: *@This(), ttfPath: []const u8, name: core.Name) !*FontAtlasVk {
        var new = try self.allocator.create(FontAtlasVk);

        var textureName = try std.fmt.allocPrint(self.allocator, "texture.font.{s}", .{name.utf8});
        defer self.allocator.free(textureName);

        new.* = try FontAtlasVk.init(
            self.allocator,
            self.g,
        );

        try new.loadFont(ttfPath);
        try new.prepareFont(core.Name.fromUtf8(textureName));
        new.atlas.rendererHash = name.hash;
        try self.papyrusCtx.installFontAtlas(name.utf8, new.atlas);
        try self.fonts.put(self.allocator, name.hash, new);

        return new;
    }

    pub fn addDisplayText(self: *@This(), fontName: core.Name, opts: anytype) !*DisplayText {
        var new = try self.allocator.create(DisplayText);

        new.* = try DisplayText.init(
            self.allocator,
            self.fonts.get(fontName.hash).?,
            opts,
        );

        var small = opts.charLimit <= self.small_limit;

        if (small) {
            try self.smallDisplays.append(self.allocator, new);
        } else {
            try self.displays.append(self.allocator, new);
        }

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
            var rv: TextFrameAlloc = .{ .small = false, .index = frameContext.allocated };
            frameContext.allocated += 1;
            return rv;
        }

        var rv: TextFrameAlloc = .{ .small = true, .index = frameContext.allocated_small };
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

        self.displays.deinit(self.allocator);

        var iter = self.fonts.iterator();
        while (iter.next()) |i| {
            std.debug.print("ITERATION\n", .{});
            i.value_ptr.*.deinit();
        }

        self.arena.deinit();
        backingAllocator.destroy(self);
    }
};
