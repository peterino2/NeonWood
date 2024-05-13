const std = @import("std");
const core = @import("core");
const graphics = @import("graphics.zig");
const PixelBufferRGA8 = @import("PixelBufferRGBA8.zig");

pub fn updateTextureFromPixelsSync(
    textureName: core.Name,
    pixelBuffer: PixelBufferRGA8,
) void {
    graphics.getContext().updateTextureFromPixelsSync(textureName, pixelBuffer);
}
