pub const SkyboxSystem = struct {};

const vk_renderer_interface = @import("vk_renderer/vk_renderer_interface.zig");
const RendererInterface = vk_renderer_interface.RendererInterface;

const std = @import("std");

const graphics = @import("graphics.zig");
const core = @import("core");
