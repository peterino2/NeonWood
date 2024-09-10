// register core types and subsystems into the scripting engine
pub fn registerTypes() !void {
    // transform POD type

    const state = script.getState();
    // lua.pod.registerPodType(state, core.Vector, "Vector");
    // lua.pod.registerPodType(state, core.Vectorf, "Vectorf");
    try lua.pod.registerPodType(state, core.Vector2);
    try lua.pod.registerPodType(state, core.Vector2f);
    // try lua.pod.registerPodType(state, core.Transform);

    //lua.pod.registerPodType(state, core.Vector4, "Vector4");
}

const lua = @import("lua");
const std = @import("std");
const script = @import("script.zig");
const core = @import("core.zig");
