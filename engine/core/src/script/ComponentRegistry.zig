ref: ecs.EcsContainerRef = undefined,

pub const PodDataTable: pod.DataTable = .{
    .name = "ComponentRegistration",
};

const lua = @import("lua");
const ecs = @import("../ecs.zig");
const pod = lua.pod;
