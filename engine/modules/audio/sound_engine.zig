// Implemented via miniaudio

const std = @import("std");
const core = @import("../core.zig");
const assets = @import("../assets.zig");

const Name = core.Name;
const AutoHashMapUnmanaged = std.AutoHashMapUnmanaged;
const tracy = core.tracy;

const c = @import("c.zig");

pub fn sound_log(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[SOUND     ]: " ++ fmt ++ "\n", args);
}

pub fn sound_logs(comptime fmt: []const u8) void {
    std.debug.print("[SOUND     ]: " ++ fmt ++ "\n", .{});
}

pub fn sound_err(comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[SOUND     ]: ERROR!! " ++ fmt ++ "\n", args);
}

pub fn sound_errs(comptime fmt: []const u8) void {
    std.debug.print("[SOUND     ]: ERROR!!" ++ fmt ++ "\n", .{});
}

pub const SoundLoader = struct {
    pub const LoaderInterfaceVTable = assets.AssetLoaderInterface.from(core.MakeName("Sound"), @This());

    engine: *NeonSoundEngine,

    pub fn init(engine: *NeonSoundEngine) @This() {
        return @This(){
            .engine = engine,
        };
    }

    pub fn loadAsset(self: *@This(), assetRef: assets.AssetRef) assets.AssetLoaderError!void {
        core.engine_log("loading sound asset {s}", .{assetRef.path});
        self.engine.loadSound(assetRef.name, assetRef.path, .{
            .volume = assetRef.properties.soundVolume,
        }) catch { 
            core.engine_log("unable to load sound {s}", .{assetRef.name.utf8});
        };
    }
};

fn ma_res(value: anytype) !void {
    if (value != c.MA_SUCCESS) {
        core.engine_err("miniaudio error value: {d}", .{value});
        return error.MA_ERROR;
    }
}
// On init, SoundEngine will spawn a
pub const NeonSoundEngine = struct {
    pub const NeonObjectTable = core.RttiData.from(@This());

    engine: *c.ma_engine,
    sounds: AutoHashMapUnmanaged(u32, *c.ma_sound),
    allocator: std.mem.Allocator,
    volume: f32 = 1.0,

    pub fn init(allocator: std.mem.Allocator) @This() {
        var self = @This(){
            .engine = allocator.create(c.ma_engine) catch unreachable,
            .sounds = .{},
            .allocator = allocator,
        };

        _ = c.ma_engine_init(null, self.engine);

        return self;
    }

    pub fn loadSound(
        self: *@This(),
        soundName: core.Name,
        fileName: []const u8,
        soundParams: struct {
            looping: bool = false,
            volume: f32 = 1.0,
        },
    ) !void {
        var sound = try self.allocator.create(c.ma_sound);
        errdefer self.allocator.destroy(sound);

        var res = c.ma_sound_init_from_file(self.engine, fileName.ptr, 0, null, null, sound);
        if(res != c.MA_SUCCESS)
        {
            sound_err("tried loading sound: {s} failed", .{soundName.utf8});
            return error.MiniAudioError;
        }

        try self.sounds.put(self.allocator, soundName.hash, sound);
        c.ma_sound_set_volume(sound, soundParams.volume);
    }

    pub fn playSound(self: *@This(), soundName: core.Name) !void
    {
        var maybeSound = self.sounds.get(soundName.hash);

        if(maybeSound == null)
            return error.NoSoundError;

        var sound = maybeSound.?;

        if(c.ma_sound_start(sound) != c.MA_SUCCESS)
            sound_err("unable to start sound: {s}", .{soundName.utf8});
    }

    pub fn setVolume(self: *@This(), volume: f32) void 
    {
        self.volume = volume;
        _ = c.ma_engine_set_volume(self.engine, volume);
    }

    pub fn stopSound(self: *@This(), soundName: core.Name) void
    {
        var sound = self.sounds.get(soundName.hash).?;

        if(c.ma_sound_stop(sound) != c.MA_SUCCESS)
        {
            //
        }
    }

    pub fn deinit(self: *@This()) void {
        // c.ma_engine_uninit(self.engine);
        self.allocator.destroy(self.engine);

        var iter = self.sounds.iterator();
        while (iter.next()) |sound| {
            self.allocator.destroy(sound.value_ptr.*);
        }
        self.sounds.deinit(self.allocator);
    }

    pub fn tick(self: *@This(), deltaTime: f64) void {
        var z = tracy.ZoneNC(@src(), "audio engine tick", 0xABBADD);
        defer z.End();

        _ = self;
        _ = deltaTime;
    }
};
