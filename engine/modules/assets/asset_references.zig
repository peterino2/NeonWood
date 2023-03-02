const std = @import("std");
const core = @import("../core.zig");
const tracy = core.tracy;

pub const AssetImportReference = struct {
    assetRef: AssetRef,
    properties: AssetPropertiesBag,
};

pub fn MakeImportRef(comptime assetType: []const u8, comptime name: []const u8, comptime path: []const u8) AssetImportReference {
    return .{
        .assetRef = .{
            .assetType = core.MakeName(assetType),
            .name = core.MakeName(name),
        },
        .properties = .{ .path = path },
    };
}

// TODO, this needs to be replaced with some kind of polymorphic data bag I think,
// some kind of transmute is probably in order, maybe allocate 64 bytes of data
// for it.
pub const AssetPropertiesBag = struct {
    path: []const u8 = "None",
    soundVolume: f32 = 1.0,
    soundLooping: bool = false,
    textureUseBlockySampler: bool = true,
};

// newer API contains info about how to load things as well.
// ^- no bad... references should only be name + type
pub const AssetRef = struct {
    name: core.Name,
    assetType: core.Name,
};

// very minimal asset loading library.
pub const AssetLoaderError = error{
    UnableToLoad,
};

pub const AssetLoaderStatus = enum {
    AssetReady, // The asset was loaded and ready to be installed
    LoadFailed, // The asset failed for one reason or another
};

pub const AssetLoaderMessage = struct {
    assetRef: AssetRef,
    status: AssetLoaderStatus,
    message: ?[]u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, assetRef: AssetRef, status: AssetLoaderStatus, maybeMessage: ?[]const u8) !@This() {
        var m: ?[]u8 = null;
        if (maybeMessage) |message| {
            m = try core.dupeString(message);
        }

        return .{ .message = m, .allocator = allocator, .assetRef = assetRef, .status = status };
    }

    pub fn deinit(self: *@This()) void {
        if (self.message) |message| {
            self.allocator.free(message);
        }
    }
};

pub const AssetLoaderContext = struct {
    loaderMessage: core.RingQueue(AssetLoaderMessage),
};

pub const AssetLoaderInterface = struct {
    typeName: core.Name,
    typeSize: usize,
    typeAlign: usize,

    assetType: core.Name,
    loadAsset: *const fn (*anyopaque, AssetRef, ?AssetPropertiesBag) AssetLoaderError!void,

    pub fn from(comptime assetType: core.Name, comptime TargetType: type) @This() {
        const wrappedFuncs = struct {
            pub fn loadAsset(
                pointer: *anyopaque,
                assetRef: AssetRef,
                properties: ?AssetPropertiesBag,
            ) AssetLoaderError!void {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                try ptr.loadAsset(assetRef, properties);
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

    pub fn loadAsset(self: *@This(), asset: AssetRef, propertiesBag: ?AssetPropertiesBag) !void {
        try self.vtable.loadAsset(self.target, asset, propertiesBag);
    }
};

pub const AssetReferenceSys = struct {
    loaders: std.AutoHashMapUnmanaged(u32, AssetLoaderRef),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) @This() {
        return @This(){
            .loaders = .{},
            .allocator = allocator,
        };
    }

    pub fn registerLoader(self: *@This(), loader: anytype) !void {
        const vtable = &@field(@TypeOf(loader.*), "LoaderInterfaceVTable");
        try self.loaders.put(self.allocator, vtable.assetType.hash, .{ .vtable = vtable, .target = loader });
    }

    pub fn loadRef(self: @This(), asset: AssetRef, propertiesBag: ?AssetPropertiesBag) !void {
        var z = tracy.ZoneN(@src(), "AssetReferenceSys LoadRef");
        if (propertiesBag) |props| {
            core.engine_log("loading asset {s} ({s}) [{s}]", .{ asset.name.utf8, asset.assetType.utf8, props.path });
        } else {
            core.engine_log("loading asset {s} ({s})", .{ asset.name.utf8, asset.assetType.utf8 });
        }
        try self.loaders.getPtr(asset.assetType.hash).?.loadAsset(asset, propertiesBag);
        z.End();
    }
};
