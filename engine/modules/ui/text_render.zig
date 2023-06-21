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

pub const FontAtlasVk = struct {
    g: *graphics.NeonVkContext,
    allocator: std.mem.Allocator,
    atlas: *FontAtlas,
    texture: *graphics.Texture = undefined,
    textureSet: *vk.DescriptorSet = undefined,

    pub fn init(
        allocator: std.mem.Allocator,
        g: *graphics.NeonVkContext,
        fontPath: []const u8,
    ) !@This() {
        var self = try allocator.create(@This());

        self.* = .{
            .allocator = allocator,
            .atlas = try FontAtlas.initFromFileSDF(allocator, fontPath, 64),
            .g = g,
        };

        return self;
    }

    fn prepareFont(self: *@This(), fontName: core.Name) !void {
        var pixels = try self.fontAtlas.makeBitmapRGBA(self.allocator);
        defer self.allocator.free(pixels);
        var res = try graphics.createTextureFromPixelsSync(
            fontName,
            pixels,
            .{ .x = self.fontAtlas.atlasSize.x, .y = self.fontAtlas.atlasSize.y },
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
    string: std.ArrayListUnmanaged(u8),

    displaySize: f32 = 16.0,
    position: Vector2f = .{},
    boxSize: Vector2f = .{},

    pub fn init(
        allocator: std.mem.Allocator,
        atlas: *FontAtlasVk,
        opts: struct {
            charLimit: usize = 1024,
        },
    ) !@This() {
        var self = @This(){
            .g = atlas.g,
            .allocator = allocator,
            .atlas = atlas,
            .mesh = try graphics.DynamicMesh.init(atlas.g, atlas.g.allocator, .{
                .maxVertexCount = opts.charLimit * 4,
            }),
        };

        return self;
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
        const atlas = self.atlas.atlas;

        const ratio = (self.displaySize) / atlas.fontSize;
        const stride = @intToFloat(f32, atlas.glyphStride) * ratio;

        var xOffset = self.position.x;

        for (self.string.items) |ch| {
            if (!atlas.hasGlyph[ch]) {
                xOffset += stride;
            }
        }
    }
};

pub const TextRenderer = struct {
    g: *graphics.NeonVkContext,
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    displays: ArrayListU(*DisplayText) = .{},
    fonts: AutoHashMapU(u32, *FontAtlasVk) = .{},

    pub fn init(backingAllocator: std.mem.Allocator, g: *graphics.NeonVkContext) !*@This() {
        var self = try backingAllocator.create(@This());
        var arena = std.heap.ArenaAllocator.init(backingAllocator);
        var allocator = arena.allocator();

        self.* = .{
            .allocator = allocator,
            .arena = arena,
            .g = g,
        };

        return self;
    }

    pub fn addFont(self: *@This(), ttfPath: []const u8, name: core.Name) !*FontAtlasVk {
        var new = try self.allocator.create(FontAtlasVk);

        var textureName = std.fmt.allocPrint(self.allocator, "");
        defer self.allocator.free(textureName);

        new.* = try FontAtlasVk.init(
            self.allocator,
            self.g,
            ttfPath,
        );
        self.FontAtlasVk.prepareFont(core.Name.fromUtf8(textureName));

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

        try self.displays.append(new);

        return new;
    }

    pub fn deinit(self: *@This(), backingAllocator: std.mem.Allocator) void {
        self.arena.deinit();
        backingAllocator.destroy(self);
    }
};
