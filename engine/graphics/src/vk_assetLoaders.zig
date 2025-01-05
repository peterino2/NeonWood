const std = @import("std");
const vk = @import("vulkan");
const graphics = @import("graphics.zig");

const core = @import("core");
const assets = @import("assets");
const vk_utils = @import("vk_utils.zig");
const vkinit = @import("vk_init.zig");
const vk_cubemap = @import("vk_renderer/vk_cubemap.zig");

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
    pub var LoaderInterfaceVTable: assets.AssetLoaderInterface = assets.AssetLoaderInterface.from("Texture", @This());
    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    const StagedTextureDescription = struct {
        name: core.Name,
        stagingResults: vk_utils.LoadAndStageImage,
        textureListResults: ?[]vk_utils.LoadAndStageImage = null,
        assetRef: assets.AssetRef,
        properties: assets.AssetPropertiesBag,

        pub fn deinit(self: *@This(), gc: *NeonVkContext) void {
            self.stagingResults.deinit(gc.vkAllocator);
            if (self.textureListResults) |results| {
                for (results) |*result| {
                    result.deinit(gc.vkAllocator);
                }
            }
        }
    };

    const RTAssetsReady = struct {
        name: core.Name,
        texture: *Texture,
        textureSet: vk.DescriptorSet,
        textureId: u32,
    };

    gc: *NeonVkContext,
    assetsReady: core.RingQueue(StagedTextureDescription),
    rtAssetsReady: core.RingQueue(RTAssetsReady),
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

            pub fn eFunc(ctx: @This()) !void {
                var z1 = tracy.ZoneN(@src(), "Loading file from TextureLoader");
                const gc = ctx.gc;
                defer {
                    _ = ctx.gc.outstandingJobsCount.fetchSub(1, .seq_cst);
                }

                var loadAndStageResults: vk_utils.LoadAndStageImage = undefined;
                if (!ctx.properties.textureCube) {
                    loadAndStageResults = try vk_utils.load_and_stage_image_from_file(gc, ctx.properties.path);
                    errdefer loadAndStageResults.deinit(gc.vkAllocator);
                } else {
                    loadAndStageResults = try vk_cubemap.stageCubeTexture(ctx.properties.textureList.?);
                    errdefer loadAndStageResults.deinit(gc.vkAllocator);
                }

                var assetRefName = ctx.assetRef.name;

                tracy.Message(assetRefName.utf8());
                tracy.Message(ctx.properties.path);

                core.engine_log("loaded: {s} from: {s}", .{ assetRefName.utf8(), ctx.properties.path });
                var loadedDescription = StagedTextureDescription{
                    .name = ctx.assetRef.name,
                    .stagingResults = loadAndStageResults,
                    .assetRef = ctx.assetRef,
                    .properties = ctx.properties,
                };

                if (ctx.properties.textureList) |textureList| {
                    const tlResults = try ctx.gc.allocator.alloc(vk_utils.LoadAndStageImage, textureList.len);
                    errdefer ctx.gc.allocator.free(tlResults);

                    for (textureList, 0..) |tPath, i| {
                        const rv = vk_utils.load_and_stage_image_from_file(gc, tPath) catch {
                            core.engine_log("unable to load file {s}", .{tPath});
                            return error.FailedToLoad;
                        };
                        errdefer rv.deinit();
                        tlResults[i] = rv;
                    }

                    loadedDescription.textureListResults = tlResults;
                }

                z1.End();

                ctx.loader.assetsReady.pushLocked(loadedDescription) catch unreachable;
            }

            pub fn func(ctx: @This(), _: *core.JobContext) void {
                ctx.eFunc() catch unreachable;
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

    pub fn processRenderThreadEvents(ptr: *anyopaque) void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        self.processEventInner() catch {};
    }

    pub fn createImageFromStagingResult(self: *@This(), name: core.Name, stagingResults: *vk_utils.LoadAndStageImage, properties: assets.AssetPropertiesBag) core.EngineDataEventError!void {
        const gc = self.gc;
        var stagingBuffer = stagingResults.stagingBuffer;
        const image = stagingResults.image;

        if (stagingResults.cubeOffsets != null) {
            vk_cubemap.submitTextureCube(&gc.uploader, stagingResults) catch return error.UnknownStatePanic;
            stagingBuffer.deinit(gc.vkAllocator);

            var ivc = vkinit.imageViewCreateInfo(
                .r8g8b8a8_srgb,
                image.image,
                .{ .color_bit = true },
                stagingResults.mipLevel,
            );
            ivc.view_type = .cube;
            ivc.subresource_range.layer_count = 6;
            const imageView = gc.vkd.createImageView(gc.dev, &ivc, null) catch return error.UnknownStatePanic;
            const newTexture = gc.allocator.create(Texture) catch return error.UnknownStatePanic;
            newTexture.* = Texture{
                .image = image,
                .imageView = imageView,
            };

            const rv = vk_utils.createDescriptorSetForImage(
                gc.dev,
                gc.descriptorPool,
                gc.singleTextureSetLayout,
                imageView,
                gc.cubeSampler,
                false,
            ) catch return error.UnknownStatePanic;

            self.rtAssetsReady.pushLocked(.{
                .name = name,
                .texture = newTexture,
                .textureSet = rv.textureSet,
                .textureId = rv.textureId,
            }) catch return error.UnknownStatePanic;
        } else {
            vk_utils.submit_copy_from_staging(gc, stagingBuffer, image, stagingResults.mipLevel) catch return error.UnknownStatePanic;
            stagingBuffer.deinit(gc.vkAllocator);

            var imageViewCreate = vkinit.imageViewCreateInfo(
                .r8g8b8a8_srgb,
                image.image,
                .{ .color_bit = true },
                stagingResults.mipLevel,
            );
            const imageView = gc.vkd.createImageView(gc.dev, &imageViewCreate, null) catch return error.UnknownStatePanic;
            const newTexture = gc.allocator.create(Texture) catch return error.UnknownStatePanic;

            newTexture.* = Texture{
                .image = image,
                .imageView = imageView,
            };

            const sampler = if (properties.textureUseBlockySampler) gc.blockySampler else gc.linearSampler;
            const rv = vk_utils.createDescriptorSetForImage(
                gc.dev,
                gc.descriptorPool,
                gc.singleTextureSetLayout,
                imageView,
                sampler,
                true,
            ) catch return error.UnknownStatePanic;

            self.rtAssetsReady.pushLocked(.{
                .name = name,
                .texture = newTexture,
                .textureSet = rv.textureSet,
                .textureId = rv.textureId,
            }) catch return error.UnknownStatePanic;
        }
    }

    fn processEventInner(self: *@This()) core.EngineDataEventError!void {
        if (self.assetsReady.count() > 0) {
            self.assetsReady.lock();
            defer self.assetsReady.unlock();
            while (self.assetsReady.popFromUnlocked()) |ar| {
                var assetReady = ar;
                var z1 = tracy.ZoneN(@src(), "Uploading asset loaded by TextureLoader");
                tracy.Message("TextureLoader");
                tracy.Message(assetReady.assetRef.name.utf8());
                tracy.Message(assetReady.properties.path);
                core.engine_log("async texture load complete registry: {s}", .{assetReady.name.utf8()});
                try self.createImageFromStagingResult(assetReady.name, &assetReady.stagingResults, assetReady.properties);

                if (assetReady.textureListResults) |results| {
                    var buf: [256]u8 = undefined;
                    for (results, 0..) |res, i| {
                        var r = res;
                        var arName = assetReady.name;
                        const newName = std.fmt.bufPrint(&buf, "{s}[{d}]", .{ arName.utf8(), i }) catch return core.EngineDataEventError.OutOfMemory;

                        try self.createImageFromStagingResult(core.MakeName(newName), &r, assetReady.properties);
                    }
                    self.gc.allocator.free(results);
                }

                z1.End();
            }
        }
    }

    // processing events, some should really be processing events rather than
    pub fn processEvents(self: *@This(), frameNumber: u64) core.EngineDataEventError!void {
        _ = frameNumber;
        if (self.rtAssetsReady.count() > 0) {
            self.rtAssetsReady.lock();
            defer self.rtAssetsReady.unlock();
            while (self.rtAssetsReady.popFromUnlocked()) |a| {
                self.gc.install_texture_into_registry(a.name, a.texture, a.textureSet, a.textureId) catch return error.UnknownStatePanic;
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
            //todo: the EngineObjectVTable init function should have a handleable error
            .assetsReady = core.RingQueue(StagedTextureDescription).init(allocator, 1024) catch unreachable,
            .rtAssetsReady = core.RingQueue(RTAssetsReady).init(allocator, 1024) catch unreachable,
        };

        try self.gc.renderthread.installListener(self, processRenderThreadEvents);

        return self;
    }

    pub fn destroy(self: *@This(), allocator: std.mem.Allocator) void {
        self.assetsReady.deinit();
        self.rtAssetsReady.deinit();
        allocator.destroy(self);
    }
};

