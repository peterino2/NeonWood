const std = @import("std");
pub const neonwood = @import("modules/neonwood.zig");

const animations = @import("projects/neurophobia/animations.zig");
const resources = @import("resources");
const vk = @import("vulkan");
const core = neonwood.core;
const graphics = neonwood.graphics;
const assets = neonwood.assets;
const engine_log = core.engine_log;
const c = graphics.c;
const p2a = core.p_to_a;

const gpd = graphics.gpu_pipe_data;
const Vectorf = core.Vectorf;
const Vector2 = core.Vector2;
const Camera = graphics.render_object.Camera;
const RenderObject = graphics.render_objects.RenderObject;
const PixelPos = graphics.PixelPos;
const AssetReference = assets.AssetReference;
const MakeName = core.MakeName;
const mul = core.zm.mul;
const NeonVkPipelineBuilder = graphics.NeonVkPipelineBuilder;

const TextureAssets = [_]AssetReference{
    .{ .name = core.MakeName("t_sprite"), .path = "content/singleSpriteTest.png" },
    .{ .name = core.MakeName("t_denverWalk"), .path = "projects/neurophobia/DenverWalksAll.png" },
};

const MeshAssets = [_]AssetReference{
    .{ .name = core.MakeName("m_monkey"), .path = "content/monkey.obj" },
    .{ .name = core.MakeName("m_room"), .path = "content/SCUFFED_Room.obj" },
};

var gGame: *GameContext = undefined;

