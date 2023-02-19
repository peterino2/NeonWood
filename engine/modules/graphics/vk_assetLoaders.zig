const std = @import("std");
const vk = @import("vulkan");

const core = @import("../core.zig");
const assets = @import("../assets.zig");

const tracy = core.tracy;
const materials = @import("materials.zig");
const vk_renderer = @import("vk_renderer.zig");
const mesh = @import("mesh.zig");
const texture = @import("texture.zig");

const NeonVkContext = vk_renderer.NeonVkContext;
const Material = materials.Material;
const Mesh = mesh.Mesh;
const Texture = texture.Texture;

pub const TextureLoader = struct {
    pub const LoaderInterfaceVTable = assets.AssetLoaderInterface.from(core.MakeName("Texture"), @This());
    pub const NeonObjectTable = core.RttiData.from(@This());
    const LoadedTextureDescription = struct {
        imageName: []const u8,
        texture: *Texture,
        textureSet: vk.DescriptorSet,
    };

    gc: *NeonVkContext,
    assetsReady: core.RingQueue(LoadedTextureDescription),

    pub fn loadAsset(self: *@This(), assetRef: assets.AssetRef) assets.AssetLoaderError!void {
        core.engine_log("loading texture asset {s}", .{assetRef.path});

        _ = self.gc.create_standard_texture_from_file(assetRef.name, assetRef.path) catch return error.UnableToLoad;
        self.gc.make_mesh_image_from_texture(assetRef.name, .{ .useBlocky = assetRef.properties.textureUseBlockySampler }) catch return error.UnableToLoad;
    }

    // processing events, some should really be processing events rather than
    pub fn processEvents(self: *@This(), frameNumber: u64) core.RttiDataEventError!void {
        _ = frameNumber;

        if (self.assetsReady.count() > 0) {
            self.assetsReady.lock();
            defer self.assetsReady.unlock();
            while (self.assetsReady.count() > 0) {
                if (self.assetsReady.popFromUnlocked()) |assetReady| {
                    _ = assetReady;
                }
            }
        }
    }

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .gc = vk_renderer.gContext,
            //todo: the RttiData init function should have a handleable error
            .assetsReady = core.RingQueue(LoadedTextureDescription).init(allocator, 4096) catch unreachable,
        };
    }
};

pub const MeshLoader = struct {
    pub const LoaderInterfaceVTable = assets.AssetLoaderInterface.from(core.MakeName("Mesh"), @This());
    pub const NeonObjectTable = core.RttiData.from(@This());
    gc: *NeonVkContext,

    pub fn loadAsset(self: *@This(), assetRef: assets.AssetRef) assets.AssetLoaderError!void {
        core.engine_log("loading mesh asset {s}", .{assetRef.path});
        _ = self.gc.new_mesh_from_obj(assetRef.name, assetRef.path) catch return error.UnableToLoad;
    }

    pub fn tick(self: *@This(), dt: f64) void {
        _ = self;
        _ = dt;
    }
};

pub var gTextureLoader: *TextureLoader = undefined;
pub var gMeshLoader: *MeshLoader = undefined;

pub fn init_loaders() !void {
    var allocator = std.heap.c_allocator;

    gTextureLoader = try core.createObject(TextureLoader, .{
        .responds_to_events = true,
    });

    gMeshLoader = try allocator.create(MeshLoader);
    gMeshLoader.* = .{ .gc = vk_renderer.gContext };

    try assets.gAssetSys.registerLoader(gTextureLoader);
    try assets.gAssetSys.registerLoader(gMeshLoader);
}
