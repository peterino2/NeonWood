const std = @import("std");
const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const vk = @import("vulkan");

// 
const VkRendererSystem = struct{
    dev: vk.Device,
    commandBufferFences: std.ArrayListUnmanaged(vk.Fence).size(2),

    // engine object
    pub fn tick()  void
    {
    }

    pub fn create() *@This()
    {
    }

    pub fn destroy() *@This()
    {
    }
    
};

// all the stuff needed to draw this specific frame
const VkRendererState = struct{
    cameraGpu: NeonVkCameraDataGpu,

    pub fn draw(self: @This()) !void 
    {
        // 1. acquire next frame
        // 2. execute pre-frame updates
        // 3. start the main render pass and render meshes
        // 4. execute plugin renderers
        // 5. finish main renderpass
        // 6. update dynamic meshes
        // 7. finish frame
        // 8. perform resource cleanup. ( if there are any resources to clean up.)
    }
};
