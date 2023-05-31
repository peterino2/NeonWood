const std = @import("std");
const vk = @import("vulkan");

const core = @import("../core.zig");
const assets = @import("../assets.zig");
const vk_utils = @import("vk_utils.zig");
const vkinit = @import("vk_init.zig");

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

    const StagedTextureDescription = struct {
        name: core.Name,
        stagingResults: vk_utils.LoadAndStageImage,
        assetRef: assets.AssetRef,
        properties: assets.AssetPropertiesBag,
    };

    gc: *NeonVkContext,
    assetsReady: core.RingQueue(StagedTextureDescription),

    pub fn loadAsset(self: *@This(), assetRef: assets.AssetRef, props: ?assets.AssetPropertiesBag) assets.AssetLoaderError!void {
        // core.engine_log("async loading texture asset {s}", .{assetRef.path});

        // _ = self.gc.create_standard_texture_from_file(assetRef.name, assetRef.path) catch return error.UnableToLoad;
        // self.gc.make_mesh_image_from_texture(assetRef.name, .{ .useBlocky = assetRef.properties.textureUseBlockySampler }) catch return error.UnableToLoad;

        var z = tracy.ZoneN(@src(), "TextureLoader loadAsset");
        const Lambda = struct {
            loader: *TextureLoader,
            assetRef: assets.AssetRef,
            gc: *NeonVkContext,
            properties: assets.AssetPropertiesBag,

            pub fn func(ctx: @This(), job: *core.JobContext) void {
                _ = job;
                var z1 = tracy.ZoneN(@src(), "Loading file from TextureLoader");
                const gc = ctx.gc;
                // I'm like 99% sure theres a memory leak here if this raises an error
                var stagingResults = vk_utils.load_and_stage_image_from_file(gc, ctx.properties.path) catch unreachable;

                tracy.Message(ctx.assetRef.name.utf8);
                tracy.Message(ctx.properties.path);
                var loadedDescription = StagedTextureDescription{
                    .name = ctx.assetRef.name,
                    .stagingResults = stagingResults,
                    .assetRef = ctx.assetRef,
                    .properties = ctx.properties,
                };

                z1.End();
                ctx.loader.assetsReady.pushLocked(loadedDescription) catch unreachable;
            }
        };

        core.dispatchJob(Lambda{
            .loader = self,
            .gc = self.gc,
            .assetRef = assetRef,
            .properties = props.?,
        }) catch return error.UnableToLoad;

        z.End();
    }

    // processing events, some should really be processing events rather than
    pub fn processEvents(self: *@This(), frameNumber: u64) core.RttiDataEventError!void {
        _ = frameNumber;
        const gc = self.gc;

        if (self.assetsReady.count() > 0) {
            self.assetsReady.lock();
            defer self.assetsReady.unlock();
            while (self.assetsReady.popFromUnlocked()) |assetReady| {
                var z1 = tracy.ZoneN(@src(), "Uploading asset loaded by TextureLoader");
                tracy.Message("TextureLoader");
                tracy.Message(assetReady.assetRef.name.utf8);
                tracy.Message(assetReady.properties.path);

                core.engine_log("async texture load complete registry: {s}", .{assetReady.name.utf8});
                var stagingBuffer = assetReady.stagingResults.stagingBuffer;
                var image = assetReady.stagingResults.image;

                vk_utils.submit_copy_from_staging(gc, stagingBuffer, image, assetReady.stagingResults.mipLevel) catch return error.UnknownStatePanic;
                stagingBuffer.deinit(gc.vkAllocator);

                var imageViewCreate = vkinit.imageViewCreateInfo(
                    .r8g8b8a8_srgb,
                    image.image,
                    .{ .color_bit = true },
                    assetReady.stagingResults.mipLevel,
                );
                var imageView = gc.vkd.createImageView(gc.dev, &imageViewCreate, null) catch return error.UnknownStatePanic;
                var newTexture = gc.allocator.create(Texture) catch return error.UnknownStatePanic;

                newTexture.* = Texture{
                    .image = image,
                    .imageView = imageView,
                };
                var textureSet = gc.create_mesh_image_for_texture(newTexture, .{
                    .useBlocky = assetReady.properties.textureUseBlockySampler,
                }) catch unreachable;

                gc.install_texture_into_registry(assetReady.name, newTexture, textureSet) catch return error.UnknownStatePanic;
                z1.End();
            }
        }
    }

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .gc = vk_renderer.gContext,
            //todo: the RttiData init function should have a handleable error
            .assetsReady = core.RingQueue(StagedTextureDescription).init(allocator, 1024) catch unreachable,
        };
    }
};

pub const MeshLoader = struct {
    pub const LoaderInterfaceVTable = assets.AssetLoaderInterface.from(core.MakeName("Mesh"), @This());
    pub const NeonObjectTable = core.RttiData.from(@This());
    gc: *NeonVkContext,

    pub fn loadAsset(self: *@This(), assetRef: assets.AssetRef, propertiesBag: ?assets.AssetPropertiesBag) assets.AssetLoaderError!void {
        core.engine_log("loading mesh asset {s}", .{propertiesBag.?.path});
        _ = self.gc.new_mesh_from_obj(assetRef.name, propertiesBag.?.path) catch return error.UnableToLoad;
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
