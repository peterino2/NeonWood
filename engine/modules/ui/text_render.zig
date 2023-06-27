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
    atlas: *FontAtlas,
    texture: *graphics.Texture = undefined,
    textureSet: *vk.DescriptorSet = undefined,

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
    g: *graphics.NeonVkContext,
    atlas: *FontAtlasVk,
    mesh: *DynamicMesh,
    string: std.ArrayList(u8),

    displaySize: f32 = 24.0,
    position: Vector2f = .{},
    boxSize: Vector2f = .{ .x = 10, .y = 10 },
    color: Color = .{ .r = 1.0, .g = 1.0, .b = 1.0 },

    pub fn deinit(self: *@This()) void {
        _ = self;
    }

    pub fn init(
        allocator: std.mem.Allocator,
        atlas: *FontAtlasVk,
        opts: struct {
            charLimit: u32 = 1024,
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
        try self.string.appendSlice("the quick brown fox jumps over the lazy dog [2 + 2 is 4]");

        return self;
    }

    pub fn draw(self: *@This(), cmd: vk.CommandBuffer, textMaterial: *graphics.Material) void {
        var fontSet = self.atlas.textureSet;
        var vkd = self.g.vkd;
        var vertexBufferOffset: u64 = 0;

        vkd.cmdBindPipeline(cmd, .graphics, textMaterial.pipeline);
        vkd.cmdBindVertexBuffers(cmd, 0, 1, core.p_to_a(&self.mesh.getVertexBuffer().buffer), core.p_to_a(&vertexBufferOffset));
        vkd.cmdBindIndexBuffer(cmd, self.mesh.getIndexBuffer().buffer, 0, .uint32);
        vkd.cmdBindDescriptorSets(cmd, .graphics, textMaterial.layout, 1, 1, core.p_to_a(fontSet), 0, undefined);
        vkd.cmdDrawIndexed(cmd, self.mesh.getIndexBufferLen(), 1, 0, 0, 0);
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
        // todo. do a hash check.
        self.mesh.clearVertices();

        const atlas = self.atlas.atlas;

        const ratio = (self.displaySize) / atlas.fontSize;
        const stride = @intToFloat(f32, atlas.glyphStride) * ratio;

        var xOffset = self.position.x;
        var yOffset: f32 = 0;

        for (self.string.items) |ch| {
            if (!atlas.hasGlyph[ch]) {
                xOffset += stride / 2;
                continue;
            }

            const Vector2 = papyrus.Vector2;
            const box = Vector2.fromVector2i(atlas.glyphBox1[ch]).fmul(ratio);
            const metrics = Vector2.fromVector2i(atlas.glyphMetrics[ch]).fmul(ratio);
            const baseMetrics = Vector2.fromVector2i(atlas.glyphMetrics[ch]);
            const fontHeight = @intToFloat(f32, atlas.glyphMetrics['A'].y) * ratio;

            const uv_tl = atlas.glyphCoordinates[ch][0];

            if (xOffset + box.x > self.boxSize.x) {
                xOffset = 0;
                yOffset += fontHeight;
            }

            self.mesh.addQuad2D(
                .{ .x = xOffset + box.x, .y = yOffset + self.position.y + box.y + fontHeight, .z = 0 }, // top left
                .{ .x = metrics.x, .y = metrics.y, .z = 0 },
                .{ .x = uv_tl.x, .y = uv_tl.y }, // uv topleft
                .{
                    .x = baseMetrics.x / @intToFloat(f32, atlas.atlasSize.x),
                    .y = baseMetrics.y / @intToFloat(f32, atlas.atlasSize.y),
                }, // uv size
                .{ .r = self.color.r, .g = self.color.g, .b = self.color.b }, // color
            );

            if (ch == ' ') {
                xOffset += stride / 2;
            } else {
                xOffset += box.x + metrics.x;
            }
        }
    }
};

// list of texts to display
pub const TextRenderer = struct {
    g: *graphics.NeonVkContext,
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    displays: ArrayListU(*DisplayText) = .{},
    fonts: AutoHashMapU(u32, *FontAtlasVk) = .{},
    papyrusCtx: *papyrus.PapyrusContext,

    pub fn init(backingAllocator: std.mem.Allocator, g: *graphics.NeonVkContext, papyrusCtx: *papyrus.PapyrusContext) !*@This() {
        var self = try backingAllocator.create(@This());
        var arena = std.heap.ArenaAllocator.init(backingAllocator);
        var allocator = arena.allocator();

        self.* = .{
            .allocator = allocator,
            .arena = arena,
            .g = g,
            .papyrusCtx = papyrusCtx,
        };

        var new = try self.allocator.create(FontAtlasVk);
        new.* = try FontAtlasVk.init(self.allocator, self.g);
        new.atlas = papyrusCtx.fallbackFont.atlas; // use default font instead of loading a font from text file
        try new.prepareFont(core.MakeName("default"));

        try self.fonts.put(allocator, core.MakeName("default").hash, new);

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

        try self.displays.append(self.allocator, new);

        return new;
    }

    pub fn deinit(self: *@This(), backingAllocator: std.mem.Allocator) void {
        self.arena.deinit();
        backingAllocator.destroy(self);
    }
};
