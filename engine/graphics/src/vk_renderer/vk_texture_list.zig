// this implements the global texture list

const gTextureList: *TextureList = undefined;

pub const ArrayedTexture = struct {};

pub const TextureList = struct {
    allocator: std.mem.Allocator,

    pub fn create(gc: *NeonVkContext) !*@This() {
        const self = try gc.allocator.create(@This());

        self.* = .{
            .allocator = gc.allocator,
        };

        return self;
    }

    pub fn createTextureList(: []*Texture) void
    {
    }

    pub fn destroy(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

const graphics = @import("graphics");
const NeonVkContext = graphics.NeonVkContext;

const std = @import("std");
