const std = @import("std");
const nw = @import("root").neonwood;
const vk = @import("vulkan");
const graphics = nw.graphics;
const core = nw.core;
const animations = @import("animations.zig");
const resources = @import("resources");
const tracy = core.tracy;

const RenderObject = graphics.render_objects.RenderObject;
const NeonVkImage = graphics.NeonVkImage;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const NeonVkPipelineBuilder = graphics.NeonVkPipelineBuilder;
const MakeName = core.MakeName;
const gpd = graphics.gpu_pipe_data;
const PixelPos = graphics.PixelPos;
const ObjectHandle = core.ObjectHandle;

// gpu data to be sent to sprite shaders.
// texture coordinates are set in sprite_mesh.vert
pub const PapyrusSpriteGpu = struct {
    topLeft: core.Vector2f, // texture atlas topLeft coordinate
    size: core.Vector2f, // texture atlas size
    alpha: f32 = 1.0,
    pad: [12]u8 = std.mem.zeroes([12]u8), // padding so that our struct size is exactly 32 bytes.
    //alpha: core.Vector2f = .{.x = 0, .y = 0},
};

pub const PapyrusSprite = struct {
    frameIndex: usize = 0,
    flipped: bool = false,
    dirty: bool = true,
    alpha: f32 = 1.0,

    // oh man.. destroying/unloading stuff is going to be a fucking nightmare.. we'll deal with that
    // far later when we eventually move onto doing a proper asset system.
    // there's a reason why papyrus and the animation stuff are all under game code not engine
    // code
    spriteSheet: *animations.SpriteSheet,
};

// This means that I can literally set up the entire sprite pipeline
// without having to formally implement this stuff in the engine itself.

