// Implemented via miniaudio

const std = @import("std");
const core = @import("../core.zig");
const assets = @import("../assets.zig");

const Name = core.Name;
const AutoHashMapUnmanaged = std.AutoHashMapUnmanaged;
const tracy = core.tracy;

const c = @import("c.zig");

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
        try self.engine.loadSound(assetRef.name, assetRef.path, .{});
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

    pub fn init(allocator: std.mem.Allocator) @This() {
        var self = @This(){
            .engine = allocator.create(c.ma_engine) catch unreachable,
            .sounds = .{},
            .allocator = allocator,
        };

        _ = c.ma_engine_init(null, self.engine);

        return self;
    }

    pub fn fire_test(self: *@This()) void {
        _ = c.ma_engine_play_sound(self.engine, "content/heyheypeople.wav", null);
    }

    pub fn loadSound(
        self: *@This(),
        soundName: core.Name,
        fileName: []const u8,
        soundParams: struct {
            looping: bool = false,
            volume: bool = false,
        },
    ) !void {
        _ = self;
        _ = soundName;
        _ = fileName;
        _ = soundParams;
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
