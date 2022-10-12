const core = @import("core.zig");
const std = @import("std");

const soundEngine = @import("audio/sound_engine.zig");
pub const NeonSoundEngine = soundEngine.NeonSoundEngine;

pub var gSoundEngine: *NeonSoundEngine = undefined;

pub fn start_module() void 
{
    gSoundEngine = core.gEngine.createObject(NeonSoundEngine, .{.can_tick = true}) catch unreachable;
}

pub fn shutdown_module() void
{

}
