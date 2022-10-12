const std = @import("std");
pub const neonwood = @import("modules/neonwood.zig");

const animations = @import("projects/neurophobia/animations.zig");
const papyrusSprite = @import("projects/neurophobia/papyrus.zig");
const PapyrusSubsystem = papyrusSprite.PapyrusSubsystem;
const PapyrusSpriteGpu = papyrusSprite.PapyrusSpriteGpu;
const PapyrusSprite = papyrusSprite.PapyrusSprite;
const PapyrusImageSubsystem = papyrusSprite.PapyrusImageSubsystem;

const resources = @import("resources");
const vk = @import("vulkan");
const core = neonwood.core;
const graphics = neonwood.graphics;
const assets = neonwood.assets;
const engine_log = core.engine_log;
const audio = neonwood.audio;
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

const TextureAssets = [_]AssetReference{
    .{ .name = core.MakeName("t_sprite"), .path = "content/singleSpriteTest.png" },
    .{ .name = core.MakeName("t_denver"), .path = "content/DenverSheet.png" },
    .{ .name = core.MakeName("t_salina_big"), .path = "content/Salina_annoyed.png" },
};

const MeshAssets = [_]AssetReference{
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
    papyrusImage: *PapyrusImageSubsystem,

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
    testSpriteData: PapyrusSpriteGpu = .{ .topLeft = .{ .x = 0, .y = 0 }, .size = .{ .x = 1.0, .y = 1.0 } },
    testWindow: bool = true,
    flipped: bool = false,
    animations: std.ArrayListUnmanaged([*c]const u8),
    selectedAnim: [64]bool,
    currentAnim: core.Name = core.MakeName("walkUp"),
    currentAnimCache: core.Name = core.MakeName("None"),
    sensitivity: f64 = 0.005,
    displayImage: core.ObjectHandle = .{},
    speechWindow: bool = true,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
            .camera = Camera.init(),
            .textureAssets = .{},
            .animations = .{},
            .meshAssets = .{},
            .gc = graphics.getContext(),
            .selectedAnim = std.mem.zeroes([64]bool),
            .cameraRotationStart = core.zm.quatFromRollPitchYaw(core.radians(30.0), 0.0, 0.0),
            .cameraHorizontalRotation = undefined,
            .cameraHorizontalRotationStart = undefined,
            .cameraHorizontalRotationMat = core.zm.identity(),
            // for some reason core.createObject fails here... not sure why.
            //core.createObject(PapyrusSubsystem, .{.can_tick = false}) catch unreachable,
            .papyrus = allocator.create(PapyrusSubsystem) catch unreachable,
            .papyrusImage = allocator.create(PapyrusImageSubsystem) catch unreachable,
        };

        self.papyrus.* = PapyrusSubsystem.init(allocator);
        self.camera.rotation = self.cameraRotationStart;

        self.papyrusImage.* = PapyrusImageSubsystem.init(allocator);

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
        _ = deltaTime;
        // c.igShowDemoWindow(&self.showDemo);
        // core.ui_log("uiTick: {d}", .{deltaTime});
        if (self.papyrus.spriteSheets.get(core.MakeName("t_denver").hash)) |spriteObject| {
            _ = c.igBegin("Salina", &self.speechWindow, 0);
            _ = c.igText("Hi... Nice to meet you I guess... My name's Salina. \nI am NOT impressed by your actions today");
            _ = c.igEnd();
            if (self.testWindow) {
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
    }

    pub fn load_texture(self: *Self, assetRef: AssetReference) !void {
        _ = try self.gc.create_standard_texture_from_file(assetRef.name, assetRef.path);
        try self.gc.make_mesh_image_from_texture(assetRef.name);
    }

    pub fn load_mesh(self: *Self, assetRef: AssetReference) !void {
        _ = try self.gc.new_mesh_from_obj(assetRef.name, assetRef.path);
    }

    pub fn init_objects(self: *Self) !void {
        var gc = self.gc;
        _ = try gc.add_renderobject(.{ .mesh_name = MakeName("m_room"), .material_name = MakeName("mat_mesh"), .init_transform = core.zm.scaling(0.8, 0.8, 0.8) });

        self.denver = try gc.add_renderobject(.{
            .mesh_name = MakeName("mesh_quad"),
            .material_name = MakeName("mat_mesh"),
            .init_transform = mul(core.zm.scaling(3.0, 3.0, 3.0), core.zm.translation(0.0, 1.6, 2.0)),
        });

        var ptr = gc.renderObjectSet.get(self.denver, .renderObject).?;

        //x.ptr.setTextureByName(self.gc, MakeName("t_denver"));
        ptr.applyRelativeRotationX(core.radians(-10.0));

        // convert t_denver into an spritesheet with animations
        var spriteSheet = try self.papyrus.addSpriteSheetByName(MakeName("t_denver"));
        try spriteSheet.generateSpriteFrames(self.allocator, .{ .x = 32, .y = 48 });

        // zig fmt: off
        // creating frame references for denver
        //                                                     Animation name              frame start   frame count   FrameRate
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkDown"),     0,             8,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkRight"),    8,             8,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkUp"),      16,             8,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("idleDown"),    24,            16,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("idleRight"),   24 + 16 * 1,   16,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("idleUp"),      24 + 16 * 2,   16,            10);
        // zig fmt: on

        ptr.applyTransform(spriteSheet.getXFrameScaling());
        try self.papyrus.addSprite(self.denver, MakeName("t_denver"));

        var i: u32 = 0;
        while (i < 100) : (i += 1) {
            var x = try self.gc.add_renderobject(.{
                .mesh_name = MakeName("mesh_quad"),
                .material_name = MakeName("mat_mesh"),
                .init_transform = mul(core.zm.scaling(3.0, 3.0, 3.0), core.zm.translation(2.5 * @intToFloat(f32, i % 100), 1.6, 3.0 * (@intToFloat(f32, i) / 100))),
            });
            var p = gc.renderObjectSet.get(x, .renderObject).?;
            p.applyTransform(spriteSheet.getXFrameScaling());
            try self.papyrus.addSprite(x, MakeName("t_denver"));
            try self.papyrus.playSpriteAnimation(x, core.MakeName("idleDown"), .{});
        }
    }

    pub fn prepareGame(self: *Self) !void {
        gGame = self;
        try self.papyrus.prepareSubsystem();
        try self.papyrusImage.prepareSubsystem();
        graphics.registerRendererPlugin(self.papyrus) catch unreachable;
        graphics.registerRendererPlugin(self.papyrusImage) catch unreachable;

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

        self.displayImage = self.papyrusImage.newDisplayImage(
            core.MakeName("t_salina_big"),
            .{ .x = 0.2, .y = 0.2 }, // by default it's anchored from the top left
            null,
        );
        audio.gSoundEngine.fire_test();
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

        var renderObject: *graphics.RenderObject = self.gc.renderObjectSet.get(self.denver, .renderObject).?;
        const dt = @floatCast(f32, deltaTime);
        const speed = 3.0;
        if (movement.z > 0) {
            renderObject.applyTransform(core.zm.translation(0, 0, -speed * dt));
            self.currentAnim = core.MakeName("walkUp");
            self.flipped = false;
            self.camera.translate(.{ .x = 0, .y = 0, .z = speed * @floatCast(f32, deltaTime) });
        } else if (movement.z < 0) {
            renderObject.applyTransform(core.zm.translation(0, 0, speed * dt));
            self.currentAnim = core.MakeName("walkDown");
            self.flipped = false;
            self.camera.translate(.{ .x = 0, .y = 0, .z = -speed * @floatCast(f32, deltaTime) });
        } else if (movement.x < 0) {
            renderObject.applyTransform(core.zm.translation(speed * dt, 0, 0));
            self.currentAnim = core.MakeName("walkRight");
            self.flipped = false;
            self.camera.translate(.{ .y = 0, .z = 0, .x = -speed * @floatCast(f32, deltaTime) });
        } else if (movement.x > 0) {
            renderObject.applyTransform(core.zm.translation(-speed * dt, 0, 0));
            self.currentAnim = core.MakeName("walkRight");
            self.flipped = true;
            self.camera.translate(.{ .y = 0, .z = 0, .x = speed * @floatCast(f32, deltaTime) });
        } else {
            if (self.currentAnim.hash == core.MakeName("walkDown").hash)
                self.currentAnim = core.MakeName("idleDown");
            if (self.currentAnim.hash == core.MakeName("walkRight").hash)
                self.currentAnim = core.MakeName("idleRight");
            if (self.currentAnim.hash == core.MakeName("walkUp").hash)
                self.currentAnim = core.MakeName("idleUp");
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
        self.papyrusImage.deinit();
    }
};

pub fn inputCallback(
    window: ?*c.GLFWwindow,
    key: c_int,
    scancode: c_int,
    action: c_int,
    mods: c_int,
) callconv(.C) void {
    _ = window;
    _ = scancode;
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

pub fn main() anyerror!void {
    graphics.setWindowName("Neurophobia - Rpg Horror Gamejam");
    engine_log("Starting up", .{});

    core.start_module();
    defer core.shutdown_module();

    audio.start_module();
    defer audio.shutdown_module();

    graphics.start_module();
    defer graphics.shutdown_module();

    // Setup the game
    var gameContext = try core.createObject(GameContext, .{ .can_tick = true });
    try gameContext.prepareGame();

    // run the game
    core.gEngine.run();
}
