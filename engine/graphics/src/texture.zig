const std = @import("std");
const core = @import("core");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const vkinit = @import("vk_init.zig");

const NeonVkContext = vk_renderer.NeonVkContext;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;
const NeonVkImage = vk_renderer.NeonVkImage;

pub const PixelPos = struct {
    x: u32,
    y: u32,

    /// returns y/x of the pixel position
    pub fn ratio(self: @This()) f32 {
        return @as(f32, @floatFromInt(self.y)) / @as(f32, @floatFromInt(self.x));
    }
};

// This is a simple display texture
pub const Texture = struct {
    image: NeonVkImage,
    imageView: vk.ImageView,

    pub fn deinit(self: *@This(), ctx: *NeonVkContext) void {
        ctx.vkd.destroyImageView(ctx.dev, self.imageView, null);
        self.image.deinit(ctx.vkAllocator);
    }

    pub fn getDimensions(self: @This()) PixelPos {
        return .{
            .x = self.image.pixelWidth,
            .y = self.image.pixelHeight,
        };
    }
};
