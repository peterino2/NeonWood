const std = @import("std");
pub const neonwood = @import("modules/neonwood.zig");

// this game won't build anymore
// game specific systems
const animations = @import("projects/cognesia/animations.zig");
pub const dialogue = @import("projects/cognesia/dialogue.zig");
const papyrusSprite = @import("projects/cognesia/papyrus.zig");
const collisions = @import("projects/cognesia/collisions.zig");
const interactable = @import("projects/cognesia/interactable.zig");
const halcyon_sys = @import("projects/cognesia/halcyon_sys.zig");
const stage = @import("projects/cognesia/stage.zig");

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
const debugAvailable: bool = false;

const GameAssets = [_]assets.AssetRef{
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_door_open"), .path = "content/door_open.wav", .properties = .{
        .soundVolume = 1.0,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_footstep"), .path = "content/fs0.wav", .properties = .{
        .soundVolume = 1.0,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_fs_reverb"), .path = "content/fs0_reverb.wav", .properties = .{
        .soundVolume = 1.0,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_coffee_made"), .path = "content/coffee.wav", .properties = .{
        .soundVolume = 0.4,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_thump"), .path = "content/thump.wav", .properties = .{
        .soundVolume = 0.4,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_heyheypeople"), .path = "content/heyheypeople.wav", .properties = .{
        .soundVolume = 1.0,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_track1"), .path = "content/track1.wav", .properties = .{
        .soundVolume = 0.5,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_darkness"), .path = "content/dark_mood.wav", .properties = .{
        .soundVolume = 1.0,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_talk"), .path = "content/talkingBlip.wav", .properties = .{
        .soundVolume = 0.05,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_menuBlip"), .path = "content/menuBlip.wav", .properties = .{
        .soundVolume = 0.1,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_flash"), .path = "content/hitHurt.wav", .properties = .{
        .soundVolume = 1.0,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_engineSplash"), .path = "content/engineSplashSound.wav", .properties = .{
        .soundVolume = 1.0,
    } },
    .{ .assetType = core.MakeName("Sound"), .name = core.MakeName("s_truehorror"), .path = "content/truehorror.wav", .properties = .{
        .soundVolume = 0.3,
    } },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_denver"), .path = "content/DenverSheet.png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_scuffed_room"), .path = "content/PackedEnvironment.png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_salina_big"), .path = "content/salina_neutral.png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_denver_big"), .path = "content/Denver_Big.png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_exclamation"), .path = "content/exclamation.png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_vignette"), .path = "content/vignette.png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_vignette2"), .path = "content/vignette2.png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_salina"), .path = "content/salina.png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_page"), .path = "content/paperSprite.png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_blackScreen"), .path = "content/blackScreen.png" },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_engineSplash"), .path = "content/NeonWoodEngineSplash.png", .properties = .{
        .textureUseBlockySampler = false,
    } },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_cognesia"), .path = "content/CognesiaLogo.png", .properties = .{
        .textureUseBlockySampler = false,
    } },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_test_page"), .path = "content/page_test.png", .properties = .{
        .textureUseBlockySampler = false,
    } },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_page1"), .path = "content/Page1.png", .properties = .{ .textureUseBlockySampler = false } },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_page2"), .path = "content/Page2.png", .properties = .{ .textureUseBlockySampler = false } },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_page3"), .path = "content/Page3.png", .properties = .{ .textureUseBlockySampler = false } },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_page4"), .path = "content/Page4.png", .properties = .{ .textureUseBlockySampler = false } },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_page5"), .path = "content/Page5.png", .properties = .{ .textureUseBlockySampler = false } },
    .{ .assetType = core.MakeName("Texture"), .name = core.MakeName("t_page6"), .path = "content/Page6.png", .properties = .{ .textureUseBlockySampler = false } },
    //.{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_room"), .path = "content/SCUFFED_Room.obj" },
    //.{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_room2"), .path = "content/room2.obj" },
    //.{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_room3"), .path = "content/room3.obj" },
    //.{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_room2_blank"), .path = "content/room2_blank.obj" },
    .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_break_room"), .path = "content/BreakRoom.obj" },
    .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_hallway1"), .path = "content/Hallway1.obj" },
    .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_hallway0"), .path = "content/Hallway0.obj" },
    .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_hallwayCursed"), .path = "content/HallwayCursed.obj" },
    .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_roomDenver"), .path = "content/RoomDenver.obj" },
    .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_roomDaisy"), .path = "content/RoomDaisy.obj" },
    .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_roomJeff"), .path = "content/RoomJeff.obj" },
    .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_roomKevin"), .path = "content/RoomKevin.obj" },
    .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_roomCursed"), .path = "content/RoomCursed.obj" },
    .{ .assetType = core.MakeName("Mesh"), .name = core.MakeName("m_roomSalina"), .path = "content/RoomSalina.obj" },
};

pub var gGame: *GameContext = undefined;

fn zigIgFormat(buf: []u8, comptime fmt: []const u8, args: anytype) !void {
    var print = try std.fmt.bufPrint(buf, fmt, args);
    buf[print.len] = 0;
    //std.debug.print("{s}", .{print});
    c.igText(print.ptr);
}

