const std = @import("std");
const core = @import("../core.zig");

pub const AssetReference = struct {
    name: core.Name,
    path: []const u8,
};

pub const AssetPropertiesBag = struct{
    soundVolume: f32 = 1.0,
    soundLooping: bool = false,
    textureUseBlockySampler: bool = true,
};

// newer API contains info about how to load things as well.
pub const AssetRef = struct {
    name: core.Name,
    assetType: core.Name,
    path: []const u8,
    properties: AssetPropertiesBag = .{},
};

// very minimal asset loading library.
pub const AssetLoaderError = error {
    UnableToLoad,
};

pub const AssetLoaderInterface = struct {
    typeName: core.Name,
    typeSize: usize,
    typeAlign: usize,

    assetType: core.Name,
    loadAsset: fn (*anyopaque, AssetRef) AssetLoaderError!void,

    pub fn from(comptime assetType: core.Name, comptime TargetType: type) @This()
    {
        const wrappedFuncs = struct {
            pub fn loadAsset(pointer: *anyopaque, assetRef: AssetRef) AssetLoaderError!void {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                try ptr.loadAsset(assetRef);
            }
        };

        if (!@hasDecl(TargetType, "loadAsset")) {
            @compileLog("Tried to generate AssetLoaderInterface for type ", TargetType, "but it's missing func loadAsset");
            unreachable;
        }

        var self = @This(){
            .typeName = core.MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .loadAsset = wrappedFuncs.loadAsset,
            .assetType = assetType,
        };

        return self;
    }
};

pub const AssetLoaderRef = struct {
    target: *anyopaque,
    vtable: *const AssetLoaderInterface,

    pub fn loadAsset(self: *@This(), asset: AssetRef) !void
    {
        try self.vtable.loadAsset(self.target, asset);
    }
};

pub const AssetReferenceSys = struct {
    loaders: std.AutoHashMapUnmanaged(u32, AssetLoaderRef),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) @This()
    {
        return @This() {
            .loaders = .{},
            .allocator = allocator,
        };
    }

    pub fn registerLoader(self: *@This(), loader: anytype) !void
    {
        const vtable = &@field(@TypeOf(loader.*), "LoaderInterfaceVTable");
        try self.loaders.put(self.allocator, vtable.assetType.hash, .{.vtable = vtable, .target = loader});
    }

    pub fn loadRef(self: @This(), asset: AssetRef) !void 
    {
        core.engine_log("loading asset {any}", .{asset});
        try self.loaders.get(asset.assetType.hash).?.loadAsset(asset);
    }
};