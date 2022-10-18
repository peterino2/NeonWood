const core = @import("core.zig");
const assets = @import("assets.zig");
const std = @import("std");

const soundEngine = @import("audio/sound_engine.zig");
pub const NeonSoundEngine = soundEngine.NeonSoundEngine;

pub var gSoundEngine: *NeonSoundEngine = undefined;
pub var gSoundLoader: *soundEngine.SoundLoader = undefined;

pub fn start_module() void 
{
    gSoundEngine = core.gEngine.createObject(NeonSoundEngine, .{.can_tick = true}) catch unreachable;
    gSoundLoader = std.heap.c_allocator.create(soundEngine.SoundLoader) catch unreachable;
    gSoundLoader.* = soundEngine.SoundLoader.init(gSoundEngine);

    assets.gAssetSys.registerLoader(gSoundLoader) catch unreachable;
}

pub fn shutdown_module() void
{

}
