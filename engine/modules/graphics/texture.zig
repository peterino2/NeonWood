const std = @import("std");
const core = @import("../core/core.zig");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const obj_loader = @import("lib/objLoader/obj_loader.zig");
const vkinit = @import("vk_init.zig");

const p2a = core.p_to_a;
const NeonVkContext = vk_renderer.NeonVkContext;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;
const NeonVkImage = vk_renderer.NeonVkImage;

pub const Texture = struct {
    image: NeonVkImage,
    imageView: vk.ImageView,

    pub fn deinit(self: *@This(), ctx: *NeonVkContext) !void {
        ctx.vkd.destroyImageView(ctx.dev, self.imageView, null);
        self.image.deinit(ctx.vmaAllocator);
    }
};
