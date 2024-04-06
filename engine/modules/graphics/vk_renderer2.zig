const std = @import("std");
const core = @import("../core.zig");
const graphics = @import("../graphics.zig");

// 
const VkRendererSystem = struct{
    commandBufferFences: ArrayListU().size(2),
    
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

const VkRendererState = struct{
    cameraGpu: NeonVkCameraDataGpu,
};
