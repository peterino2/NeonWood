pub usingnamespace @cImport({
    @cDefine("GLFW_INCLUDE_NONE", {});
    @cInclude("GLFW/glfw3.h");
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cDefine("CIMGUI_USE_GLFW", {});
    @cInclude("cimgui.h");
    @cInclude("cimgui_compat.h");
    @cInclude("cimgui_impl.h");
});

const vk = @import("vulkan");
const c = @This();
