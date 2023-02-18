const core = @import("core.zig");
const assets = @import("assets.zig");
const std = @import("std");

const soundEngine = @import("audio/sound_engine.zig");
pub const NeonSoundEngine = soundEngine.NeonSoundEngine;
pub const sound_err = soundEngine.sound_err;
pub const sound_errs = soundEngine.sound_errs;
pub const sound_log = soundEngine.sound_log;
pub const sound_logs = soundEngine.sound_logs;

pub var gSoundEngine: *NeonSoundEngine = undefined;
pub var gSoundLoader: *soundEngine.SoundLoader = undefined;

pub fn start_module() void {
    gSoundEngine = core.gEngine.createObject(NeonSoundEngine, .{ .can_tick = true }) catch unreachable;
    gSoundLoader = std.heap.c_allocator.create(soundEngine.SoundLoader) catch unreachable;
    gSoundLoader.* = soundEngine.SoundLoader.init(gSoundEngine);

    assets.gAssetSys.registerLoader(gSoundLoader) catch unreachable;
    gSoundEngine.loadSound(core.MakeName("s_test"), "content/audio/engineTick.wav", .{}) catch unreachable;
}

pub fn shutdown_module() void {}
