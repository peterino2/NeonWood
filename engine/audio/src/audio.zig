const core = @import("core");
const assets = @import("assets");
const std = @import("std");
const memory = core.MemoryTracker;

const soundEngine = @import("sound_engine.zig");
pub const NeonSoundEngine = soundEngine.NeonSoundEngine;
pub const sound_err = soundEngine.sound_err;
pub const sound_errs = soundEngine.sound_errs;
pub const sound_log = soundEngine.sound_log;
pub const sound_logs = soundEngine.sound_logs;

pub var gSoundEngine: *NeonSoundEngine = undefined;
pub var gSoundLoader: *soundEngine.SoundLoader = undefined;

pub fn start_module(allocator: std.mem.Allocator) !void {
    gSoundEngine = core.gEngine.createObject(NeonSoundEngine, .{ .can_tick = true }) catch unreachable;
    gSoundLoader = allocator.create(soundEngine.SoundLoader) catch unreachable;
    gSoundLoader.* = soundEngine.SoundLoader.init(gSoundEngine);

    assets.gAssetSys.registerLoader(gSoundLoader) catch unreachable;
    gSoundEngine.loadSound(core.MakeName("s_test"), "content/sounds/engineTick.wav", .{}) catch unreachable;

    core.engine_logs("sound start_module");
    memory.MTPrintStatsDelta();
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    _ = allocator;
    gSoundEngine.shutdown();
}

pub const Module = core.ModuleDescription{
    .name = "audio",
    .enabledByDefault = false,
};
