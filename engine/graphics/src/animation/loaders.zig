pub const AnimationLoader = struct {
    pub var LoaderInterfaceVTable: assets.AssetLoaderInterface = assets.AssetLoaderInterface.from("Animation", @This());
    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    sys: *animation_system.AnimationSystem,

    pub fn discardAll(self: *@This()) void {
        _ = self;
    }

    pub fn loadAsset(self: *@This(), assetRef: assets.AssetRef, propertiesBag: ?assets.AssetPropertiesBag) assets.AssetLoaderError!void {
        const animation = ozz.Animation.create();

        const mapping = core.fs().loadFile(propertiesBag.?.path) catch return error.UnableToLoad;
        defer core.fs().unmap(mapping);
        animation.loadFromBytes(mapping.bytes);

        self.sys.newAnimTrack(assetRef.name, animation) catch return error.UnableToLoad;
    }

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .sys = animation_system.gAnimationSys,
        };

        return self;
    }

    pub fn destroy(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.destroy(self);
    }
};

pub const SkeletonLoader = struct {
    pub var LoaderInterfaceVTable: assets.AssetLoaderInterface = assets.AssetLoaderInterface.from("Skeleton", @This());
    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    sys: *animation_system.AnimationSystem,

    pub fn discardAll(self: *@This()) void {
        _ = self;
    }

    pub fn loadAsset(self: *@This(), assetRef: assets.AssetRef, propertiesBag: ?assets.AssetPropertiesBag) assets.AssetLoaderError!void {
        const sk = ozz.Skeleton.create();

        const mapping = core.fs().loadFile(propertiesBag.?.path) catch return error.UnableToLoad;
        defer core.fs().unmap(mapping);
        sk.loadFromBytes(mapping.bytes);

        self.sys.newSkeleton(assetRef.name, sk) catch return error.UnableToLoad;
    }

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .sys = animation_system.gAnimationSys,
        };

        return self;
    }

    pub fn destroy(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.destroy(self);
    }
};

pub var gSkeletonLoader: *SkeletonLoader = undefined;
pub var gAnimationLoader: *AnimationLoader = undefined;

pub fn initLoaders() !void {
    gSkeletonLoader = try core.createObject(SkeletonLoader, .{});
    gAnimationLoader = try core.createObject(AnimationLoader, .{});

    try assets.gAssetSys.registerLoader(gSkeletonLoader);
    try assets.gAssetSys.registerLoader(gAnimationLoader);
}

const animation_system = @import("animationSystem.zig");
const assets = @import("assets");
const core = @import("core");
const std = @import("std");
const ozz = @import("ozz");