// primarily a test file that exists to create a simple application for
// basic engine onboarding
const GameContext = struct {
    const Self = @This();
    pub const NeonObjectTable = core.RttiData.from(Self);
    pub const InterfaceUiTable = core.InterfaceUiData.from(Self);

    allocator: std.mem.Allocator,
    camera: Camera,
    gc: *graphics.NeonVkContext,

    papyrus: *PapyrusSubsystem,

    isRotating: bool = false,
    shouldExit: bool = false,
    fastMove: bool = true,
    panCamera: bool = false,
    showDemo: bool = true,
    panCameraCache: bool = false,
    textureAssets: std.ArrayListUnmanaged(AssetReference) = .{},
    meshAssets: std.ArrayListUnmanaged(AssetReference) = .{},
    movementInput: Vectorf = Vectorf.new(0.0, 0.0, 0.0),

    mousePosition: Vector2 = Vector2.zero(),
    mousePositionPanStart: Vector2 = Vector2.zero(),
    cameraRotationStart: core.Quat,
    cameraHorizontalRotation: core.Quat,
    cameraHorizontalRotationMat: core.Mat,
    cameraHorizontalRotationStart: core.Quat,

    denver: core.ObjectHandle = undefined,
    testSpriteData: SpriteDataGpu = .{ .topLeft = .{ .x = 0, .y = 0 }, .size = .{ .x = 1.0, .y = 1.0 } },
    testWindow: bool = true,
    flipped: bool = false,
    animations: std.ArrayListUnmanaged([*c]const u8),
    selectedAnim: [3]bool,
    currentAnim: core.Name = core.MakeName("walkUp"),
    currentAnimCache: core.Name = core.MakeName("None"),
    sensitivity: f64 = 0.005,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
            .camera = Camera.init(),
            .textureAssets = .{},
            .animations = .{},
            .meshAssets = .{},
            .gc = graphics.getContext(),
            .selectedAnim = .{ false, false, false },
            .cameraRotationStart = core.zm.quatFromRollPitchYaw(core.radians(30.0), 0.0, 0.0),
            .cameraHorizontalRotation = undefined,
            .cameraHorizontalRotationStart = undefined,
            .cameraHorizontalRotationMat = core.zm.identity(),
            // for some reason core.createObject fails here... not sure why.
            //core.createObject(PapyrusSubsystem, .{.can_tick = false}) catch unreachable,
            .papyrus = allocator.create(PapyrusSubsystem) catch unreachable,
        };

        self.papyrus.* = PapyrusSubsystem.init(allocator);
        self.camera.rotation = self.cameraRotationStart;

        core.game_logs("Game starting");

        self.camera.fov = 60.0;
        self.cameraHorizontalRotation = self.cameraRotationStart;
        self.cameraHorizontalRotationStart = self.cameraRotationStart;

        self.camera.translate(.{ .x = 0.0, .y = 7.14, .z = -5.0 });
        self.camera.updateCamera();

        self.textureAssets.appendSlice(self.allocator, &TextureAssets) catch unreachable;
        self.meshAssets.appendSlice(self.allocator, &MeshAssets) catch unreachable;

        return self;
    }

    pub fn uiTick(self: *Self, deltaTime: f64) void {
        _ = self;
        _ = deltaTime;
        // c.igShowDemoWindow(&self.showDemo);
        // core.ui_log("uiTick: {d}", .{deltaTime});
        if (self.papyrus.spriteSheets.get(core.MakeName("t_denverWalk").hash)) |spriteObject| {
            _ = c.igBegin("testWindow", &self.testWindow, 0);
            _ = c.igCheckbox("flip sprite", &self.flipped);
            if (c.igBeginCombo("animation List", self.currentAnim.utf8.ptr, 0)) {
                var iter = spriteObject.animations.iterator();
                var i: usize = 0;
                while (iter.next()) |animation| {
                    const anim: animations.SpriteAnimation = animation.value_ptr.*;
                    const name = anim.name;
                    if (c.igSelectable_Bool(name.utf8.ptr, self.selectedAnim[i], 0, c.ImVec2{ .x = 0, .y = 0 })) {
                        self.currentAnim = name;
                        for (self.selectedAnim) |*flag| {
                            flag.* = false;
                        }
                        self.selectedAnim[i] = true;
                        core.engine_logs("you selected me");
                    }
                    i += 1;
                }
                c.igEndCombo();
            }
            c.igEnd();
        }
    }

    pub fn load_texture(self: *Self, assetRef: AssetReference) !void {
        _ = try self.gc.create_standard_texture_from_file(assetRef.name, assetRef.path);
        try self.gc.make_mesh_image_from_texture(assetRef.name);
    }

    pub fn load_mesh(self: *Self, assetRef: AssetReference) !void {
        _ = try self.gc.new_mesh_from_obj(assetRef.name, assetRef.path);
    }

    pub fn init_objects(self: *Self) !void {
        _ = self;
        var gc = self.gc;
        _ = try gc.add_renderobject(.{
            .mesh_name = MakeName("m_room"),
            .material_name = MakeName("mat_mesh"),
            .init_transform = core.zm.scaling(0.8, 0.8, 0.8)
        });

        self.denver = try gc.add_renderobject(.{
            .mesh_name = MakeName("mesh_quad"),
            .material_name = MakeName("mat_mesh"),
            .init_transform = mul(core.zm.scaling(3.0, 3.0, 3.0), core.zm.translation(0.0, 1.6, 2.0)),
        });

        var ptr = gc.renderObjectSet.get(self.denver, .renderObject).?;

        //x.ptr.setTextureByName(self.gc, MakeName("t_denverWalk"));
        ptr.applyRelativeRotationX(core.radians(-10.0));

        // convert t_denverwalk into an spritesheet with animations
        var spriteSheet = try self.papyrus.addSpriteSheetByName(MakeName("t_denverWalk"));
        try spriteSheet.generateSpriteFrames(self.allocator, .{ .x = 32, .y = 48 });

        // zig fmt: off
        // creating frame references for denver
        //                                                     Animation name              frame start   frame count   FrameRate
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkUp"),    0,            8,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkDown"),  8,            8,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkRight"), 16,           8,            10);

        // zig fmt: on


        ptr.applyTransform(spriteSheet.getXFrameScaling());
        try self.papyrus.addSprite(self.denver, MakeName("t_denverWalk"));
    }

    pub fn prepareGame(self: *Self) !void {
        gGame = self;
        try self.papyrus.prepareSubsystem();
        graphics.registerRendererPlugin(self.papyrus) catch unreachable;

        for (self.textureAssets.items) |asset| {
            try self.load_texture(asset);
        }

        for (self.meshAssets.items) |asset| {
            try self.load_mesh(asset);
        }

        // todo: this needs a nicer interface.
        try graphics.getContext().add_ui_object(.{
            .ptr = self,
            .vtable = &InterfaceUiTable,
        });

        _ = c.glfwSetKeyCallback(self.gc.window, inputCallback);
        try self.init_objects();
        self.camera.translate(.{ .x = 0.0, .y = -0.0, .z = -6.0 });
        self.gc.activateCamera(&self.camera);
    }

    pub fn tick(self: *Self, deltaTime: f64) void {

        // ---- poll camera stuff ----
        c.glfwGetCursorPos(self.gc.window, &self.mousePosition.x, &self.mousePosition.y);

        // was there why isn't this automatic?.. think about it later
        if (self.camera.isDirty()) {
            self.camera.updateCamera();
        }

        self.camera.resolve(self.cameraHorizontalRotationMat);
        // --------------------------

        var movement = self.movementInput.normalize().fmul(@floatCast(f32, deltaTime));
        _ = movement;

        var renderObject: *graphics.RenderObject = self.gc.renderObjectSet.get(self.denver, .renderObject).?;
        const dt = @floatCast(f32, deltaTime);
        const speed = 3.0;
        if( movement.z > 0 )
        {
            renderObject.applyTransform(core.zm.translation(0, 0, -speed * dt));
            self.currentAnim = core.MakeName("walkUp");
            self.flipped =  false;
            self.camera.translate(.{.x = 0, .y = 0, .z = speed * @floatCast(f32, deltaTime)});
        }
        else if( movement.z < 0 )
        {
            renderObject.applyTransform(core.zm.translation(0, 0, speed * dt));
            self.currentAnim = core.MakeName("walkDown");
            self.flipped =  false;
            self.camera.translate(.{.x = 0, .y = 0, .z = -speed * @floatCast(f32, deltaTime)});
        }
        else if( movement.x < 0)
        {
            renderObject.applyTransform(core.zm.translation(speed * dt, 0, 0));
            self.currentAnim = core.MakeName("walkRight");
            self.flipped = false;
            self.camera.translate(.{.y = 0, .z = 0, .x = -speed * @floatCast(f32, deltaTime)});
        }
        else if( movement.x > 0)
        {
            renderObject.applyTransform(core.zm.translation(-speed * dt, 0, 0));
            self.currentAnim = core.MakeName("walkRight");
            self.flipped = true;
            self.camera.translate(.{.y = 0, .z = 0, .x = speed * @floatCast(f32, deltaTime)});
        }
        else
        {
            self.currentAnimCache = core.MakeName("None"); // ... wait...
        }


        if (self.currentAnimCache.hash != self.currentAnim.hash) {
            self.currentAnimCache = self.currentAnim;
            self.papyrus.playSpriteAnimation(self.denver, self.currentAnim, .{}) catch unreachable;
        }

        self.papyrus.setSpriteFlipped(self.denver, self.flipped);
        self.papyrus.tick(deltaTime);
    }

    pub fn deinit(self: *Self) void {
        self.textureAssets.deinit(self.allocator);
        self.meshAssets.deinit(self.allocator);
        self.papyrus.deinit();
    }
};

