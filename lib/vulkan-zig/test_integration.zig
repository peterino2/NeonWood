const vk = @import("vulkan");

const std = @import("std");
pub const BaseDispatch = vk.BaseWrapper(.{
    .createInstance = true,
    .getInstanceProcAddr = true,
    .enumerateInstanceVersion = true,
    .enumerateInstanceLayerProperties = true,
    .enumerateInstanceExtensionProperties = true,
});

test "hello-vulkan" {
    std.debug.print("GENERATED API VERSION = {any}\n", .{vk.HEADER_VERSION});
    std.debug.print("vkb table size = {d}\n", .{@sizeOf(BaseDispatch)});
}
