const std = @import("std");
const core = @import("../core.zig");
const tracy = core.tracy;

pub const AssetImportReference = struct {
    assetRef: AssetRef,
    properties: AssetPropertiesBag,
};

// MakeImportRef with defaults.
pub fn MakeImportRef(assetType: []const u8, name: []const u8, path: []const u8) AssetImportReference {
    return .{
        .assetRef = .{
            .assetType = core.MakeName(assetType),
            .name = core.MakeName(name),
        },
        .properties = .{ .path = path },
    };
}

// Advanced version of MakeImportRef, allows user to explicitly construct the properties bag.
pub fn MakeImportRefOptions(assetType: []const u8, name: []const u8, properties: AssetPropertiesBag) AssetImportReference {
    return .{
        .assetRef = .{
            .assetType = core.MakeName(assetType),
            .name = core.MakeName(name),
        },
        .properties = properties,
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

pub const AssetLoaderInterface = struct {
    typeName: core.Name,
    typeSize: usize,
    typeAlign: usize,

    assetType: core.Name,
    loadAsset: *const fn (*anyopaque, AssetRef, ?AssetPropertiesBag) AssetLoaderError!void,
    destroy: *const fn (*anyopaque, std.mem.Allocator) void,
    discardAll: *const fn (*anyopaque) void,

    pub fn from(comptime assetType: core.Name, comptime TargetType: type) @This() {
        const wrappedFuncs = struct {
            pub fn loadAsset(
                pointer: *anyopaque,
                assetRef: AssetRef,
                properties: ?AssetPropertiesBag,
            ) AssetLoaderError!void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                try ptr.loadAsset(assetRef, properties);
            }

            pub fn discardAll(pointer: *anyopaque) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                ptr.discardAll();
            }

            pub fn destroy(
                pointer: *anyopaque,
                allocator: std.mem.Allocator,
            ) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                ptr.destroy(allocator);
            }
        };

        if (!@hasDecl(TargetType, "loadAsset")) {
            @compileLog("Tried to generate AssetLoaderInterface for type ", TargetType, "but it's missing func loadAsset");
            unreachable;
        }

        if (!@hasDecl(TargetType, "destroy")) {
            @compileLog("Tried to generate AssetLoaderInterface for type ", TargetType, "but it's missing func destroy.");
            unreachable;
        }

        var self = @This(){
            .typeName = core.MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .loadAsset = wrappedFuncs.loadAsset,
            .discardAll = wrappedFuncs.discardAll,
            .destroy = wrappedFuncs.destroy,
            .assetType = assetType,
        };

        return self;
    }
};

pub const AssetLoaderRef = struct {
    target: *anyopaque,
    vtable: *const AssetLoaderInterface,
    size: usize,

    pub fn loadAsset(self: *@This(), asset: AssetRef, propertiesBag: ?AssetPropertiesBag) !void {
        try self.vtable.loadAsset(self.target, asset, propertiesBag);
    }

    pub fn discardAll(self: @This()) void {
        self.vtable.discardAll(self.target);
    }

    pub fn destroy(self: *@This(), allocator: std.mem.Allocator) void {
        self.vtable.destroy(self.target, allocator);
    }
};

pub const AssetReferenceSys = struct {
    loaders: std.AutoHashMapUnmanaged(u32, AssetLoaderRef),
    allocator: std.mem.Allocator,
    outstandingAssetJobs: std.atomic.Atomic(i32),

    pub fn init(allocator: std.mem.Allocator) @This() {
        return @This(){
            .loaders = .{},
            .allocator = allocator,
            .outstandingAssetJobs = std.atomic.Atomic(i32).init(0),
        };
    }

    pub fn registerLoader(self: *@This(), loader: anytype) !void {
        const vtable = &@field(@TypeOf(loader.*), "LoaderInterfaceVTable");
        try self.loaders.put(self.allocator, vtable.assetType.handle(), .{
            .vtable = vtable,
            .target = loader,
            .size = @sizeOf(@TypeOf(loader)),
        });
    }

    pub fn loadRef(self: *@This(), asset: AssetRef, propertiesBag: ?AssetPropertiesBag) !void {
        if (core.getEngine().isShuttingDown())
            return;

        _ = self.outstandingAssetJobs.fetchAdd(1, .Acquire);

        var z = tracy.ZoneN(@src(), "AssetReferenceSys LoadRef");
        if (propertiesBag) |props| {
            core.engine_log("loading asset {s} ({s}) [{s}]", .{ asset.name.utf8(), asset.assetType.utf8(), props.path });
        } else {
            core.engine_log("loading asset {s} ({s})", .{ asset.name.utf8(), asset.assetType.utf8() });
        }
        try self.loaders.getPtr(asset.assetType.handle()).?.loadAsset(asset, propertiesBag);
        z.End();
    }

    pub fn deinit(self: *@This()) void {
        var iter = self.loaders.valueIterator();
        while (iter.next()) |i| {
            i.destroy(self.allocator);
        }
    }
};