// gpu data to be sent to sprite shaders.
// texture coordinates are set in sprite_mesh.vert
const SpriteDataGpu = struct {
    topLeft: core.Vector2f, // texture atlas topLeft coordinate
    size: core.Vector2f, // texture atlas size
};

const PapyrusSprite = struct {
    frameIndex: usize = 0,
    flipped: bool = false,

    // oh man.. destroying/unloading stuff is going to be a fucking nightmare.. we'll deal with that
    // far later when we eventually move onto doing a proper asset system.
    // there's a reason why papyrus and the animation stuff are all under game code not engine
    // code
    spriteSheet: *animations.SpriteSheet,
};

// Wait.. i just had a huge breakthrough..
// I can directly access everything vk_renderer.

// This means that I can literally set up the entire sprite pipeline
// without having to formally implement this stuff in the engine itself.

// subsystem that implements a 2d sprite system that allows you to put animated
// 2d sprites onto quads.
const PapyrusSubsystem = struct {

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
    pipeData: gpd.GpuPipeData,
    mappedBuffers: []gpd.GpuMappingData(SpriteDataGpu) = undefined,
    spriteSheets: std.AutoHashMapUnmanaged(u32, *animations.SpriteSheet),

    pub fn init(allocator: std.mem.Allocator) @This() {
        var self = @This(){
            .allocator = allocator,
            .gc = graphics.getContext(),
            .pipeData = undefined,
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
        if(self.spriteObjects.get(objectHandle, .activeAnims)) |instance|
        {
           instance.* = animationInstance;
        }
        else
        {
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
        var spriteDataBuilder = gpd.GpuPipeDataBuilder.init(self.allocator, self.gc);
        try spriteDataBuilder.addBufferBinding(SpriteDataGpu, .storage_buffer, .{ .vertex_bit = true }, .storageBuffer);
        self.pipeData = try spriteDataBuilder.build();

        try self.createSpriteMaterials();
        defer spriteDataBuilder.deinit();

        self.mappedBuffers = try self.pipeData.mapBuffers(self.gc, SpriteDataGpu, 0);
    }

    pub fn addSprite(self: *@This(), objectHandle: core.ObjectHandle, sheetName: core.Name) !void {
        //var newSpriteObject = try self.allocator.create(PapyrusSprite);
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

    pub fn setSpriteFlipped(self: *@This(), objectHandle: core.ObjectHandle, flipped: bool ) void
    {
        if(self.spriteObjects.get(objectHandle, .sprite))|*object|
        {
            object.*.flipped = flipped;
        }
    }

    // Part of the renderer plugin interface
    pub fn onBindObject(self: *@This(), objectHandle: core.ObjectHandle, objectIndex: usize, cmd: vk.CommandBuffer, frameIndex: usize) void {
        _ = objectIndex;

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
            @ptrCast([*]const u32, resources.sprite_mesh_vert),
            resources.default_lit_frag.len,
            @ptrCast([*]const u32, resources.default_lit_frag),
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

    fn handleAnimations(self: *@This(), deltaTime: f64) void 
    {
        for(self.spriteObjects.dense.items(.activeAnims)) |*anim, i| 
        {
            if(anim.playing)
            {
                anim.advance(deltaTime);
                self.spriteObjects.dense.items(.sprite)[i].frameIndex = anim.getCurrentFrame();
            }
        }
    }

    pub fn tick(self: *@This(), deltaTime: f64) void
    {
        self.handleAnimations(deltaTime);
    }

    pub fn preDraw(self: *@This(), frameId: usize) void {
        // 1. update animation data in the PapyrusPerFrameData
        _ = self;
        for (self.spriteObjects.dense.items(.sprite)) |dense, i| {
            const spriteObject: PapyrusSprite = dense;

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

            self.mappedBuffers[frameId].objects[renderIndex].topLeft = topLeft;
            self.mappedBuffers[frameId].objects[renderIndex].size = size;
        }
        // core.graphics_logs("calling papyrus subsystem predraw");
    }
};

pub fn main() anyerror!void {
    graphics.setWindowName("Neurophobia - Rpg Horror Gamejam");
    engine_log("Starting up", .{});
    core.start_module();
    defer core.shutdown_module();
    graphics.start_module();
    defer graphics.shutdown_module();

    // Setup the game
    var gameContext = try core.createObject(GameContext, .{ .can_tick = true });
    try gameContext.prepareGame();

    // run the game
    core.gEngine.run();
}

pub fn inputCallback(
    window: ?*c.GLFWwindow,
    key: c_int,
    scancode: c_int,
    action: c_int,
    mods: c_int,
) callconv(.C) void {
    _ = window;
    _ = key;
    _ = scancode;
    _ = action;
    _ = mods;

    if (key == c.GLFW_KEY_T and action == c.GLFW_PRESS) {
        core.engine_logs("Debug key pressed");
        graphics.getContext().shouldShowDebug = true;
    }

    if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS) {
        core.engine_logs("Escape key pressed, game ends now");
        core.gEngine.exit();
    }

    if (action == c.GLFW_PRESS) {
        if (key == c.GLFW_KEY_R) {
            gGame.isRotating = !gGame.isRotating;
        }
        if (key == c.GLFW_KEY_F) {
            gGame.fastMove = !gGame.fastMove;
        }
        if (key == c.GLFW_KEY_W) {
            gGame.movementInput.z += 1.0;
        }
        if (key == c.GLFW_KEY_S) {
            gGame.movementInput.z += -1.0;
        }
        if (key == c.GLFW_KEY_D) {
            gGame.movementInput.x += -1.0;
        }
        if (key == c.GLFW_KEY_A) {
            gGame.movementInput.x += 1.0;
        }
        if (key == c.GLFW_KEY_Q) {
            gGame.movementInput.y += -1.0;
        }
        if (key == c.GLFW_KEY_E) {
            gGame.movementInput.y += 1.0;
        }
    }
    if (action == c.GLFW_RELEASE) {
        if (key == c.GLFW_KEY_W) {
            gGame.movementInput.z -= 1.0;
        }
        if (key == c.GLFW_KEY_S) {
            gGame.movementInput.z -= -1.0;
        }
        if (key == c.GLFW_KEY_D) {
            gGame.movementInput.x -= -1.0;
        }
        if (key == c.GLFW_KEY_A) {
            gGame.movementInput.x -= 1.0;
        }
        if (key == c.GLFW_KEY_Q) {
            gGame.movementInput.y -= -1.0;
        }
        if (key == c.GLFW_KEY_E) {
            gGame.movementInput.y -= 1.0;
        }
    }
}
