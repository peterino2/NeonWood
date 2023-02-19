const std = @import("std");
const core = @import("../core.zig");
const assets = @import("../assets.zig");

const JobContext = core.JobContext;
const JobWorker = core.JobWorker;
const JobManager = core.JobManager;

const AssetReference = assets.AssetReference;

pub const AsyncAssetJobContext = struct {
    mutex: std.mutex.Mutex,
    assetLoadList: []const AssetReference,
    allocator: std.mem.Allocator,

    pub fn loadAssets(assetList: []const AssetReference, allocator: std.mem.Allocator) !*@This() {
        var this: *@This() = try allocator.create(@This());

        this.* = .{
            .mutex = .{},
            .assetLoadList = assetList,
            .allocator = allocator,
        };

        return this;
    }
};
