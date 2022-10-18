const std = @import("std");
pub const neonwood = @import("modules/neonwood.zig");

const animations = @import("projects/neurophobia/animations.zig");
const dialogue = @import("projects/neurophobia/dialogue.zig");
const papyrusSprite = @import("projects/neurophobia/papyrus.zig");
const collisions = @import("projects/neurophobia/collisions.zig");
const Collision2D = collisions.Collision2D;
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

const GameAssets = [_]assets.AssetRef{
    .{.assetType = core.MakeName("Sound"), .name = core.MakeName("s_audio_pip"), .path = "content/audioPip.wav" },
    .{.assetType = core.MakeName("Texture"), .name = core.MakeName("t_denver"), .path = "content/DenverSheet.png" },
    .{.assetType = core.MakeName("Texture"), .name = core.MakeName("t_salina_big"), .path = "content/Salina_annoyed.png" },
    .{.assetType = core.MakeName("Texture"), .name = core.MakeName("t_denver_big"), .path = "content/Denver_Big.png" },
    .{.assetType = core.MakeName("Mesh"), .name = core.MakeName("m_room"), .path = "content/SCUFFED_Room.obj" },
    .{.assetType = core.MakeName("Mesh"), .name = core.MakeName("m_break_room"), .path = "content/BreakRoomModel.obj" },
};

var gGame: *GameContext = undefined;