pub const MeshLoader = struct {
    pub var LoaderInterfaceVTable = assets.AssetLoaderInterface.from("Mesh", @This());
    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());
    gc: *NeonVkContext,

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .gc = vk_renderer.gContext,
        };

        return self;
    }

    pub fn loadAsset(self: *@This(), assetRef: assets.AssetRef, propertiesBag: ?assets.AssetPropertiesBag) assets.AssetLoaderError!void {
        _ = self;
        const sourceType = getSourceType(propertiesBag);
        core.engine_log("loading mesh asset {s} [{s}]", .{ propertiesBag.?.path, if (sourceType) |s| @tagName(s) else "default" });
        graphics.loadIndexedMeshForPooling(assetRef.name, .{
            .path = propertiesBag.?.path,
            .sourceType = getSourceType(propertiesBag),
            .skeletonName = if (propertiesBag.?.skeletonName) |skName| core.MakeName(skName) else null,
        }) catch return error.UnableToLoad;
    }

    fn getSourceType(propertiesBag: ?assets.AssetPropertiesBag) ?graphics.MeshSourceType {
        if (propertiesBag) |bag| {
            if (bag.meshType) |meshType| {
                if (std.mem.eql(u8, meshType, "obj")) {
                    return graphics.MeshSourceType.obj;
                }
                if (std.mem.eql(u8, meshType, "gltf")) {
                    return graphics.MeshSourceType.gltf;
                }
            }

            // try to deduce it by file name, if nothing is set.
            const ext = core.getFileExtension(bag.path);
            if (std.mem.eql(u8, ext, ".obj")) {
                return graphics.MeshSourceType.obj;
            }
            if (std.mem.eql(u8, ext, ".gltf")) {
                return graphics.MeshSourceType.gltf;
            }

            if (std.mem.eql(u8, ext, ".glb")) {
                return graphics.MeshSourceType.gltf;
            }
        }

        return null;
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
