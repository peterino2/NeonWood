pub usingnamespace @cImport({
    @cDefine("GLFW_INCLUDE_NONE", {});
    @cInclude("GLFW/glfw3.h");
    @cInclude("glad/glad.h");
    @cInclude("KHR/khrplatform.h");
});
