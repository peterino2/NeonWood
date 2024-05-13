const std = @import("std");
const vk = @import("vulkan");

const core = @import("core");
const assets = @import("assets");
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
    pub var LoaderInterfaceVTable: assets.AssetLoaderInterface = assets.AssetLoaderInterface.from(core.MakeName("Texture"), @This());
    pub var NeonObjectTable: core.RttiData = core.RttiData.from(@This());

    const StagedTextureDescription = struct {
        name: core.Name,
        stagingResults: vk_utils.LoadAndStageImage,
        assetRef: assets.AssetRef,
        properties: assets.AssetPropertiesBag,

        pub fn deinit(self: *@This(), gc: *NeonVkContext) void {
            self.stagingResults.deinit(gc.vkAllocator);
        }
    };

    gc: *NeonVkContext,
    assetsReady: core.RingQueue(StagedTextureDescription),
    discarding: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    pub fn loadAsset(self: *@This(), assetRef: assets.AssetRef, props: ?assets.AssetPropertiesBag) assets.AssetLoaderError!void {
        if (self.discarding.load(.seq_cst)) {
            return;
        }

        var z = tracy.ZoneN(@src(), "TextureLoader loadAsset");
        const Lambda = struct {
            loader: *TextureLoader,
            assetRef: assets.AssetRef,
            gc: *NeonVkContext,
            properties: assets.AssetPropertiesBag,

            pub fn func(ctx: @This(), _: *core.JobContext) void {
                var z1 = tracy.ZoneN(@src(), "Loading file from TextureLoader");
                const gc = ctx.gc;
                const stagingResults = vk_utils.load_and_stage_image_from_file(gc, ctx.properties.path) catch unreachable;

                tracy.Message(ctx.assetRef.name.utf8());
                tracy.Message(ctx.properties.path);

                core.engine_log("loaded: {d} from: {d}", .{ ctx.assetRef.name.utf8(), ctx.properties.path });
                const loadedDescription = StagedTextureDescription{
                    .name = ctx.assetRef.name,
                    .stagingResults = stagingResults,
                    .assetRef = ctx.assetRef,
                    .properties = ctx.properties,
                };

                z1.End();
                ctx.loader.assetsReady.pushLocked(loadedDescription) catch unreachable;
                _ = ctx.gc.outstandingJobsCount.fetchSub(1, .seq_cst);
            }
        };

        _ = self.gc.outstandingJobsCount.fetchAdd(1, .seq_cst);
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
                tracy.Message(assetReady.assetRef.name.utf8());
                tracy.Message(assetReady.properties.path);

                core.engine_log("async texture load complete registry: {s}", .{assetReady.name.utf8()});
                var stagingBuffer = assetReady.stagingResults.stagingBuffer;
                const image = assetReady.stagingResults.image;

                vk_utils.submit_copy_from_staging(gc, stagingBuffer, image, assetReady.stagingResults.mipLevel) catch return error.UnknownStatePanic;
                stagingBuffer.deinit(gc.vkAllocator);

                var imageViewCreate = vkinit.imageViewCreateInfo(
                    .r8g8b8a8_srgb,
                    image.image,
                    .{ .color_bit = true },
                    assetReady.stagingResults.mipLevel,
                );
                const imageView = gc.vkd.createImageView(gc.dev, &imageViewCreate, null) catch return error.UnknownStatePanic;
                const newTexture = gc.allocator.create(Texture) catch return error.UnknownStatePanic;

                newTexture.* = Texture{
                    .image = image,
                    .imageView = imageView,
                };
                const textureSet = gc.create_mesh_image_for_texture(newTexture, .{
                    .useBlocky = assetReady.properties.textureUseBlockySampler,
                }) catch unreachable;

                gc.install_texture_into_registry(assetReady.name, newTexture, textureSet) catch return error.UnknownStatePanic;
                z1.End();
            }
        }
    }

    pub fn discardAll(self: *@This()) void {
        self.discarding.store(true, .seq_cst);
        core.graphics_log("discarding {d} outstanding jobs", .{self.assetsReady.count()});

        self.assetsReady.lock();
        defer self.assetsReady.unlock();

        while (self.assetsReady.popFromUnlocked()) |assetReady| {
            var copy = assetReady;
            StagedTextureDescription.deinit(&copy, self.gc);
        }
    }

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .gc = vk_renderer.gContext,
            //todo: the RttiData init function should have a handleable error
            .assetsReady = core.RingQueue(StagedTextureDescription).init(allocator, 1024) catch unreachable,
        };

        return self;
    }

    pub fn destroy(self: *@This(), allocator: std.mem.Allocator) void {
        self.assetsReady.deinit();
        allocator.destroy(self);
    }
};

pub const MeshLoader = struct {
    pub var LoaderInterfaceVTable = assets.AssetLoaderInterface.from(core.MakeName("Mesh"), @This());
    pub var NeonObjectTable: core.RttiData = core.RttiData.from(@This());
    gc: *NeonVkContext,

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .gc = vk_renderer.gContext,
        };

        return self;
    }

    pub fn loadAsset(self: *@This(), assetRef: assets.AssetRef, propertiesBag: ?assets.AssetPropertiesBag) assets.AssetLoaderError!void {
        core.engine_log("loading mesh asset {s}", .{propertiesBag.?.path});
        _ = self.gc.new_mesh_from_obj(assetRef.name, propertiesBag.?.path) catch return error.UnableToLoad;
    }

    pub fn discardAll(self: *@This()) void {
        // totally synchronous, nothing to do for a discard
        _ = self;
    }

    pub fn destroy(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.destroy(self);
    }
};

pub var gTextureLoader: *TextureLoader = undefined;
pub var gMeshLoader: *MeshLoader = undefined;

pub fn init_loaders(allocator: std.mem.Allocator) !void {
    gTextureLoader = try core.createObject(TextureLoader, .{
        .responds_to_events = true,
    });

    gMeshLoader = try allocator.create(MeshLoader);
    gMeshLoader.* = .{ .gc = vk_renderer.gContext };

    try assets.gAssetSys.registerLoader(gTextureLoader);
    try assets.gAssetSys.registerLoader(gMeshLoader);
}

// submit an abort message to TextureLoader and MeshLoader
pub fn discardAll() void {
    gTextureLoader.discardAll();
    gMeshLoader.discardAll();
}