const ScreenEffects = struct {
    vignette: core.ObjectHandle = undefined,
    vignette2: core.ObjectHandle = undefined,
    blackFader: core.ObjectHandle = undefined,
    engineSplash: core.ObjectHandle = undefined,
    page: core.ObjectHandle = undefined,

    pageAnimTime: f32 = 0,
    pageShowRiseTime: f32 = 1.0,
    pageState: enum { rising, fading, holding } = .holding,
    pageVisible: bool = false,

    blackFadeAnimTime: f32 = 0,
    blackFadeEndAnimTime: f32 = 1.2,
    blackFadeIsFading: bool = false,
    positionSelect: usize = 0,
    loadWhenFaded: ?[]const u8 = null,

    holdTime: f32 = 0,
    holdTimeEnd: f32 = 1.0,
    holding: bool = false,

    engineSplashTime: f32 = 0,
    engineSplashPreHoldTime: f32 = 1.5,
    engineSplashRiseTime: f32 = 1.0,
    engineSplashHoldTime: f32 = 1.0,
    engineSplashFadeTime: f32 = 1.0,
    engineSplashPostFadeTime: f32 = 1.0,
    engineSplashState: enum {
        prehold,
        rising,
        holding,
        fading,
        postFade,
        dead,
    } = .dead,
    engineSplashFirstFrame: bool = false,
    splashSound: ?core.Name = core.MakeName("s_engineSplash"),

    endGame: bool = false,
    endGameTime: f32 = 0,
    endGameFade: f32 = 12,

    papyrusImage: *PapyrusImageSubsystem,

    pub fn showPage(self: *@This(), pageName: core.Name) void {
        self.papyrusImage.setNewImageUseDefaults(self.page, pageName);
        self.pageState = .rising;
        self.pageVisible = true;
        self.papyrusImage.setImageScale(self.page, .{ .x = -0.714, .y = 0.714 });
    }

    pub fn hidePage(self: *@This()) void {
        self.pageVisible = false;
        self.pageState = .fading;
    }

    pub fn tickPageAnim(self: *@This(), dt: f32) void {
        switch (self.pageState) {
            .holding => {
                return;
            },
            .rising => {
                self.pageAnimTime += dt;
                var alpha = core.clamp(self.pageAnimTime / self.pageShowRiseTime, 0, 1);
                self.papyrusImage.setAlpha(self.page, alpha);
                if (self.pageAnimTime > self.pageShowRiseTime) {
                    self.pageAnimTime = 0;
                    self.pageState = .holding;
                }
            },
            .fading => {
                self.pageAnimTime += dt;
                var alpha = core.clamp((self.pageShowRiseTime - self.pageAnimTime) / self.pageShowRiseTime, 0, 1);
                self.papyrusImage.setAlpha(self.page, alpha);
                if (self.pageAnimTime > self.pageShowRiseTime) {
                    self.pageAnimTime = 0;
                    self.pageState = .holding;
                }
            },
        }
    }

    pub fn getEngineSplashTotalTime(self: @This()) f32 {
        return self.engineSplashPreHoldTime + self.engineSplashRiseTime + self.engineSplashHoldTime + self.engineSplashPostFadeTime + self.engineSplashFadeTime;
    }

    pub fn init(papyrusImage: *PapyrusImageSubsystem) @This() {
        return .{
            .papyrusImage = papyrusImage,
        };
    }

    pub fn startEngineSplashSequence(self: *@This(), splashImage: core.Name, splashSound: core.Name) void {
        self.engineSplashTime = 0;
        self.engineSplashState = .prehold;
        self.engineSplashFirstFrame = true;
        self.papyrusImage.setNewImageUseDefaults(self.engineSplash, splashImage);
        self.papyrusImage.setImageScale(self.engineSplash, .{ .x = -1, .y = 1 });
        self.papyrusImage.setAlpha(self.engineSplash, 0);
        self.splashSound = splashSound;
    }

    pub fn tickEngineSplashAnim(self: *@This(), deltaTime: f32) void {
        if (self.engineSplashFirstFrame) {
            self.engineSplashFirstFrame = false;
            return;
        }

        switch (self.engineSplashState) {
            .dead => {
                return;
            },
            .prehold => {
                self.engineSplashTime += deltaTime;
                if (self.engineSplashTime > self.engineSplashPreHoldTime) {
                    self.engineSplashTime = 0;
                    self.engineSplashState = .rising;
                    if (self.splashSound) |splashSound| {
                        audio.gSoundEngine.playSound(splashSound) catch unreachable;
                    }
                }
            },
            .rising => {
                self.engineSplashTime += deltaTime;
                var alpha: f32 = core.clamp(self.engineSplashTime / self.engineSplashRiseTime, 0.0, 1.0);
                self.papyrusImage.setAlpha(self.engineSplash, alpha * alpha);
                if (self.engineSplashTime > self.engineSplashRiseTime) {
                    self.engineSplashTime = 0;
                    self.engineSplashState = .holding;
                }
            },
            .holding => {
                self.engineSplashTime += deltaTime;
                if (self.engineSplashTime > self.engineSplashHoldTime) {
                    self.engineSplashTime = 0;
                    self.engineSplashState = .fading;
                }
            },
            .fading => {
                self.engineSplashTime += deltaTime;
                self.papyrusImage.setAlpha(self.engineSplash, core.clamp((self.engineSplashFadeTime - self.engineSplashTime) / self.engineSplashFadeTime, 0.0, 1.0));
                if (self.engineSplashTime > self.engineSplashFadeTime) {
                    self.engineSplashTime = 0;
                    self.engineSplashState = .postFade;
                }
            },
            .postFade => {
                self.engineSplashTime += deltaTime;
                if (self.engineSplashTime > self.engineSplashPostFadeTime) {
                    self.engineSplashTime = 0;
                    self.engineSplashState = .dead;
                }
            },
        }
    }

    pub fn startEndGame(self: *@This()) void {
        self.endGame = true;
        gGame.setMovementEnabled(false);
    }

    pub fn tickEndGame(self: *@This(), dt: f32) void {
        if (self.endGame == true) {
            gGame.setMovementEnabled(false);
            self.endGameTime += dt;
            if (self.endGameTime > 5.0) {
                self.papyrusImage.setAlpha(self.blackFader, (self.endGameTime - 5.0) / (self.endGameFade - 5.0));

                if (self.endGameTime > self.endGameFade) {
                    gGame.halcyon.startDialogue("doomed");
                    self.endGame = false;
                }
            }
        }
    }

    pub fn loadSceneOnFadeout(self: *@This(), scenePath: []const u8, positionSelect: usize) !void {
        self.blackFadeIsFading = true;
        self.blackFadeAnimTime = 0;
        self.positionSelect = positionSelect;
        if (self.loadWhenFaded) |target| {
            self.papyrusImage.allocator.free(target);
        }
        self.loadWhenFaded = try std.fmt.allocPrintZ(self.papyrusImage.allocator, "{s}", .{scenePath});
    }

    pub fn prepare(self: *@This()) void {
        self.blackFader = self.papyrusImage.newDisplayImage(
            core.MakeName("t_blackScreen"),
            .{ .x = 1, .y = 1 },
            null,
        );
        self.papyrusImage.setImageScale(self.blackFader, .{ .x = 2.0, .y = 2.0 });
        self.papyrusImage.setAlpha(self.blackFader, 0);

        self.vignette2 = self.papyrusImage.newDisplayImage(
            core.MakeName("t_vignette2"),
            .{ .x = 1, .y = 1 },
            null,
        );
        self.papyrusImage.setImageScale(self.vignette2, .{ .x = 2.0, .y = 2.0 });

        self.vignette = self.papyrusImage.newDisplayImage(
            core.MakeName("t_vignette"),
            .{ .x = 1, .y = 1 },
            null,
        );
        // self.papyrusImage.setImageUseAbsolute(self.vignette, true);
        self.papyrusImage.setImageScale(self.vignette, .{ .x = 2.0, .y = 2.0 });
        self.papyrusImage.setAlpha(self.vignette, 0.0);

        self.page = self.papyrusImage.newDisplayImage(
            core.MakeName("t_cognesia"),
            .{ .x = 1, .y = 1 },
            null,
        );
        // self.papyrusImage.setImageUseAbsolute(self.vignette, true);
        self.papyrusImage.setImageScale(self.page, .{ .x = 1.0, .y = 1.0 });
        self.papyrusImage.setAlpha(self.page, 0.0);

        self.engineSplash = self.papyrusImage.newDisplayImage(
            core.MakeName("t_engineSplash"),
            .{ .x = 1, .y = 1 },
            null,
        );
        self.papyrusImage.setImageScale(self.engineSplash, .{ .x = -1.0, .y = 1.0 });
        self.papyrusImage.setAlpha(self.engineSplash, 0);
    }

    pub fn setVignetteStrength(self: *@This(), strength: f32) void {
        self.papyrusImage.setAlpha(self.vignette2, 1 - strength);
        self.papyrusImage.setAlpha(self.vignette, strength);
    }

    pub fn tickAnims(self: *@This(), dt: f32) void {
        self.tickEngineSplashAnim(dt);
        self.tickPageAnim(dt);
        self.tickEndGame(dt);

        if (self.holding) {
            if (self.holdTime < self.holdTimeEnd) {
                self.holdTime += dt;
            }
            if (self.holdTime >= self.holdTimeEnd) {
                gGame.loadStageFromFileFinish(self.loadWhenFaded.?, self.positionSelect) catch unreachable;
                self.papyrusImage.allocator.free(self.loadWhenFaded.?);
                self.loadWhenFaded = null;
                self.holding = false;
            }
            return;
        }
        if (self.blackFadeIsFading and self.blackFadeAnimTime < self.blackFadeEndAnimTime) {
            self.blackFadeAnimTime += dt;
            //self.papyrusImage.setAlpha(self.blackFader, self.blackFadeAnimTime / self.blackFadeEndAnimTime);
            const alpha = core.clamp(self.blackFadeAnimTime / self.blackFadeEndAnimTime, 0, 1.0);
            self.papyrusImage.setAlpha(self.blackFader, alpha);
            if (self.blackFadeAnimTime >= self.blackFadeEndAnimTime) {
                if (self.loadWhenFaded != null) {
                    self.blackFadeIsFading = false;
                    self.holding = true;
                    audio.gSoundEngine.playSound(core.MakeName("s_door_open")) catch {};
                    self.holdTime = 0;
                }
            }
            return;
        }

        if ((!self.blackFadeIsFading) and self.blackFadeAnimTime > 0) {
            self.blackFadeAnimTime -= dt;
            const alpha = core.clamp(self.blackFadeAnimTime / self.blackFadeEndAnimTime, 0, 1.0);
            self.papyrusImage.setAlpha(self.blackFader, alpha * alpha);
            return;
        }
    }
};