fn zigIgFormat(buf: []u8, comptime fmt: []const u8, args: anytype) !void {
    var print = try std.fmt.bufPrint(buf, fmt, args);
    //std.debug.print("{s}", .{print});
    c.igText(print.ptr);
}

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
    collision: Collision2D,

    isRotating: bool = false,
    shouldExit: bool = false,
    fastMove: bool = true,
    panCamera: bool = false,
    showDemo: bool = true,
    panCameraCache: bool = false,
    movementInput: Vectorf = Vectorf.new(0.0, 0.0, 0.0),

    mousePosition: Vector2 = Vector2.zero(),
    mousePositionPanStart: Vector2 = Vector2.zero(),
    cameraRotationStart: core.Quat,
    cameraHorizontalRotation: core.Quat,
    cameraHorizontalRotationMat: core.Mat,
    cameraHorizontalRotationStart: core.Quat,

    denver: core.ObjectHandle = undefined,
    testWindow: bool = false,
    flipped: bool = false,
    animations: std.ArrayListUnmanaged([*c]const u8),
    selectedAnim: [64]bool,
    currentAnim: core.Name = core.MakeName("walkUp"),
    currentAnimCache: core.Name = core.MakeName("None"),
    sensitivity: f64 = 0.005,
    dialogueSys: dialogue.DialogueSystem,

    positionPrintBuffer: [4096]u8 = std.mem.zeroes([4096]u8),
    inDialogue: bool = false,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
            .camera = Camera.init(),
            .animations = .{},
            .gc = graphics.getContext(),
            .selectedAnim = std.mem.zeroes([64]bool),
            .cameraRotationStart = core.zm.quatFromRollPitchYaw(core.radians(30.0), 0.0, 0.0),
            .cameraHorizontalRotation = undefined,
            .cameraHorizontalRotationStart = undefined,
            .cameraHorizontalRotationMat = core.zm.identity(),
            .collision = Collision2D.init(allocator),
            .dialogueSys = dialogue.DialogueSystem.init(allocator, graphics.getContext()),
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

        self.camera.translate(.{ .x = 0.0, .y = 7.14, .z = 18.0 });
        self.camera.updateCamera();

        return self;
    }

    pub fn uiTick(self: *Self, deltaTime: f64) void {
        // c.igShowDemoWindow(&self.showDemo);
        // core.ui_log("uiTick: {d}", .{deltaTime});

        self.dialogueSys.uiTick(deltaTime);
        if (self.papyrus.spriteSheets.get(core.MakeName("t_denver").hash)) |spriteObject| {
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

                if (c.igButton("Play Sound Test", .{ .x = 150, .y = 50 })) {
                    audio.gSoundEngine.fire_test();
                }

                c.igText("Denver sprite stats");

                var posRot = core.gScene.objects.get(self.denver, .posRot).?;
                var position = posRot.position;
                zigIgFormat(self.positionPrintBuffer[0..], "{any}", .{position}) catch unreachable;

                c.igEnd();
            }
        }
    }

    pub fn init_denver(self: *Self) !void {
        var gc = self.gc;

        self.denver = try gc.add_renderobject(.{
            .mesh_name = MakeName("mesh_quad"),
            .material_name = MakeName("mat_mesh"),
            .init_transform = mul(core.zm.scaling(3.0, 3.0, 3.0), core.zm.translation(0.0, 1.6, 2.0)),
        });

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

        try self.papyrus.addSprite(self.denver, MakeName("t_denver"));
        _ = try core.gScene.createSceneObjectWithHandle(self.denver, .{ .transform = core.zm.identity() });
        core.assert(core.gScene.objects.denseIndices.items.len == 1);
        core.assert(core.gScene.objects.denseIndices.items[0].hash() == self.denver.hash());
        try core.gScene.setMobility(self.denver, .moveable);
        core.gScene.setScaleV(self.denver, spriteSheet.getScale());
        var posRot = core.gScene.objects.get(self.denver, .posRot).?;
        posRot.*.position = posRot.position.add(.{ .x = 0, .y = 1.6, .z = 2.0 });
    }

    pub fn init_objects(self: *Self) !void {
        self.camera.translate(.{ .x = 0.0, .y = -0.0, .z = -6.0 });
        self.gc.activateCamera(&self.camera);

        var gc = self.gc;
        _ = try gc.add_renderobject(.{
            .mesh_name = MakeName("m_break_room"),
            .material_name = MakeName("mat_mesh"),
            .init_transform = core.zm.scaling(1, 1, 1),
            //.init_transform = core.zm.scaling(0.8, 0.8, 0.8),
        });

        try self.init_denver();
        try self.collision.loadCollisionFromFile("content/BreakRoomCollision.cg");
        // ====== CODEGEN  =====
        // _ = try self.collision.addLine(.{.x = -1.22,.y = 0.09,.z = -6.04}, .{.x = 1.49,.y = 0.09,.z = -6.04});
        // _ = try self.collision.addLine(.{.x = -1.22,.y = 0.09,.z = -3.14}, .{.x = -1.22,.y = 0.09,.z = 0.06});
        // _ = try self.collision.addLine(.{.x = 1.49,.y = 0.09,.z = -6.04}, .{.x = 1.49,.y = 0.09,.z = 3.56});
        // _ = try self.collision.addLine(.{.x = -1.91,.y = 0.09,.z = 0.06}, .{.x = -1.22,.y = 0.09,.z = 0.06});
        // _ = try self.collision.addLine(.{.x = 3.19,.y = 0.09,.z = 3.56}, .{.x = 3.19,.y = 0.09,.z = 6.86});
        // _ = try self.collision.addLine(.{.x = 0.89,.y = 0.09,.z = 9.16}, .{.x = -5.02,.y = 0.09,.z = 9.16});
        // _ = try self.collision.addLine(.{.x = -2.91,.y = 0.09,.z = 2.36}, .{.x = -2.91,.y = 0.09,.z = 0.56});
        // _ = try self.collision.addLine(.{.x = 1.49,.y = 0.09,.z = 3.56}, .{.x = 3.19,.y = 0.09,.z = 3.56});
        // _ = try self.collision.addLine(.{.x = -4.61,.y = 0.09,.z = 2.36}, .{.x = -2.91,.y = 0.09,.z = 2.36});
        // _ = try self.collision.addLine(.{.x = -5.02,.y = 0.09,.z = 9.16}, .{.x = -5.02,.y = 0.09,.z = 0.66});
        // _ = try self.collision.addLine(.{.x = 3.19,.y = 0.09,.z = 6.86}, .{.x = 0.89,.y = 0.09,.z = 6.86});
        // _ = try self.collision.addLine(.{.x = 0.89,.y = 0.09,.z = 6.86}, .{.x = 0.89,.y = 0.09,.z = 9.16});
        // _ = try self.collision.addLine(.{.x = -4.61,.y = 0.09,.z = 0.66}, .{.x = -4.61,.y = 0.09,.z = 2.36});
        // _ = try self.collision.addLine(.{.x = -5.02,.y = 0.09,.z = 0.66}, .{.x = -4.61,.y = 0.09,.z = 0.66});
        // _ = try self.collision.addLine(.{.x = -1.91,.y = 0.09,.z = -3.14}, .{.x = -1.22,.y = 0.09,.z = -3.14});
        // _ = try self.collision.addLine(.{.x = -1.22,.y = 0.09,.z = -6.04}, .{.x = -2.91,.y = 0.09,.z = -6.04});
        // _ = try self.collision.addLine(.{.x = -2.91,.y = 0.09,.z = -6.04}, .{.x = -2.91,.y = 0.09,.z = -3.64});
        // _ = try self.collision.addLine(.{.x = -2.91,.y = 0.09,.z = 0.56}, .{.x = -1.91,.y = 0.09,.z = 0.56});
        // _ = try self.collision.addLine(.{.x = -1.91,.y = 0.09,.z = 0.56}, .{.x = -1.91,.y = 0.09,.z = 0.06});
        // _ = try self.collision.addLine(.{.x = -2.91,.y = 0.09,.z = -3.64}, .{.x = -1.91,.y = 0.09,.z = -3.64});
        // _ = try self.collision.addLine(.{.x = -1.91,.y = 0.09,.z = -3.64}, .{.x = -1.91,.y = 0.09,.z = -3.14});

        // ====== CODEGEN  =====
        // _ = try self.collision.addLine(.{ .x = -3.16, .y = 0.71, .z = 0.14 }, .{ .x = -3.19, .y = 0.71, .z = 3.45 });
        // _ = try self.collision.addLine(.{ .x = -3.19, .y = 0.71, .z = 3.45 }, .{ .x = 4.87, .y = 0.71, .z = 3.49 });
        // _ = try self.collision.addLine(.{ .x = 4.87, .y = 0.71, .z = 3.49 }, .{ .x = 4.92, .y = 0.71, .z = -0.22 });
        // _ = try self.collision.addLine(.{ .x = -1.66, .y = 0.71, .z = 0.04 }, .{ .x = -3.16, .y = 0.71, .z = 0.14 });
        // _ = try self.collision.addLine(.{ .x = 4.92, .y = 0.71, .z = -0.22 }, .{ .x = 2.67, .y = 0.71, .z = -0.22 });
        // _ = try self.collision.addLine(.{ .x = -1.70, .y = 0.71, .z = -3.98 }, .{ .x = -1.66, .y = 0.71, .z = 0.04 });
        // _ = try self.collision.addLine(.{ .x = 2.53, .y = 0.71, .z = -1.74 }, .{ .x = 0.05, .y = 0.71, .z = -1.61 });
        // _ = try self.collision.addLine(.{ .x = 2.67, .y = 0.71, .z = -0.22 }, .{ .x = 2.53, .y = 0.71, .z = -1.74 });
        // _ = try self.collision.addLine(.{ .x = 0.05, .y = 0.71, .z = -1.61 }, .{ .x = -0.08, .y = 0.71, .z = -3.99 });
        // _ = try self.collision.addLine(.{ .x = -0.08, .y = 0.71, .z = -3.99 }, .{ .x = -1.70, .y = 0.71, .z = -3.98 });
    }

    pub fn prepareGame(self: *Self) !void {
        gGame = self;
        try self.papyrus.prepareSubsystem();
        try self.papyrusImage.prepareSubsystem();
        graphics.registerRendererPlugin(self.papyrus) catch unreachable;
        graphics.registerRendererPlugin(self.papyrusImage) catch unreachable;

        for(GameAssets) |asset|
        {
            try assets.gAssetSys.loadRef(asset);
        }

        try assets.gAssetSys.loadRef(.{
            .name = MakeName("testSound"),
            .assetType = MakeName("Sound"),
            .path = "content/heyheypeople.wav",
        });

        // todo: this needs a nicer interface.
        try graphics.getContext().add_ui_object(.{
            .ptr = self,
            .vtable = &InterfaceUiTable,
        });
        try self.dialogueSys.setup(self.papyrusImage);

        _ = c.glfwSetKeyCallback(self.gc.window, inputCallback);

        try self.init_objects();
    }

    pub fn tick(self: *Self, deltaTime: f64) void {

        // ---- poll camera stuff ----
        c.glfwGetCursorPos(self.gc.window, &self.mousePosition.x, &self.mousePosition.y);

        // was there why isn't this automatic?.. think about it later
        if (self.camera.isDirty()) {
            self.camera.updateCamera();
        }

        self.camera.resolve(self.cameraHorizontalRotationMat);
        self.inDialogue = self.dialogueSys.fadeTime > 0;

        // --------------------------

        var movement = self.movementInput.normalize().fmul(@floatCast(f32, deltaTime));

        var posRot = core.gScene.objects.get(self.denver, .posRot).?;
        const dt = @floatCast(f32, deltaTime);
        const speed = 4.0;
        var moved: bool = false;

        if (!self.inDialogue) {
            if (movement.z > 0) {
                const movementVector = .{ .x = 0, .y = 0, .z = speed * dt };
                self.currentAnim = core.MakeName("walkDown");
                if (!self.checkMovement(posRot.position, movementVector)) {
                    self.flipped = false;
                    moved = true;
                    posRot.*.position = posRot.position.add(movementVector);
                    self.camera.translate(movementVector);
                }
            } else if (movement.z < 0) {
                const movementVector = .{ .x = 0, .y = 0, .z = -speed * dt };
                self.currentAnim = core.MakeName("walkUp");
                if (!self.checkMovement(posRot.position, movementVector)) {
                    moved = true;
                    self.flipped = false;
                    posRot.*.position = posRot.position.add(movementVector);
                    self.camera.translate(movementVector);
                }
            } else if (movement.x < 0) {
                const movementVector = .{ .y = 0, .z = 0, .x = -speed * dt };
                self.currentAnim = core.MakeName("walkRight");
                self.flipped = true;
                if (!self.checkMovement(posRot.position, movementVector)) {
                    moved = true;
                    posRot.*.position = posRot.position.add(movementVector);
                    self.camera.translate(movementVector);
                }
            } else if (movement.x > 0) {
                const movementVector = .{ .y = 0, .z = 0, .x = speed * dt };
                self.currentAnim = core.MakeName("walkRight");
                self.flipped = false;
                if (!self.checkMovement(posRot.position, movementVector)) {
                    moved = true;
                    posRot.*.position = posRot.position.add(movementVector);
                    self.camera.translate(movementVector);
                }
            }
        }

        if (!moved) {
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
        self.dialogueSys.tick(deltaTime);
    }

    // returns false if nothing is stopping us from moving
    pub fn checkMovement(self: @This(), start: core.Vectorf, dir: core.Vectorf) bool {
        return self.collision.lineTrace(start, dir, 0.3);
    }

    pub fn deinit(self: *Self) void {
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

    if (key == c.GLFW_KEY_T and action == c.GLFW_PRESS) {
        core.engine_logs("OpeningDebugMenu");
        gGame.testWindow = !gGame.testWindow;
    }

    if (action == c.GLFW_PRESS) {
        if (key == c.GLFW_KEY_Z) {
            if (!gGame.dialogueSys.speechWindow) {
                gGame.dialogueSys.startDialogue(MakeName("t_denver_big"), "Denver", "Why is my room purple.");
            } else {
                gGame.dialogueSys.hideDialogue();
            }
        }
        if (key == c.GLFW_KEY_UP) {
            gGame.movementInput.z += -1.0;
        }
        if (key == c.GLFW_KEY_DOWN) {
            gGame.movementInput.z += 1.0;
        }
        if (key == c.GLFW_KEY_RIGHT) {
            gGame.movementInput.x += 1.0;
        }
        if (key == c.GLFW_KEY_LEFT) {
            gGame.movementInput.x += -1.0;
        }
    }
    if (action == c.GLFW_RELEASE) {
        if (key == c.GLFW_KEY_UP) {
            gGame.movementInput.z -= -1.0;
        }
        if (key == c.GLFW_KEY_DOWN) {
            gGame.movementInput.z -= 1.0;
        }
        if (key == c.GLFW_KEY_RIGHT) {
            gGame.movementInput.x -= 1.0;
        }
        if (key == c.GLFW_KEY_LEFT) {
            gGame.movementInput.x -= -1.0;
        }
    }
}

pub fn main() anyerror!void {
    graphics.setWindowName("Neurophobia - Rpg Horror Gamejam");
    engine_log("Starting up", .{});

    core.start_module();
    defer core.shutdown_module();

    assets.start_module();
    defer assets.shutdown_module();

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
