const std = @import("std");
const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const vk_renderer = @import("graphics/vk_renderer.zig");
const PixelBufferRGA8 = vk_renderer.PixelBufferRGA8;

pub fn updateTextureFromPixelsSync(
    textureName: core.Name,
    pixelBuffer: PixelBufferRGA8,
) void {
    graphics.getContext().updateTextureFromPixelsSync(textureName, pixelBuffer);
}
