const lua = @import("lua");
const ecs = @import("../ecs.zig");
const pod = lua.pod;

ref: ecs.EcsContainerRef,

pub const PodDataTable: pod.DataTable = .{
    .name = "ComponentRegistration",
};
