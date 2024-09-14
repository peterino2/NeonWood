const std = @import("std");
const core = @import("core");
const memory = core.MemoryTracker;

pub const asset_references = @import("asset_references.zig");
pub const asset_jobs = @import("asset_jobs.zig");

pub const AssetRef = asset_references.AssetRef;
pub const AssetReference = asset_references.AssetReference;
pub const AssetLoaderError = asset_references.AssetLoaderError;
pub const AssetLoaderInterface = asset_references.AssetLoaderInterface;
pub const AssetImportReference = asset_references.AssetImportReference;
pub const AssetPropertiesBag = asset_references.AssetPropertiesBag;
pub const AssetReferenceSys = asset_references.AssetReferenceSys;

pub const MakeImportRef = asset_references.MakeImportRef;
pub const MakeImportRefOptions = asset_references.MakeImportRefOptions;

pub const AsyncAssetJobContext = asset_jobs.AsyncAssetJobContext;

pub var gAssetSys: *AssetReferenceSys = undefined;

pub const Module = core.ModuleDescription{
    .name = "assets",
    .enabledByDefault = true,
};

pub fn start_module(comptime spec: anytype, args: anytype, allocator: std.mem.Allocator) !void {
    _ = args;
    _ = spec;
    gAssetSys = allocator.create(AssetReferenceSys) catch @panic("unable to initialize asset reference");
    gAssetSys.* = AssetReferenceSys.init(allocator);

    memory.MTPrintStatsDelta();
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    gAssetSys.deinit();

    allocator.destroy(gAssetSys);
}

pub fn loadList(assetList: anytype) !void {
    for (assetList) |assetImport| {
        try load(assetImport);
    }
}

pub fn load(assetImport: AssetImportReference) !void {
    var z1 = core.tracy.ZoneN(@src(), "Loading asset");
    core.tracy.Message(assetImport.assetRef.name.utf8());
    core.tracy.Message(assetImport.properties.path);
    try gAssetSys.loadRef(assetImport.assetRef, assetImport.properties);
    z1.End();
}