// subsystem that implements a 2d sprite system that allows you to put animated
// 2d sprites onto quads.
pub const PapyrusSubsystem = struct {

    // Interfaces and tables
    pub const RendererInterfaceVTable = graphics.RendererInterface.from(@This());
    pub const NeonObjectTable = core.RttiData.from(@This());

    const SpriteObjectSet = core.SparseMultiSet(struct {
        sprite: PapyrusSprite,
        activeAnims: animations.SpriteAnimationInstance = .{},
    });

    //spriteObjects: core.SparseSet(*PapyrusSprite),
    spriteObjects: SpriteObjectSet,
    allocator: std.mem.Allocator,
    gc: *graphics.NeonVkContext,
    pipeData: gpd.GpuPipeData = undefined,
    mappedBuffers: []gpd.GpuMappingData(PapyrusSpriteGpu) = undefined,
    spriteSheets: std.AutoHashMapUnmanaged(u32, *animations.SpriteSheet),

    pub fn init(allocator: std.mem.Allocator) @This() {
        var self = @This(){
            .allocator = allocator,
            .gc = graphics.getContext(),
            //.spriteObjects = core.SparseSet(*PapyrusSprite).init(allocator),
            .spriteObjects = SpriteObjectSet.init(allocator),
            .spriteSheets = .{},
        };

        return self;
    }

    pub fn setSpriteFrame(self: *@This(), objectHandle: core.ObjectHandle, frameIndex: usize, reversed: bool) void {
        var spriteObject = self.spriteObjects.get(objectHandle, .sprite).?;

        spriteObject.*.frameIndex = frameIndex;
        spriteObject.*.reversed = reversed;
    }

    pub fn setSpriteAlpha(self: *@This(), objectHandle: core.ObjectHandle, alpha: f32) void {
        self.spriteObjects.get(objectHandle, .sprite).?.*.alpha = alpha;
    }

    pub fn getAnimInstance(self: *@This(), objectHandle: core.ObjectHandle) ?*animations.SpriteAnimationInstance {
        return self.spriteObjects.get(objectHandle, .activeAnims);
    }

    pub fn playSpriteAnimation(
        self: *@This(),
        objectHandle: core.ObjectHandle,
        animationName: core.Name,
        params: struct {
            reverse: bool = false,
            looping: bool = true,
        },
    ) !void {
        var sprite = self.spriteObjects.get(objectHandle, .sprite).?;
        var animationInstance = sprite.*.spriteSheet.createAnimationInstance(animationName) orelse return error.MissingAnimation;
        animationInstance.reverse = params.reverse;
        animationInstance.looping = params.looping;
        animationInstance.playing = true;
        if (self.spriteObjects.get(objectHandle, .activeAnims)) |instance| {
            instance.* = animationInstance;
        } else {
            return error.UnableToRegisterInstance;
        }
    }

    pub fn addSpriteSheetByName(self: *@This(), baseTextureName: core.Name) !*animations.SpriteSheet {
        var texture = self.gc.textures.get(baseTextureName.hash).?;
        var spriteSheet = try self.allocator.create(animations.SpriteSheet);
        spriteSheet.* = animations.SpriteSheet.init(&texture.image);

        try self.spriteSheets.put(self.allocator, baseTextureName.hash, spriteSheet);

        return spriteSheet;
    }

    fn destroy_spritesheets(self: *@This()) void {
        var iter = self.spriteSheets.iterator();
        while (iter.next()) |i| {
            try i.value_ptr.*.deinit(self);
            self.allocator.destroy(i.value_ptr.*);
        }
    }

    pub fn deinit(self: *@This()) void {
        for (self.mappedBuffers) |*mapped| {
            mapped.unmap(self.gc);
        }
        self.spriteObjects.deinit();
        self.pipeData.deinit(self.allocator, self.gc);
    }

    pub fn prepareSubsystem(self: *@This()) !void {
        var zone = tracy.Zone(@src());
        zone.Name("Papyrus Subsystem init");
        defer zone.End();

        var spriteDataBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
        try spriteDataBuilder.addBufferBinding(PapyrusSpriteGpu, .storage_buffer, .{ .vertex_bit = true }, .storageBuffer);
        self.pipeData = try spriteDataBuilder.build();

        try self.createSpriteMaterials();
        defer spriteDataBuilder.deinit();

        core.graphics_logs("mapping sprite buffers");
        self.mappedBuffers = try self.pipeData.mapBuffers(self.gc, PapyrusSpriteGpu, 0);
    }

    pub fn addSprite(self: *@This(), objectHandle: core.ObjectHandle, sheetName: core.Name) !void {
        //var newSpriteObject = try self.allocator.create(PapyrusSprite);
        var zone = tracy.Zone(@src());
        zone.Name("adding sprite");
        defer zone.End();
        var newSpriteObject = PapyrusSprite{ .frameIndex = 0, .spriteSheet = self.spriteSheets.get(sheetName.hash).? };

        var result = try self.spriteObjects.createWithHandle(
            objectHandle,
            .{
                .sprite = newSpriteObject,
            },
        );

        if (self.gc.renderObjectSet.get(objectHandle, .renderObject)) |renderObject| {
            // set the material to mat_sprite
            renderObject.material = self.gc.materials.get(core.MakeName("mat_sprite").hash).?;

            // assign the texture to the spritesheet and register the spriteObject as using
            // this spritesheet
            renderObject.setTextureByName(self.gc, sheetName);
        }

        _ = result;
    }

    pub fn setSpriteFlipped(self: *@This(), objectHandle: core.ObjectHandle, flipped: bool) void {
        if (self.spriteObjects.get(objectHandle, .sprite)) |*object| {
            object.*.flipped = flipped;
        }
    }

    // Part of the renderer plugin interface
    pub fn onBindObject(self: *@This(), objectHandle: core.ObjectHandle, objectIndex: usize, cmd: vk.CommandBuffer, frameIndex: usize) void {
        _ = objectIndex;
        var x = tracy.ZoneNC(@src(), "papyrus sprite render", 0xDDAAAA);
        defer x.End();

        if (self.spriteObjects.get(objectHandle, .sprite)) |object| {
            var renderObject = self.gc.renderObjectSet.get(objectHandle, .renderObject).?;
            _ = object;
            self.gc.vkd.cmdBindDescriptorSets(
                cmd, // command buffer
                .graphics, // bind point
                renderObject.material.?.layout, // layout
                3, // set id
                1, // binding id
                self.pipeData.getDescriptorSet(frameIndex), // descriptorSet
                0,
                undefined,
            );
            // core.graphics_log("Papyrus: binding object {any}:{any} draw index {d}", .{objectHandle, object, objectIndex });
        }
    }

    pub fn createSpriteMaterials(self: *@This()) !void {
        // use default lit and sprite_mesh.vert
        // this will install several pipelines and materials into the

        core.graphics_logs("creating sprite material");
        var gc: *graphics.NeonVkContext = self.gc;
        var pipelineBuilder = try NeonVkPipelineBuilder.init(
            gc.dev,
            gc.vkd,
            gc.allocator,
            resources.sprite_mesh_vert.len,
            @ptrCast([*]const u32, &resources.sprite_mesh_vert),
            resources.sprite_mesh_frag.len,
            @ptrCast([*]const u32, &resources.sprite_mesh_frag),
        );
        defer pipelineBuilder.deinit();

        try pipelineBuilder.add_mesh_description();
        try pipelineBuilder.add_push_constant();
        try pipelineBuilder.add_layout(gc.globalDescriptorLayout);
        try pipelineBuilder.add_layout(gc.objectDescriptorLayout);
        try pipelineBuilder.add_layout(gc.singleTextureSetLayout);
        try pipelineBuilder.add_layout(self.pipeData.descriptorSetLayout);
        try pipelineBuilder.add_depth_stencil();
        try pipelineBuilder.init_triangle_pipeline(gc.actual_extent);

        var materialName = core.MakeName("mat_sprite");
        var material = try gc.allocator.create(graphics.Material);
        material.* = graphics.Material{
            .materialName = materialName,
            .pipeline = (try pipelineBuilder.build(gc.renderPass)).?,
            .layout = pipelineBuilder.pipelineLayout,
        };

        try gc.add_material(material);
    }

    fn handleAnimations(self: *@This(), deltaTime: f64) void {
        var zone = tracy.Zone(@src());
        zone.Name("papyrus animation");
        defer zone.End();

        for (self.spriteObjects.dense.items(.activeAnims), 0..) |*anim, i| {
            var zanim = tracy.Zone(@src());
            zanim.Name("papyrus animation update anim");
            defer zanim.End();

            if (anim.playing) {
                anim.advance(deltaTime);
                var so = &self.spriteObjects.dense.items(.sprite)[i];
                so.*.frameIndex = anim.getCurrentFrame();
                so.*.dirty = true;
            }
        }
    }

    pub fn tick(self: *@This(), deltaTime: f64) void {
        self.handleAnimations(deltaTime);
    }

    pub fn preDraw(self: *@This(), frameId: usize) void {
        // 1. update animation data in the PapyrusPerFrameData
        for (self.spriteObjects.dense.items(.sprite), 0..) |*dense, i| {
            const spriteObject: *PapyrusSprite = dense;

            if (!spriteObject.dirty)
                continue;

            spriteObject.dirty = false;

            // hacky.. but we can get the true renderer index from the gc
            // by using the sparse index here.
            var objectHandle = self.spriteObjects.denseIndices.items[i];
            var renderIndex = self.gc.renderObjectSet.sparseToDense(objectHandle).?;

            var sheetSize = spriteObject.spriteSheet.getDimensions();
            var frameInfo = spriteObject.spriteSheet.frames.items[spriteObject.frameIndex];
            var topLeft = core.Vector2f{
                .x = @intToFloat(f32, frameInfo.topLeft.x) / @intToFloat(f32, sheetSize.x),
                .y = @intToFloat(f32, frameInfo.topLeft.y) / @intToFloat(f32, sheetSize.y),
            };

            var size = core.Vector2f{
                .x = @intToFloat(f32, frameInfo.size.x) / @intToFloat(f32, sheetSize.x),
                .y = @intToFloat(f32, frameInfo.size.y) / @intToFloat(f32, sheetSize.y),
            };

            if (spriteObject.flipped) {
                topLeft.x += size.x;
                size.x = -size.x;
            }

            var gpuObject = &self.mappedBuffers[frameId].objects[renderIndex];
            //var gpuObject = &self.mappedBuffers[frameId].getObject(renderIndex);

            gpuObject.*.topLeft = topLeft;
            gpuObject.*.size = size;
            gpuObject.*.alpha = spriteObject.alpha;
        }
        // core.graphics_logs("calling papyrus subsystem predraw");
    }
};

