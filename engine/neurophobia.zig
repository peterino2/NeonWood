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

    papyrus: PapyrusSubsystem,

    isRotating: bool = false,
    shouldExit: bool = false,
    fastMove: bool = true,
    panCamera: bool = false,
    showDemo: bool = true,
    panCameraCache: bool = false,
    textureAssets: std.ArrayListUnmanaged(AssetReference) = .{},
    meshAssets: std.ArrayListUnmanaged(AssetReference) = .{},
    cameraMovement: Vectorf = Vectorf.new(0.0, 0.0, 0.0),

    mousePosition: Vector2 = Vector2.zero(),
    mousePositionPanStart: Vector2 = Vector2.zero(),
    cameraRotationStart: core.Quat,
    cameraHorizontalRotation: core.Quat,
    cameraHorizontalRotationMat: core.Mat,
    cameraHorizontalRotationStart: core.Quat,

    testSpriteHandle: core.ObjectHandle = undefined,
    testSpriteData: SpriteDataGpu = .{ .topLeft = .{ .x = 0, .y = 0 }, .size = .{ .x = 1.0, .y = 1.0 } },
    testWindow: bool = true,
    frameIndex: c_int = 0,
    tickTime: f64 = 0.2,
    frameTime: f64 = 0.1,
    flipped: bool = false,
    animations: std.ArrayListUnmanaged([*c]const u8),
    selectedAnim: [3]bool,
    currentAnim: core.Name = core.MakeName("walkUp"),
    currentAnimCache: core.Name = core.MakeName("None"),
    sensitivity: f64 = 0.005,
    activeAnimInstance: animations.SpriteAnimationInstance=.{},

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
            .camera = Camera.init(),
            .textureAssets = .{},
            .animations = .{},
            .meshAssets = .{},
            .gc = graphics.getContext(),
            .selectedAnim = .{false, false, false},
            .cameraRotationStart = core.zm.quatFromRollPitchYaw(core.radians(60.0), 0.0, 0.0),
            .cameraHorizontalRotation = undefined,
            .cameraHorizontalRotationStart = undefined,
            .cameraHorizontalRotationMat = core.zm.identity(),
            .papyrus = PapyrusSubsystem.init(allocator),
        };
        self.camera.rotation = self.cameraRotationStart;

        core.game_logs("Game starting");

        self.camera.fov = 60.0;
        self.cameraHorizontalRotation = self.cameraRotationStart;
        self.cameraHorizontalRotationStart = self.cameraRotationStart;

        self.camera.translate(.{ .x = 0.0, .y = 10.0, .z = -2.0 });
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
            _ = c.igSliderInt(
                "frameIndex",
                &self.frameIndex,
                0,
                @intCast(c_int, spriteObject.frames.items.len - 1),
                "%d",
                0,
            );
            _ = c.igCheckbox("flip sprite", &self.flipped);
            if(c.igBeginCombo("animation List", self.currentAnim.utf8.ptr, 0))
            {

                var iter = spriteObject.animations.iterator();
                var i: usize = 0;
                while (iter.next()) |animation| 
                {
                    const anim:animations.SpriteAnimation = animation.value_ptr.*;
                    const name = anim.name;
                    if(c.igSelectable_Bool(name.utf8.ptr, self.selectedAnim[i], 0, c.ImVec2{.x = 0, .y = 0}))
                    {
                        self.currentAnim = name;
                        for(self.selectedAnim)|*flag|
                        {
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
        });

        var x = try gc.add_renderobject(.{
            .mesh_name = MakeName("mesh_quad"),
            .material_name = MakeName("mat_mesh"),
            .init_transform = mul(core.zm.scaling(3.0, 3.0, 3.0), core.zm.translation(0.0, 1.5, 0.0)),
        });

        //x.ptr.setTextureByName(self.gc, MakeName("t_denverWalk"));
        x.ptr.applyRelativeRotationX(core.radians(-15.0));

        // convert t_denverwalk into an spritesheet with animations
        var spriteSheet = try self.papyrus.addSpriteSheetByName(MakeName("t_denverWalk"));
        try spriteSheet.generateSpriteFrames(self.allocator, .{ .x = 32, .y = 48 });

        // zig fmt: off
        //                                                     Animation name              frame start   frame count   FrameRate
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkUp"),    0,            8,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkDown"),  8,            8,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkRight"), 16,           8,            10);
        // zig fmt: on
        try self.animations.append(self.allocator, "walkUp");
        try self.animations.append(self.allocator, "walkDown");
        try self.animations.append(self.allocator, "walkRight");

        x.ptr.applyTransform(spriteSheet.getXFrameScaling());
        try self.papyrus.addSprite(x.handle, MakeName("t_denverWalk"));
        self.testSpriteHandle = x.handle;
    }

    fn handleCameraPan(self: *Self, deltaTime: f64) void {
        _ = deltaTime;
        if (self.panCameraCache == false and self.panCamera) {
            core.graphics_logs("Camera button down");
            self.mousePositionPanStart = self.mousePosition;
            self.cameraRotationStart = self.camera.rotation;
            self.cameraHorizontalRotationStart = self.cameraHorizontalRotation;
        }

        if (self.panCamera) {
            var diff = self.mousePosition.sub(self.mousePositionPanStart);

            var horizontalRotation = core.zm.matFromRollPitchYaw(0.0, @floatCast(f32, diff.x * self.sensitivity), 0.0);
            horizontalRotation = mul(
                core.zm.matFromQuat(self.cameraHorizontalRotationStart),
                horizontalRotation,
            );
            self.cameraHorizontalRotationMat = horizontalRotation;
            self.cameraHorizontalRotation = core.zm.quatFromMat(horizontalRotation);

            // calculate the new roatation for the camera
            var offset = core.zm.matFromRollPitchYaw(core.clamp(@floatCast(f32, diff.y * self.sensitivity), core.radians(-90.0), core.radians(90.0)), 0.0, 0.0);
            var final = mul(core.zm.matFromQuat(self.cameraRotationStart), offset);
            self.camera.rotation = core.zm.quatFromMat(final);
        }

        self.panCameraCache = self.panCamera;
    }

    pub fn prepareGame(self: *Self) !void {
        gGame = self;
        try self.papyrus.prepareSubsystem();
        graphics.registerRendererPlugin(&self.papyrus) catch unreachable;

        for (self.textureAssets.items) |asset| {
            try self.load_texture(asset);
        }

        for (self.meshAssets.items) |asset| {
            try self.load_mesh(asset);
        }

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

        if (self.camera.isDirty()) {
            self.camera.updateCamera();
        }

        const state = c.glfwGetMouseButton(self.gc.window, c.GLFW_MOUSE_BUTTON_RIGHT);
        if (state == c.GLFW_PRESS) {
            self.panCamera = true;
        }
        if (state == c.GLFW_RELEASE) {
            self.panCamera = false;
        }

        self.camera.resolve(self.cameraHorizontalRotationMat);
        // --------------------------

        var movement = self.cameraMovement.normalize().fmul(@floatCast(f32, deltaTime));
        if (self.fastMove) {
            movement = movement.fmul(10.0);
        }

        var movement_v = mul(core.zm.matFromQuat(self.cameraHorizontalRotation), movement.toZm());
        _ = movement_v;
        // self.camera.translate(.{ .x = movement_v[0], .y = movement_v[1], .z = movement_v[2] });
        // self.handleCameraPan(deltaTime);

        self.tickTime -= deltaTime;

        if(self.currentAnimCache.hash != self.currentAnim.hash)
        {
            self.currentAnimCache = self.currentAnim;
            self.activeAnimInstance = self.papyrus.createAnimInstance(self.testSpriteHandle, self.currentAnim).?;
            self.activeAnimInstance.looping = true;
        }

        self.activeAnimInstance.advance(deltaTime);
        self.papyrus.setSpriteFrame(self.testSpriteHandle, @intCast(usize, self.activeAnimInstance.getCurrentFrame()), self.flipped);

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
    spriteFrameIndex: usize = 0,
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

    spriteObjects: core.SparseSet(*PapyrusSprite),
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
            .spriteObjects = core.SparseSet(*PapyrusSprite).init(allocator),
            .spriteSheets = .{},
        };

        return self;
    }

    pub fn createAnimInstance(self: *@This(), objectHandle: core.ObjectHandle, animationName: core.Name) ?animations.SpriteAnimationInstance
    {
        var spriteObject = self.spriteObjects.get(objectHandle).?;
        return spriteObject.*.spriteSheet.createAnimationInstance(animationName);
    }

    pub fn setSpriteFrame(self: *@This(), objectHandle: core.ObjectHandle, frameIndex: usize, flipped: bool) void {
        var spriteObject = self.spriteObjects.get(objectHandle).?;

        spriteObject.*.spriteFrameIndex = frameIndex;
        spriteObject.*.flipped = flipped;
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
        for (self.mappedBuffers) |_, i| {
            self.mappedBuffers[i].objects[0].topLeft = .{ .x = 0.0, .y = 0.0 };
            self.mappedBuffers[i].objects[0].size = .{ .x = 0.5, .y = 0.5 };
            self.mappedBuffers[i].objects[1].topLeft = .{ .x = 0.0, .y = 0.0 };
            self.mappedBuffers[i].objects[1].size = .{ .x = 0.5, .y = 0.5 };
        }
    }

    pub fn addSprite(self: *@This(), objectHandle: core.ObjectHandle, sheetName: core.Name) !void {
        var newSpriteObject = try self.allocator.create(PapyrusSprite);
        newSpriteObject.* = .{ .spriteFrameIndex = 0, .spriteSheet = self.spriteSheets.get(sheetName.hash).? };

        var result = try self.spriteObjects.createWithHandle(
            objectHandle,
            newSpriteObject,
        );
        if (self.gc.renderObjectSet.get(objectHandle)) |renderObject| {
            // set the material to mat_sprite
            renderObject.material = self.gc.materials.get(core.MakeName("mat_sprite").hash).?;

            // assign the texture to the spritesheet and register the spriteObject as using
            // this spritesheet
            renderObject.setTextureByName(self.gc, sheetName);
        }

        _ = result;
    }

    // Part of the renderer plugin interface
    pub fn onBindObject(self: *@This(), objectHandle: core.ObjectHandle, objectIndex: usize, cmd: vk.CommandBuffer, frameIndex: usize) void {
        _ = objectIndex;

        if (self.spriteObjects.get(objectHandle)) |object| {
            var renderObject = self.gc.renderObjectSet.get(objectHandle).?;
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

    pub fn preDraw(self: *@This(), frameId: usize) void {
        // 1. update animation data in the PapyrusPerFrameData
        _ = self;
        for (self.spriteObjects.dense.items) |*dense| {
            var spriteObject: PapyrusSprite = dense.value.*;
            // hacky.. but we can get the true renderer index from the gc
            // by using the sparse index here.
            var objectHandle = self.spriteObjects.handleFromSparseIndex(dense.sparseIndex);
            var renderIndex = self.gc.renderObjectSet.sparseToDense(objectHandle).?;

            var sheetSize = spriteObject.spriteSheet.getDimensions();
            var frameInfo = spriteObject.spriteSheet.frames.items[spriteObject.spriteFrameIndex];
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
            gGame.cameraMovement.z += 1.0;
        }
        if (key == c.GLFW_KEY_S) {
            gGame.cameraMovement.z += -1.0;
        }
        if (key == c.GLFW_KEY_D) {
            gGame.cameraMovement.x += -1.0;
        }
        if (key == c.GLFW_KEY_A) {
            gGame.cameraMovement.x += 1.0;
        }
        if (key == c.GLFW_KEY_Q) {
            gGame.cameraMovement.y += -1.0;
        }
        if (key == c.GLFW_KEY_E) {
            gGame.cameraMovement.y += 1.0;
        }
    }
    if (action == c.GLFW_RELEASE) {
        if (key == c.GLFW_KEY_W) {
            gGame.cameraMovement.z -= 1.0;
        }
        if (key == c.GLFW_KEY_S) {
            gGame.cameraMovement.z -= -1.0;
        }
        if (key == c.GLFW_KEY_D) {
            gGame.cameraMovement.x -= -1.0;
        }
        if (key == c.GLFW_KEY_A) {
            gGame.cameraMovement.x -= 1.0;
        }
        if (key == c.GLFW_KEY_Q) {
            gGame.cameraMovement.y -= -1.0;
        }
        if (key == c.GLFW_KEY_E) {
            gGame.cameraMovement.y -= 1.0;
        }
    }
}
