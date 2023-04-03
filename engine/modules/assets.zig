const std = @import("std");
const core = @import("core.zig");

pub const asset_references = @import("assets/asset_references.zig");
pub const asset_jobs = @import("assets/asset_jobs.zig");

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

pub fn start_module() void {
    var allocator = std.heap.c_allocator;
    gAssetSys = allocator.create(AssetReferenceSys) catch unreachable;
    gAssetSys.* = AssetReferenceSys.init(allocator);
}

pub fn shutdown_module() void {}

pub fn loadList(assetList: anytype) !void {
    for (assetList) |assetImport| {
        var z1 = core.tracy.ZoneN(@src(), "Loading asset");
        core.tracy.Message(assetImport.assetRef.name.utf8);
        core.tracy.Message(assetImport.properties.path);
        try gAssetSys.loadRef(assetImport.assetRef, assetImport.properties);
        z1.End();
    }
}
