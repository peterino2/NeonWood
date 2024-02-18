const std = @import("std");
const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const PixelBufferRGA8 = @import("graphics/PixelBufferRGBA8.zig");

pub fn updateTextureFromPixelsSync(
    textureName: core.Name,
    pixelBuffer: PixelBufferRGA8,
) void {
    graphics.getContext().updateTextureFromPixelsSync(textureName, pixelBuffer);
}
