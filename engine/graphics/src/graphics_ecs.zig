const core = @import("core");
const graphics = @import("graphics.zig");

pub fn registerEcs() !void {
    const container = core.makeEcsContainerRef(&graphics.getContext().renderObjectSet);
    try core.registerEcsContainer(container, core.MakeName("RenderObjects"));
}
