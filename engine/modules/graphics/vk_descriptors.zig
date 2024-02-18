// higher level descriptor and SSBO wrangling libraries.

const std = @import("std");
const core = @import("../core.zig");
const vk_renderer = @import("vk_renderer.zig");
const vma = @import("vma");
const vk = @import("vulkan");
const obj_loader = @import("lib/objLoader/obj_loader.zig");
const vkinit = @import("vk_init.zig");
const vk_constants = @import("vk_constants.zig");
const tracy = core.tracy;

const spng = core.spng;

const ObjMesh = obj_loader.ObjMesh;
const ArrayList = std.ArrayList;
const Vectorf = core.Vectorf;
const NeonVkContext = vk_renderer.NeonVkContext;
const NeonVkBuffer = vk_renderer.NeonVkBuffer;
const NeonVkImage = vk_renderer.NeonVkImage;
const NumFrames = vk_constants.NUM_FRAMES;

pub const DescriptorSetLayoutInfo = struct {
    bindingCount: u32,
};