const GameContext = struct {
    const Self = @This();
    pub var NeonObjectTable: core.RttiData = core.RttiData.from(Self);
    pub const InterfaceUiTable = core.InterfaceUiData.from(Self);

    allocator: std.mem.Allocator,
    camera: Camera,
    gc: *graphics.NeonVkContext,

    papyrus: *PapyrusSubsystem,
    papyrusImage: *PapyrusImageSubsystem,
    halcyon: *halcyon_sys.HalcyonSys,
    collision: Collision2D,

    isRotating: bool = false,
    shouldExit: bool = false,
    fastMove: bool = true,
    panCamera: bool = false,
    showDemo: bool = true,
    panCameraCache: bool = false,
    movementInput: Vectorf = Vectorf.new(0.0, 0.0, 0.0),

    mousePosition: core.Vector2 = core.Vector2.zero(),
    mousePositionPanStart: core.Vector2 = core.Vector2.zero(),
    cameraRotationStart: core.Quat,
    cameraHorizontalRotation: core.Quat,
    cameraHorizontalRotationMat: core.Mat,
    cameraHorizontalRotationStart: core.Quat,
    currentScenePath: core.Name = core.NoName,

    bInHallway: bool = false,

    denver: core.ObjectHandle = undefined,
    exclamation: core.ObjectHandle = undefined,
    testWindow: bool = false,
    flipped: bool = false,
    animations: std.ArrayListUnmanaged([*c]const u8),
    selectedAnim: [64]bool,
    currentAnim: core.Name = core.MakeName("walkUp"),
    currentAnimCache: core.Name = core.MakeName("None"),
    sensitivity: f64 = 0.005,
    dialogueSys: dialogue.DialogueSystem,
    interactions: interactable.InteractionSystem,
    currentInteraction: ?*interactable.InteractableObject = null,
    facingDir: core.Vectorf = .{ .x = 0, .z = -1, .y = 0 },

    positionPrintBuffer: [4096]u8 = std.mem.zeroes([4096]u8),
    inDialogue: bool = false,
    mousePick: core.Vectorf = core.Vectorf.new(0, 0, 0),

    shakeScreen: bool = false,
    shakeScreenTime: f32 = 0,
    shakeScreenTimeEnd: f32 = 0.3,
    shakeScreenIntensity: f32 = 0.2,
    shakeScreenFrequency: f32 = 100.0,
    shakeScreenOffset: core.Vectorf = core.Vectorf.zero(),
    cameraPosition: core.Vectorf = core.Vectorf.zero(),
    screenEffects: ScreenEffects,
    stageSys: stage.StageSys,
    playerVisible: bool = true,

    roomMesh: core.ObjectHandle = undefined,
    roomCollisionFile: []const u8 = "content/BreakRoomCollision.cg",
    showInstructions: bool = false,
    movementEnabled: bool = false,
    playedIntro: bool = true,
    playingCognesiaSplash: bool = false,

    sceneMeshes: std.ArrayListUnmanaged(core.ObjectHandle),
    meshesByName: std.AutoHashMapUnmanaged(u32, core.ObjectHandle) = .{},
    meshVisibilitiesByScene: std.AutoHashMap(u32, std.ArrayList(bool)),
    currentSceneVisibilities: std.ArrayListUnmanaged(bool),

    pub fn setMovementEnabled(self: *@This(), enabled: bool) void {
        self.movementEnabled = enabled;
    }

    pub fn removeSceneObjects(self: *@This()) void {
        // TODO: this function.. yes this function right here is why we need a "proper" ecs
        for (self.sceneMeshes.items) |object| {
            _ = self.gc.renderObjectSet.destroyObject(object);
            _ = self.papyrus.spriteObjects.destroyObject(object);
        }
        self.sceneMeshes.clearRetainingCapacity();
        self.meshesByName.deinit(self.allocator);
        self.meshesByName = .{};
        self.gc.renderObjectsAreDirty = true;
    }

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
            .camera = Camera.init(),
            .animations = .{},
            .gc = graphics.getContext(),
            .selectedAnim = std.mem.zeroes([64]bool),
            .cameraRotationStart = core.zm.quatFromRollPitchYaw(core.radians(30.0), core.radians(0.0), 0.0),
            .cameraHorizontalRotation = undefined,
            .cameraHorizontalRotationStart = undefined,
            .cameraHorizontalRotationMat = core.zm.identity(),
            .collision = Collision2D.init(allocator),
            .dialogueSys = dialogue.DialogueSystem.init(allocator, graphics.getContext()),
            .papyrus = allocator.create(PapyrusSubsystem) catch unreachable,
            .papyrusImage = allocator.create(PapyrusImageSubsystem) catch unreachable,
            .interactions = interactable.InteractionSystem.init(allocator),
            .halcyon = allocator.create(halcyon_sys.HalcyonSys) catch unreachable,
            .screenEffects = undefined,
            .stageSys = stage.StageSys.init(allocator),
            .sceneMeshes = .{},
            .roomCollisionFile = std.fmt.allocPrintZ(allocator, "{s}", .{"content/BreakRoomCollision.cg"}) catch unreachable,
            .meshVisibilitiesByScene = std.AutoHashMap(u32, std.ArrayList(bool)).init(allocator),
            .currentSceneVisibilities = .{},
        };

        self.halcyon.* = halcyon_sys.HalcyonSys.init(allocator);

        self.papyrus.* = PapyrusSubsystem.init(allocator);
        self.camera.rotation = self.cameraRotationStart;

        self.papyrusImage.* = PapyrusImageSubsystem.init(allocator);

        core.game_logs("Game starting");

        self.camera.fov = 60.0;
        self.cameraHorizontalRotation = self.cameraRotationStart;
        self.cameraHorizontalRotationStart = self.cameraRotationStart;

        self.cameraPosition = .{ .x = 0.0, .y = 7.14, .z = 11.0 };
        self.camera.position = self.cameraPosition;
        self.camera.updateCamera();
        return self;
    }

    pub fn uiHelp(self: *@This()) void {
        if (!self.showInstructions) {
            return;
        }

        _ = c.igSetNextWindowPos(.{ .x = @intToFloat(f32, self.gc.actual_extent.width) * 0.01, .y = @intToFloat(f32, self.gc.actual_extent.height) * 0.01 }, 0, .{ .x = 0, .y = 0 });

        _ = c.igSetNextWindowSize(.{ .x = @intToFloat(f32, self.gc.actual_extent.width) * 0.2, .y = @intToFloat(f32, self.gc.actual_extent.height) * 0.15 }, 0);

        _ = c.igBegin(
            "instructions",
            null,
            c.ImGuiWindowFlags_NoResize | c.ImGuiWindowFlags_NoCollapse | c.ImGuiWindowFlags_NoTitleBar | c.ImGuiWindowFlags_NoMove,
        );
        _ = c.igSetWindowFontScale(0.5);
        c.igText("Arrow Keys: Move");
        c.igText("Z: Interact");
        c.igText("=/-: Volume Up Volume Down");
        c.igText("F1: Show/Hide this menu");
        c.igEnd();
    }

    pub fn doShakeScreen(self: *@This()) void {
        self.shakeScreen = true;
        self.shakeScreenTime = 0.0;
    }

    pub fn handleShakeScreen(self: *@This(), dt: f32) void {
        if (!self.shakeScreen)
            return;

        if (self.shakeScreenTime < self.shakeScreenTimeEnd) {
            self.shakeScreenTime += dt;
            const alpha = core.clamp((self.shakeScreenTimeEnd - self.shakeScreenTime) / self.shakeScreenTimeEnd, 0, 1.0);
            const mixedAlpha = alpha;
            self.shakeScreenOffset = core.Vectorf.new(
                std.math.sin(self.shakeScreenTime * self.shakeScreenFrequency) * self.shakeScreenIntensity * mixedAlpha,
                std.math.cos(self.shakeScreenTime * self.shakeScreenFrequency) * self.shakeScreenIntensity * mixedAlpha,
                std.math.cos(std.math.sin(self.shakeScreenTime * self.shakeScreenFrequency)) * 0.1 * self.shakeScreenIntensity,
            );
        } else {
            self.shakeScreen = false;
        }
    }

    pub fn volumeUp(_: @This()) void {
        var volume = audio.gSoundEngine.*.volume + 0.1;
        if (volume <= 1.0) {
            audio.gSoundEngine.setVolume(volume);
            audio.gSoundEngine.playSound(core.MakeName("s_test")) catch {};
        }
    }

    pub fn volumeDown(_: @This()) void {
        var volume = audio.gSoundEngine.*.volume;
        if (volume >= 0.1) {
            audio.gSoundEngine.setVolume(volume - 0.1);
            audio.gSoundEngine.playSound(core.MakeName("s_test")) catch {};
        }
    }

    /// ------------------------- screen fading ------------------
    pub fn fadeOut(self: *@This()) void {
        _ = self;
    }

    pub fn fadeIn(self: *@This()) void {
        _ = self;
    }

    pub fn uiTick(self: *Self, deltaTime: f64) void {
        // c.igShowDemoWindow(&self.showDemo);
        // core.ui_log("uiTick: {d}", .{deltaTime});

        self.dialogueSys.uiTick(deltaTime);

        self.uiHelp();
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

                if (c.igButton("reloadStory", .{ .x = 0, .y = 0 })) {
                    self.halcyon.loadStory("content/story.halc") catch {};
                }

                c.igText("Denver sprite stats");

                c.igText("stageInfo");
                if (c.igButton("Save Stage", .{ .x = 0, .y = 0 })) {
                    self.createAndSaveStageData("content/outStage.json") catch unreachable;
                }
                if (c.igButton("Test room1", .{ .x = 0, .y = 0 })) {
                    self.loadStageFromFile("content/room1.json", 0) catch unreachable;
                }
                if (c.igButton("Test breakroom", .{ .x = 0, .y = 0 })) {
                    self.loadStageFromFile("content/breakRoom.json", 0) catch unreachable;
                }
                //var posRot = core.gScene.objects.get(self.denver, .posRot).?;
                // var position = posRot.position;
                zigIgFormat(self.positionPrintBuffer[0..], "mouse position XY {d:.2} {d:.2}", .{ self.mousePick.x, self.mousePick.z }) catch unreachable;

                for (self.halcyon.tags.items) |tag| {
                    if (c.igButton(tag.ptr, .{ .x = 0, .y = 0 })) {
                        self.halcyon.startDialogue(tag);
                    }
                }

                c.igEnd();
            }
        }
    }

    pub fn create_page_sprite(self: *@This()) !void {
        var spriteSheet = try self.papyrus.addSpriteSheetByName(MakeName("t_page"));
        try spriteSheet.generateSpriteFrames(self.allocator, .{ .x = 16, .y = 16 });

        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("holding"), 0, 1, 1);
    }

    pub fn create_salina_sheet(self: *@This()) !void {
        var spriteSheet = try self.papyrus.addSpriteSheetByName(MakeName("t_salina"));
        try spriteSheet.generateSpriteFrames(self.allocator, .{ .x = 32, .y = 48 });

        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("idleDown"), 0, 1, 1);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("idleUp"), 1, 0, 1);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("idleRight"), 2, 1, 1);
    }

    pub fn create_denver_sheet(self: *Self) !void {
        // convert t_denver into an spritesheet with animations
        var spriteSheet = try self.papyrus.addSpriteSheetByName(MakeName("t_denver"));
        try spriteSheet.generateSpriteFrames(self.allocator, .{ .x = 32, .y = 48 });

        // zig fmt: off
        // creating frame references for denver
        //                                                     Animation name                 Frame start    Frame count   FrameRate
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkDown"),     0,             8,            10);
        try spriteSheet.addSoundEvent(self.allocator, core.MakeName("walkDown"), 2, MakeName("s_footstep"));
        try spriteSheet.addSoundEvent(self.allocator, core.MakeName("walkDown"), 6, MakeName("s_footstep"));
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkRight"),    8,             8,            10);
        try spriteSheet.addSoundEvent(self.allocator, core.MakeName("walkRight"), 2, MakeName("s_footstep"));
        try spriteSheet.addSoundEvent(self.allocator, core.MakeName("walkRight"), 6, MakeName("s_footstep"));
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("walkUp"),      16,             8,            10);
        try spriteSheet.addSoundEvent(self.allocator, core.MakeName("walkUp"), 2, MakeName("s_footstep"));
        try spriteSheet.addSoundEvent(self.allocator, core.MakeName("walkUp"), 6, MakeName("s_footstep"));
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("idleDown"),    24,            16,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("idleRight"),   24 + 16 * 1,   16,            10);
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("idleUp"),      24 + 16 * 2,   16,            10);
        // zig fmt: on
    }

    pub fn create_exclamation_sheet(self: *Self) !void {
        // convert t_denver into an spritesheet with animations
        var spriteSheet = try self.papyrus.addSpriteSheetByName(MakeName("t_exclamation"));
        try spriteSheet.generateSpriteFrames(self.allocator, .{ .x = 32, .y = 32 });

        // zig fmt: off
        // creating frame references for the exclamation mark
        //                                                     Animation name                 Frame start    Frame count   FrameRate
        try spriteSheet.addRangeBasedAnimation(self.allocator, core.MakeName("hold"),     0,             8,            10);
        // zig fmt: on

    }

    pub fn setPlayerVisible(self: *@This(), visible: bool) void {
        self.gc.setObjectVisibility(self.denver, visible);
        self.playerVisible = visible;
    }

    pub fn init_exclamation(self: *Self) !void {
        var gc = self.gc;
        self.exclamation = try gc.add_renderobject(.{
            .mesh_name = MakeName("mesh_quad"),
            .material_name = MakeName("mat_mesh"),
            .init_transform = core.zm.identity(),
        });

        try self.papyrus.addSprite(self.exclamation, MakeName("t_exclamation"));
        try self.papyrus.playSpriteAnimation(self.exclamation, MakeName("hold"), .{ .looping = true });

        _ = try core.gScene.createSceneObjectWithHandle(self.exclamation, .{ .transform = core.zm.identity() });
        try core.gScene.setMobility(self.exclamation, .moveable);

        core.gScene.setScaleV(
            self.exclamation,
            self.papyrus.spriteSheets.get(MakeName("t_exclamation").hash).?.getScale(),
        );

        gc.setObjectVisibility(self.exclamation, false);
        var posRot = core.gScene.objects.get(self.exclamation, .posRot).?;
        posRot.*.scale = posRot.scale.fmul(0.3);
        posRot.*.position = posRot.*.position.add(.{ .x = 0, .y = 1.3, .z = 0 });
    }

    pub fn init_denver(self: *Self) !void {
        var gc = self.gc;

        self.denver = try gc.add_renderobject(.{
            .mesh_name = MakeName("mesh_quad"),
            .material_name = MakeName("mat_mesh"),
            .init_transform = mul(core.zm.scaling(5.0, 5.0, 5.0), core.zm.translation(0.0, 1.6, 2.0)),
        });

        try self.papyrus.addSprite(self.denver, MakeName("t_denver"));

        _ = try core.gScene.createSceneObjectWithHandle(self.denver, .{ .transform = core.zm.identity() });
        try core.gScene.setMobility(self.denver, .moveable);

        core.gScene.setScaleV(
            self.denver,
            self.papyrus.spriteSheets.get(MakeName("t_denver").hash).?.getScale(),
        );

        // Setting up the scene setting
        var posRot = core.gScene.objects.get(self.denver, .posRot).?;
        posRot.*.position = posRot.position.add(.{ .x = 0, .y = 1.9, .z = 2.0 });
    }

    pub fn init_objects(self: *Self) !void {
        self.camera.translate(.{ .x = 0.0, .y = -0.0, .z = -6.0 });
        self.gc.activateCamera(&self.camera);

        self.roomMesh = try self.gc.add_renderobject(.{
            .mesh_name = MakeName("m_break_room"),
            //.mesh_name = MakeName("m_room"),
            .material_name = MakeName("mat_mesh"),
            .init_transform = core.zm.scaling(1, 1, 1),
        });
        var object = self.gc.renderObjectSet.get(self.roomMesh, .renderObject).?;
        object.setTextureByName(self.gc, MakeName("t_scuffed_room"));

        try self.collision.loadCollisionFromFile(self.roomCollisionFile);

        try self.init_denver();
        try self.init_exclamation();
    }

    pub fn loadStageFromFile(self: *@This(), stageDataPath: []const u8, positionSelect: usize) !void {
        try self.screenEffects.loadSceneOnFadeout(stageDataPath, positionSelect);
    }

    pub fn loadStageFromFileFinish(self: *@This(), stageDataPath: []const u8, positionSelect: usize) !void {
        self.setPlayerVisible(true);
        self.setMovementEnabled(true);
        if (self.meshVisibilitiesByScene.get(self.currentScenePath.hash)) |*visibility| {
            for (self.currentSceneVisibilities.items) |v, i| {
                visibility.items[i] = v;
            }
        }
        self.currentSceneVisibilities.clearRetainingCapacity();
        self.removeSceneObjects();

        var arena = std.heap.ArenaAllocator.init(self.allocator);
        var arenaAlloc = arena.allocator();
        var stageData = stage.StageData.init(arenaAlloc);
        try stageData.loadFromFile(stageDataPath);
        try stageData.saveToDisk("sampleOutput.json");
        self.allocator.free(self.roomCollisionFile);

        self.roomCollisionFile = try std.fmt.allocPrintZ(self.allocator, "{s}", .{stageData.data.mainStageMesh.collisionFile});
        self.collision.clearCollisions();
        try self.collision.loadCollisionFromFile(stageData.data.mainStageMesh.collisionFile);
        self.interactions.disableAll();
        self.gc.setRenderObjectMesh(self.roomMesh, stageData.data.mainStageMesh.mesh);
        self.gc.setRenderObjectTexture(self.roomMesh, stageData.data.mainStageMesh.texture);

        var pos: usize = positionSelect;

        if (pos >= stageData.data.startingPositions.items.len) {
            core.engine_err("tried to start room in position {d} but it's not available", .{pos});
            pos = 0;
        }
        var positionInfo = stageData.data.startingPositions.items[pos];
        var startingPos = positionInfo.position;
        var startingAnim = positionInfo.anim;
        self.currentAnim = startingAnim;
        self.flipped = positionInfo.flipped;

        var denverPosition = core.gScene.getPosition(self.denver);
        core.gScene.setPosition(self.denver, startingPos);
        self.cameraPosition = (self.cameraPosition.sub(denverPosition)).add(startingPos);

        self.papyrus.playSpriteAnimation(self.denver, startingAnim, .{}) catch {};
        self.papyrus.setSpriteFlipped(self.denver, positionInfo.flipped);

        if (positionInfo.startingDialogue) |startingDialogue| {
            self.halcyon.startDialogue(startingDialogue);
        }

        for (stageData.data.interactables.items) |i| {
            _ = try self.interactions.addTalkable(core.Name.fromUtf8(i.tag), i.tag, i.position, i.radius);
        }

        for (stageData.data.extraMeshes.items) |i| {
            if (i.hasSprite) {
                var spriteSheet = self.papyrus.spriteSheets.get(i.spriteName.hash).?;
                var newObject = try self.gc.add_renderobject(.{
                    .mesh_name = core.MakeName("mesh_quad"),
                    .material_name = core.MakeName("mat_mesh"),
                    .init_transform = core.zm.mul(core.zm.scalingV(spriteSheet.getScale().vmul(i.scale).toZm()), core.zm.translationV(i.position.toZm())),
                });

                try self.papyrus.addSprite(newObject, i.spriteName);
                try self.papyrus.playSpriteAnimation(newObject, i.startingAnim, .{ .looping = false });

                try self.sceneMeshes.append(self.allocator, newObject);
            }
        }

        var pathName = core.Name.fromUtf8(stageDataPath);
        self.currentScenePath = pathName;
        if (self.meshVisibilitiesByScene.get(pathName.hash)) |*visibilities| {
            for (self.sceneMeshes.items) |sceneMesh, i| {
                self.gc.setObjectVisibility(sceneMesh, visibilities.*.items[i]);
                try self.currentSceneVisibilities.append(self.allocator, visibilities.*.items[i]);
            }
        } else {
            var visibilities: std.ArrayList(bool) = std.ArrayList(bool).init(self.allocator);
            for (self.sceneMeshes.items) |_| {
                try self.currentSceneVisibilities.append(self.allocator, true);
                try visibilities.append(true);
            }
            try self.meshVisibilitiesByScene.put(pathName.hash, visibilities);
        }

        core.engine_log("extra meshes in scene: {d}", .{self.currentSceneVisibilities.items.len});
        core.assert(self.currentSceneVisibilities.items.len == self.sceneMeshes.items.len);
    }

    pub fn createAndSaveStageData(self: *@This(), stageDataPath: []const u8) !void {
        var destructorList = std.ArrayList(std.ArrayList(u8)).init(self.allocator);

        self.stageSys.currentStage.data.extraMeshes.clearRetainingCapacity();
        self.stageSys.currentStage.data.interactables.clearRetainingCapacity();
        defer {
            for (destructorList.items) |x|
                x.deinit();
            destructorList.deinit();
        }

        for (self.interactions.interactables.denseItems(.object)) |*i| {
            var x = i.serialize(self.allocator);
            var pos = i.position;

            var newInteractable = stage.Interactable{
                .position = pos,
                .tag = x.items,
                .radius = i.radius,
            };
            try self.stageSys.currentStage.data.interactables.append(self.allocator, newInteractable);
        }

        var meshObject = self.gc.renderObjectSet.get(self.roomMesh, .renderObject).?;
        self.stageSys.currentStage.data.startingPosition = core.gScene.getPosition(self.denver);
        self.stageSys.currentStage.data.mainStageMesh = .{};
        self.stageSys.currentStage.data.mainStageMesh.mesh = meshObject.*.meshName;
        self.stageSys.currentStage.data.mainStageMesh.position = meshObject.*.position;
        self.stageSys.currentStage.data.mainStageMesh.rotation = meshObject.*.rotation;
        self.stageSys.currentStage.data.mainStageMesh.scale = meshObject.*.scale;
        self.stageSys.currentStage.data.mainStageMesh.texture = meshObject.*.textureName;
        self.stageSys.currentStage.data.mainStageMesh.hasCollisions = true;
        self.stageSys.currentStage.data.mainStageMesh.collisionFile = self.roomCollisionFile;

        for (self.gc.renderObjectSet.denseItems(.renderObject)) |object, i| {
            var handle = self.gc.renderObjectSet.denseIndices.items[i];
            if (handle.hash() == self.denver.hash())
                continue;

            if (handle.hash() == self.roomMesh.hash())
                continue;

            if (handle.hash() == self.exclamation.hash())
                continue;

            var stageMesh = stage.Mesh{
                .position = object.position,
                .rotation = object.rotation,
                .scale = object.scale,
                .texture = object.textureName,
            };
            try self.stageSys.currentStage.data.extraMeshes.append(self.allocator, stageMesh);
        }

        try self.stageSys.currentStage.saveToDisk(stageDataPath);
    }

    pub fn prepareGame(self: *Self) !void {
        gGame = self;
        try self.papyrus.prepareSubsystem();
        try self.papyrusImage.prepareSubsystem();
        graphics.registerRendererPlugin(self.papyrus) catch unreachable;
        graphics.registerRendererPlugin(self.papyrusImage) catch unreachable;
        interactable.dialogueSys = &self.dialogueSys;
        interactable.halcyonSys = self.halcyon;
        self.screenEffects = ScreenEffects.init(self.papyrusImage);

        for (GameAssets) |asset| {
            try assets.gAssetSys.loadRef(asset);
        }

        self.screenEffects.prepare();
        try self.create_denver_sheet();
        try self.create_salina_sheet();
        try self.create_page_sprite();
        try self.create_exclamation_sheet();

        // todo: this needs a nicer interface.
        try graphics.getContext().add_ui_object(.{
            .ptr = self,
            .vtable = &InterfaceUiTable,
        });
        try self.dialogueSys.setup(self.papyrusImage);
        try self.halcyon.prepare(&self.dialogueSys);

        _ = c.glfwSetKeyCallback(self.gc.window, inputCallback);

        try self.init_objects();
        self.setPlayerVisible(false);

        try self.loadStageFromFileFinish("content/mainMenu.json", 0);
        self.screenEffects.startEngineSplashSequence(core.MakeName("t_engineSplash"), core.MakeName("s_engineSplash"));
        self.playedIntro = false;
        // try self.loadStageFromFileFinish("content/BreakRoom.json", 0);

        // load interactions
        // _ = try self.interactions.addTalkable(
        //     core.MakeName("test"),
        //     "coffee",
        //     .{.x = 1.8, .z = 0.5177, .y = 3.54},
        //     0.5,
        // );

        // _ = try self.interactions.addTalkable(
        //     core.MakeName("test2"),
        //     "denver_chair",
        //     .{.x = -3.749, .z = 2.1177, .y = 2.77},
        //     0.5,
        // );

        // _ = try self.interactions.addTalkable(
        //     core.MakeName("door"),
        //     "bathroom_door",
        //     .{.z = 6.46, .x = 3.286, .y = 1.95},
        //     0.5,
        // );

        // _ = try self.interactions.addTalkable(
        //     core.MakeName("setSpeakertest"),
        //     "set_speaker_test",
        //     .{.z = 6.22, .x = -4.076, .y = 1.95},
        //     0.5,
        // );

        // _ = try self.interactions.addTalkable(
        //     core.MakeName("setSpeakertest2"),
        //     "radio",
        //     .{.x = 2.5, .z = 2.5, .y = 2.75},
        //     0.5,
        // );
        // _ = try self.interactions.addTalkable(
        //     core.MakeName("somethingElse"),
        //     "lights_out",
        //     .{.x = -1.21, .z = -6.10, .y = 2.75},
        //     0.5,
        // );

    }

    pub fn tick(self: *Self, deltaTime: f64) void {

        // ---- poll camera stuff ----
        c.glfwGetCursorPos(self.gc.window, &self.mousePosition.x, &self.mousePosition.y);

        // was there why isn't this automatic?.. think about it later
        if (self.camera.isDirty()) {
            self.camera.updateCamera();
        }

        self.camera.resolve(self.cameraHorizontalRotationMat);
        self.inDialogue = self.dialogueSys.speechWindow or self.screenEffects.pageVisible;
        if (self.screenEffects.pageVisible or self.screenEffects.pageState != .holding) {
            self.dialogueSys.dialogueIsHidden = true;
        } else {
            self.dialogueSys.dialogueIsHidden = false;
        }

        if (self.testWindow) {
            var ray = self.gc.getNormRayFromActiveCamera(&self.camera, self.mousePosition);

            var maybeTrace = collisions.intersectPlaneAndLine(ray.start, ray.dir, 0, 1, 0, 0);
            //var pos = core.gScene.getPosition(self.denver);
            //graphics.debugSphere(self.camera.position, 50, .{});

            if (maybeTrace) |trace| {
                graphics.debugLine(trace, trace.add(core.Vectorf.new(0, 5.0, 0)), .{
                    .color = core.Vectorf.new(0, 1.0, 1.0),
                });
                self.mousePick = trace;
            }
        }

        //{
        // var pos = core.gScene.getPosition(self.denver);
        // var maybeTrace = collisions.intersectPlaneAndLine(
        //     core.Vectorf.new(pos.x, 5, pos.z),
        //     core.Vectorf.new(1, -1, 0),
        //     0, 1, 0, 0
        // );

        // if(maybeTrace) |trace|
        // {
        //     graphics.debugSphere(trace, 5, .{
        //         .color = core.Vectorf.new(1.0, 1.0, 0),
        //     });
        // }
        //}

        // --------------------------

        var movement = self.movementInput.normalize().fmul(@floatCast(f32, deltaTime));

        if (!self.movementEnabled) {
            movement = core.Vectorf.zero();
        }

        var posRot = core.gScene.objects.get(self.denver, .posRot).?;
        const dt = @floatCast(f32, deltaTime);
        const speed = 4.0;
        var moved: bool = false;

        if (!self.inDialogue and (!(self.screenEffects.blackFadeIsFading and self.screenEffects.loadWhenFaded != null))) {
            if (movement.z > 0) {
                self.facingDir = .{ .x = 0, .y = 0, .z = 1 };
                const movementVector = self.facingDir.fmul(speed * dt);
                self.currentAnim = core.MakeName("walkDown");
                if (!self.checkMovement(posRot.position, movementVector)) {
                    self.flipped = false;
                    moved = true;
                    posRot.*.position = posRot.position.add(movementVector);
                    self.cameraPosition = self.cameraPosition.add(movementVector);
                }
            } else if (movement.z < 0) {
                self.facingDir = .{ .x = 0, .y = 0, .z = -1 };
                const movementVector = self.facingDir.fmul(speed * dt);
                self.currentAnim = core.MakeName("walkUp");
                if (!self.checkMovement(posRot.position, movementVector)) {
                    moved = true;
                    self.flipped = false;
                    posRot.*.position = posRot.position.add(movementVector);
                    self.cameraPosition = self.cameraPosition.add(movementVector);
                }
            } else if (movement.x < 0) {
                self.facingDir = .{ .z = 0, .y = 0, .x = -1 };
                const movementVector = self.facingDir.fmul(speed * dt);
                self.currentAnim = core.MakeName("walkRight");
                self.flipped = true;
                if (!self.checkMovement(posRot.position, movementVector)) {
                    moved = true;
                    posRot.*.position = posRot.position.add(movementVector);
                    self.cameraPosition = self.cameraPosition.add(movementVector);
                }
            } else if (movement.x > 0) {
                self.facingDir = .{ .z = 0, .y = 0, .x = 1 };
                const movementVector = self.facingDir.fmul(speed * dt);
                self.currentAnim = core.MakeName("walkRight");
                self.flipped = false;
                if (!self.checkMovement(posRot.position, movementVector)) {
                    moved = true;
                    posRot.*.position = posRot.position.add(movementVector);
                    self.cameraPosition = self.cameraPosition.add(movementVector);
                }
            }
        }

        if (!moved) {
            if (self.currentAnim.hash == core.MakeName("walkDown").hash) {
                self.currentAnim = core.MakeName("idleDown");
            }
            if (self.currentAnim.hash == core.MakeName("walkRight").hash) {
                self.currentAnim = core.MakeName("idleRight");
            }
            if (self.currentAnim.hash == core.MakeName("walkUp").hash) {
                self.currentAnim = core.MakeName("idleUp");
            }
        }

        const checkPos = posRot.position.add(self.facingDir.fmul(0.5));
        if (self.testWindow) {
            graphics.debug_draw.debugSphere(checkPos, 0.5, .{});
            graphics.debugLine(checkPos, core.gScene.getPosition(self.denver), .{
                .duration = 0.0,
            });
        }

        if (gGame.interactions.getNearestObjectInRange(checkPos, 1, self.testWindow)) |i| {
            var pr = core.gScene.objects.get(self.exclamation, .posRot).?;
            pr.*.position = i.*.position.add(.{ .x = 0, .y = 0.5, .z = 0 });

            self.gc.setObjectVisibility(self.exclamation, true);
            self.currentInteraction = i;
        } else {
            self.gc.setObjectVisibility(self.exclamation, false);
            self.currentInteraction = null;
        }

        if (self.currentAnimCache.hash != self.currentAnim.hash) {
            self.currentAnimCache = self.currentAnim;
            const currentFrame = self.papyrus.getAnimInstance(self.denver).?.currentAnimFrameIndex;
            self.papyrus.playSpriteAnimation(self.denver, self.currentAnim, .{}) catch unreachable;
            var animInstance = self.papyrus.getAnimInstance(self.denver).?;
            animInstance.*.currentAnimFrameIndex = currentFrame % animInstance.animation.frameCount;
        }

        self.papyrus.setSpriteFlipped(self.denver, self.flipped);
        self.papyrus.tick(deltaTime);

        self.dialogueSys.tick(deltaTime);
        self.handleShakeScreen(@floatCast(f32, deltaTime));
        self.screenEffects.tickAnims(@floatCast(f32, deltaTime));
        if (self.screenEffects.engineSplashState == .dead and !self.screenEffects.engineSplashFirstFrame) {
            if (self.playedIntro == false) {
                self.playedIntro = true;
                self.screenEffects.startEngineSplashSequence(core.MakeName("t_cognesia"), core.MakeName("s_fs_reverb"));
                self.playingCognesiaSplash = true;
                //self.showInstructions = true;
                //self.halcyon.startDialogue("main_menu_dialogue");
            }
        }

        if (self.playingCognesiaSplash and self.screenEffects.engineSplashState == .dead) {
            self.playingCognesiaSplash = false;
            self.halcyon.startDialogue("main_menu_dialogue");
        }

        self.camera.position = self.cameraPosition.add(self.shakeScreenOffset);
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
        core.engine_logs("OpeningDebugMenu");
        if (debugAvailable)
            gGame.testWindow = !gGame.testWindow;
    }
    if (key == c.GLFW_KEY_F1 and action == c.GLFW_PRESS) {
        core.engine_logs("OpeningDebugMenu");
        gGame.showInstructions = !gGame.showInstructions;
    }

    if (key == c.GLFW_KEY_A and action == c.GLFW_PRESS) {
        const pos = gGame.mousePick;
        core.engine_log("\n{{\n \"position\": {{\"x\":{d}, \"z\":{d}, \"y\":{d}}},", .{ pos.x, pos.z, 1.9 });
        std.debug.print(" \"radius\": {d},", .{0.5});
        std.debug.print("\n \"tag\": \"{s}\"", .{"placeholder"});
        std.debug.print("\n}}", .{});
    }

    if (action == c.GLFW_PRESS) {
        if (key == c.GLFW_KEY_Z) {
            if (!gGame.dialogueSys.speechWindow and !gGame.screenEffects.blackFadeIsFading) {
                // gGame.dialogueSys.startDialogue(MakeName("t_denver_big"), "Denver", "Why is my room purple.");
                if (gGame.currentInteraction) |i| {
                    core.engine_logs("starting dialogue");
                    i.interface.onInteract();
                }
            } else {
                if (gGame.dialogueSys.choices.choices.items.len > 0) {
                    gGame.halcyon.progress(gGame.dialogueSys.choices.active_choice);
                } else {
                    if (!gGame.dialogueSys.dialogueIsHidden) {
                        gGame.halcyon.progress(null);
                    }
                }
                if (gGame.screenEffects.pageVisible and gGame.screenEffects.pageState == .holding) {
                    gGame.halcyon.progress(null);
                    gGame.screenEffects.hidePage();
                }
            }
        }
        if (key == c.GLFW_KEY_EQUAL) {
            gGame.volumeUp();
        }
        if (key == c.GLFW_KEY_MINUS) {
            gGame.volumeDown();
        }
        if (key == c.GLFW_KEY_UP) {
            gGame.movementInput.z += -1.0;
            gGame.dialogueSys.choices.cursorUp();
        }
        if (key == c.GLFW_KEY_DOWN) {
            gGame.movementInput.z += 1.0;
            gGame.dialogueSys.choices.cursorDown();
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
    graphics.setWindowName("Cognesia - Rpg Horror Gamejam");
    graphics.icon = "content/cognesia.png";
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
    var gameContext = try core.gEngine.createObject(GameContext, .{ .can_tick = true });
    try gameContext.prepareGame();

    // run the game
    core.gEngine.run();
}
