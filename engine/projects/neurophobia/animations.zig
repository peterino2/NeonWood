const std = @import("std");
const nw = @import("root").neonwood;
const graphics = nw.graphics;
const core = nw.core;

const NeonVkImage = graphics.NeonVkImage;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const PixelPos = graphics.PixelPos;

pub const SpriteFrame = struct {
    topLeft: PixelPos,
    size: PixelPos,
};

pub const SpriteSheet = struct 
{
    image: *const NeonVkImage,
    frames: ArrayListUnmanaged(SpriteFrame),

    pub fn init(image: *const NeonVkImage) @This()
    {
        var self = @This(){
            .image = image,
            .frames = .{},
        };

        return self;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void
    {
        self.frames.deinit(allocator);
    }

    pub fn generateSpriteFrames(self: *@This(), allocator: std.mem.Allocator,  frameSize: PixelPos) !void {
        var currentY: u32 = 0;
        var currentX: u32 = 0;
        var sheetWidth = self.image.pixelWidth;

        while (currentX < sheetWidth) {
            try self.addFrame(allocator, .{
                .topLeft = .{ .x = currentX, .y = currentY },
                .size = frameSize,
            });
            currentX += frameSize.x;
        }
    }

    pub fn getXFrameScaling(self: @This()) core.zm.Mat
    {
        if(self.frames.items.len == 0)
        {
            return core.zm.scaling(1.0, 1.0, 1.0);
        }

        return core.zm.scaling( 1 / self.frames.items[0].size.ratio(), 1.0, 1.0);
    }

    pub fn addFrame(self: *@This(), allocator: std.mem.Allocator, frame: SpriteFrame) !void
    {
        try self.frames.append(allocator, frame);
    }

    pub fn getDimensions(self: @This()) PixelPos
    {
        return .{
            .x = self.image.pixelWidth,
            .y = self.image.pixelHeight,
        };
    }
};