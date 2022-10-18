const std = @import("std");
const core = @import("../core.zig");
const assets = @import("../assets.zig");

const JobContext = core.JobContext;
const JobWorker = core.JobWorker;
const JobManager = core.JobManager;

const AssetReference = assets.AssetReference;

const AsyncAssetJobContext = struct {
    mutex: std.mutex.Mutex,
    asset: AssetReference,
};