// global api
//
// i hate lugging these variables around.
// device and cmd buffers are fine,
// but the dispatch variables are going to be kept here and easily accessible.

pub var _vkb: constants.BaseDispatch = undefined;
pub var _vki: constants.InstanceDispatch = undefined;
pub var _vkd: constants.DeviceDispatch = undefined;

pub const vkb = &_vkb;
pub const vki = &_vki;
pub const vkd = &_vkd;

const vk = @import("vulkan");
const constants = @import("vk_constants.zig");
