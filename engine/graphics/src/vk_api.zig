// global api
//
// i hate lugging these variables around.
// device and cmd buffers are fine,
// but the dispatch variables are going to be kept here and easily accessible.

pub var vkb: constants.BaseDispatch = undefined;
pub var vki: constants.InstanceDispatch = undefined;
pub var vkd: constants.DeviceDispatch = undefined;

const vk = @import("vulkan");
const constants = @import("vk_constants.zig");