pub const PapyrusImageGpu = struct {
    topLeft: core.Vector2f,
    size: core.Vector2f,
    anchorPoint: core.Vector2f = .{ .x = -1.0, .y = -1.0 },
    scale: core.Vector2f = .{ .x = 0, .y = 0 },
    alpha: f32 = 1.0,
    //zLevel: f32 = 0.5,
    pad: [12]u8 = std.mem.zeroes([12]u8),
};

pub const PapyrusImage = struct {
    image: *graphics.Texture,
    textureSet: *vk.DescriptorSet,
    position: core.Vector2f,
    size: core.Vector2f,
    scale: core.Vector2f,
    alpha: f32 = 1.0,
    ordering: f32 = 0.5, // higher is on top
};

// an incredibly simple image rendering subsystem
// All it does is draw QUADS on your SCREEN with a given
// textureset.
pub const PapyrusImageSubsystem = struct {
    pub const RendererInterfaceVTable = graphics.RendererInterface.from(@This());

    const ObjectSet = core.SparseMultiSet(struct { image: PapyrusImage });

    gc: *graphics.NeonVkContext,
    allocator: std.mem.Allocator,
    pipeData: gpd.GpuPipeData = undefined,
    mappedBuffers: []gpd.GpuMappingData(PapyrusImageGpu) = undefined,
    materialName: core.Name = core.MakeName("mat_image"),
    material: *graphics.Material,
    objects: ObjectSet,

    pub fn init(allocator: std.mem.Allocator) @This() {
        comptime {
            if (@sizeOf(PapyrusImageGpu) != 48) {
                @compileError(std.fmt.comptimePrint("Size of PapyrusImageGpu is invalid {d}", .{@sizeOf(PapyrusImageGpu)}));
            }
        }
        var self = @This(){
            .allocator = allocator,
            .gc = graphics.getContext(),
            .objects = ObjectSet.init(allocator),
            .material = undefined,
        };

        return self;
    }

    pub fn setAlpha(self: *@This(), objectHandle: core.ObjectHandle, alpha: f32) void {
        self.objects.get(objectHandle, .image).?.*.alpha = alpha;
    }

    pub fn deinit(self: *@This()) void {
        // self.pipeData.unmapAll(self.mappedBuffers);
        for (self.mappedBuffers) |*mapped| {
            mapped.unmap(self.gc);
        }
        self.pipeData.deinit(self.allocator, self.gc);
        self.objects.deinit();
    }

    pub fn uploadImageData(self: *@This(), frameId: usize) void {
        var gpuObjects = self.mappedBuffers[frameId].objects;
        var extent = self.gc.actual_extent;
        for (self.objects.dense.items(.image), 0..) |image, i| {
            var position = image.position;
            var screenRatio = core.Vector2f{ .x = 1.0, .y = @intToFloat(f32, extent.height) / @intToFloat(f32, extent.width) };
            if (screenRatio.x > screenRatio.y) {
                screenRatio.x = 1 / screenRatio.y;
                screenRatio.y = 1.0;
            }

            var size = image.size;
            var anchor = core.Vector2f{ .x = -1.0, .y = -1.0 };
            var scale = image.scale;

            gpuObjects[i] = PapyrusImageGpu{
                .topLeft = position,
                .size = size.fmul(screenRatio.swizzleYX()),
                .anchorPoint = anchor,
                .scale = scale,
                .alpha = image.alpha,
                //.zLevel = image.ordering,
            };
        }
    }

    pub fn setImageOrdering(self: *@This(), handle: core.ObjectHandle, ordering: f32) void {
        self.objects.get(handle, .image).?.*.ordering = ordering;
    }

    pub fn preDraw(self: *@This(), frameId: usize) void {
        var z1 = tracy.ZoneNC(@src(), "Image Predraw", 0xBBAABB);
        defer z1.End();
        self.uploadImageData(frameId);
    }

    pub fn postDraw(self: *@This(), cmd: vk.CommandBuffer, frameIndex: usize, frameTime: f64) void {
        var z = tracy.ZoneNC(@src(), "Image PostDraw", 0x44AABB);
        defer z.End();

        _ = frameTime;
        var vkd = self.gc.vkd;
        var mesh = self.gc.meshes.get(core.MakeName("mesh_quad").hash).?;
        var offset: vk.DeviceSize = 0;
        vkd.cmdBindPipeline(cmd, .graphics, self.material.pipeline);
        vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 0, 1, self.pipeData.getDescriptorSet(frameIndex), 0, undefined);
        vkd.cmdBindVertexBuffers(cmd, 0, 1, core.p_to_a(&mesh.buffer.buffer), core.p_to_a(&offset));

        for (self.objects.dense.items(.image), 0..) |image, i| {
            var textureSet = image.textureSet;
            vkd.cmdBindDescriptorSets(cmd, .graphics, self.material.layout, 1, 1, core.p_to_a(textureSet), 0, undefined);
            vkd.cmdDraw(cmd, @intCast(u32, mesh.vertices.items.len), 1, 0, @intCast(u32, i));
        }
    }

    pub fn setImagePosition(self: *@This(), objectHandle: ObjectHandle, position: core.Vector2f) void {
        self.objects.get(objectHandle, .image).?.*.position = position;
    }

    pub fn setImageSize(self: *@This(), objectHandle: ObjectHandle, size: core.Vector2f) void {
        self.objects.get(objectHandle, .image).?.*.size = size;
    }

    pub fn setImageScale(self: *@This(), objectHandle: ObjectHandle, scale: core.Vector2f) void {
        self.objects.get(objectHandle, .image).?.*.scale = scale;
    }

    // creates a display image and returns an unmanaged object handle to it.
    pub fn newDisplayImage(self: *@This(), textureName: core.Name, initialPosition: core.Vector2f, initialSize: ?core.Vector2f) ObjectHandle {
        var maybeTex = self.gc.textures.get(textureName.hash);
        core.assertf(maybeTex != null, "unable to get texture.", .{}) catch unreachable;
        var tex = maybeTex.?;

        var initSize: core.Vector2f = undefined;

        if (initialSize) |s|
            initSize = s
        else
            initSize = .{ .x = 1.0, .y = tex.getDimensions().ratio() };

        var initValue = PapyrusImage{
            .position = initialPosition,
            .size = initSize,
            .textureSet = self.gc.textureSets.get(textureName.hash).?,
            .image = self.gc.textures.get(textureName.hash).?,
            .scale = .{ .x = 1.0, .y = 1.0 },
        };

        var imageObject = self.objects.createObject(.{ .image = initValue }) catch unreachable;
        return imageObject;
    }

    // uses default image size
    pub fn setNewImageUseDefaults(self: *@This(), handle: core.ObjectHandle, textureName: core.Name) void {
        var image = self.objects.get(handle, .image).?;

        var maybeTex = self.gc.textures.get(textureName.hash);
        if (maybeTex == null) {
            return;
        }
        var tex = maybeTex.?;

        var initSize = .{ .x = 1.0, .y = tex.getDimensions().ratio() };
        image.*.image = self.gc.textures.get(textureName.hash).?;
        image.*.textureSet = self.gc.textureSets.get(textureName.hash).?;
        image.*.size = initSize;
    }

    pub fn prepareSubsystem(self: *@This()) !void {
        try self.buildGpu();
        try self.createMaterials();
    }

    pub fn buildGpu(self: *@This()) !void {
        var spriteDataBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
        try spriteDataBuilder.addBufferBinding(PapyrusImageGpu, .storage_buffer, .{ .vertex_bit = true }, .storageBuffer);
        self.pipeData = try spriteDataBuilder.build();

        defer spriteDataBuilder.deinit();

        core.graphics_logs("mapping image materials buffers");
        self.mappedBuffers = try self.pipeData.mapBuffers(self.gc, PapyrusImageGpu, 0);
    }

    pub fn createMaterials(self: *@This()) !void {
        core.graphics_logs("creating image material");
        var gc: *graphics.NeonVkContext = self.gc;
        var pipelineBuilder = try NeonVkPipelineBuilder.init(
            gc.dev,
            gc.vkd,
            gc.allocator,
            resources.image_vert.len,
            @ptrCast([*]const u32, &resources.image_vert),
            resources.image_frag.len,
            @ptrCast([*]const u32, &resources.image_frag),
        );
        defer pipelineBuilder.deinit();

        try pipelineBuilder.add_mesh_description();
        try pipelineBuilder.add_layout(self.pipeData.descriptorSetLayout);
        try pipelineBuilder.add_layout(gc.singleTextureSetLayout);
        try pipelineBuilder.add_depth_stencil();
        try pipelineBuilder.init_triangle_pipeline(gc.actual_extent);

        var materialName = self.materialName;
        var material = try gc.allocator.create(graphics.Material);
        material.* = graphics.Material{
            .materialName = materialName,
            .pipeline = (try pipelineBuilder.build(gc.renderPass)).?,
            .layout = pipelineBuilder.pipelineLayout,
        };

        try gc.add_material(material);

        self.material = material;
    }

    pub fn onBindObject(self: *@This(), objectHandle: core.ObjectHandle, objectIndex: usize, cmd: vk.CommandBuffer, frameIndex: usize) void {
        _ = self;
        _ = objectHandle;
        _ = objectIndex;
        _ = cmd;
        _ = frameIndex;
    }
};
