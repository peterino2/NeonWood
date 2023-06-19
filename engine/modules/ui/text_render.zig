const std = @import("std");
const vk = @import("vulkan");

const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const papyrus = @import("papyrus/papyrus.zig");

const FontAtlas = papyrus.FontAtlas;
const DynamicMesh = graphics.DynamicMesh;
const ArrayListU = std.ArrayListUnmanaged;

pub const FontAtlasVk = struct {
    g: *graphics.NeonVkContext,
    allocator: std.mem.Allocator,
    atlas: *FontAtlas,
    texture: *graphics.Texture = undefined,
    textureSet: *vk.DescriptorSet = undefined,

    pub fn init(allocator: std.mem.Allocator, g: *graphics.NeonVkContext, fontPath: []const u8) !*@This() {
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

    pub fn init(
        allocator: std.mem.Allocator,
        atlas: *FontAtlasVk,
        opts: struct {
            charLimit: usize = 1024,
        },
    ) !*@This() {
        var self = try allocator.create(@This());
        self.* = @This(){
            .g = atlas.g,
            .atlas = atlas,
            .mesh = try graphics.DynamicMesh.init(atlas.g, atlas.g.allocator, .{
                .maxVertexCount = opts.charLimit * 4,
            }),
        };

        return self;
    }

    pub fn setString(self: *@This(), str: []const u8) !void {
        self.string.clearRetainingCapacity();
        try self.string.appendSlice(str);
    }
};

pub const TextRenderer = struct {
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    displays: ArrayListU(*DisplayText) = .{},
    fonts: ArrayListU(*FontAtlasVk) = .{},

    pub fn init(backingAllocator: std.mem.Allocator) !*@This() {
        var self = try backingAllocator.create(@This());
        var arena = std.heap.ArenaAllocator.init(backingAllocator);
        var allocator = arena.allocator();

        self.* = .{
            .allocator = allocator,
            .arena = arena,
            .displays = .{},
        };

        return self;
    }
};
