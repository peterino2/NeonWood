const std = @import("std");
pub const neonwood = @import("root").neonwood;

const core = neonwood.core;
const platform = neonwood.platform;
const ui = neonwood.ui;
const graphics = neonwood.graphics;
const assets = neonwood.assets;
const engine_log = core.engine_log;

const audio = neonwood.audio;
const c = graphics.c;
var gGame: *GameContext = undefined;

const testimage1 = "content/textures/lost_empire-RGBA.png";
const testimage2 = "content/textures/texture_sample.png";

// Asset loader
const AssetReferences = [_]assets.AssetImportReference{
    assets.MakeImportRefOptions(
        "Mesh",
        "m_empire",
        .{
            .path = "content/meshes/lost_empire.obj",
            .textureUseBlockySampler = false,
        },
    ),
    assets.MakeImportRef("Texture", "m_texture", testimage1),
};

// Primarily a test file that exists to create a simple application for
// basic engine onboarding
pub const GameContext = struct {
    const Self = @This();
    pub const NeonObjectTable = core.RttiData.from(Self);
    pub const InterfaceUiTable = core.InterfaceUiData.from(Self);

    camera: graphics.Camera,
    allocator: std.mem.Allocator,
    showDemo: bool = true,
    debugOpen: bool = true,
    gc: *graphics.NeonVkContext = undefined,
    objHandle: core.ObjectHandle = .{},
    assetReady: bool = false,
    cameraHorizontalRotationMat: core.Mat,
    cameraTime: f64 = 0.0,
    movementInput: core.Vectorf = core.Vectorf.new(0.0, 0.0, 0.0),
    eulerX: f32 = 0,
    eulerY: f32 = 0,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
            .camera = graphics.Camera.init(),
            .cameraHorizontalRotationMat = core.zm.identity(),
        };

        self.camera.rotation = core.zm.quatFromRollPitchYaw(core.radians(30.0), core.radians(0.0), 0.0);
        self.camera.fov = 70.0;
        self.camera.position = .{ .x = 0.0, .y = 6.5, .z = 0 };
        self.camera.updateCamera();
        self.camera.resolve(self.cameraHorizontalRotationMat);

        return self;
    }

    pub fn tick(self: *@This(), deltaTime: f64) void {
        if (!self.assetReady) {
            const texName = core.MakeName("m_texture");
            if (self.gc.textures.contains(texName.hash)) {
                var obj = self.gc.renderObjectSet.get(self.objHandle, .renderObject).?;
                obj.setTextureByName(self.gc, texName);
                self.assetReady = true;
            }
        }

        const position = platform.getInstance().getCursorPosition();
        var dx = @floatCast(f32, position.x - (@floatCast(f32, lastXPos)));
        var dy = @floatCast(f32, position.y - (@floatCast(f32, lastYPos)));

        if (!platform.getInstance().cursorEnabled) {
            self.eulerX += dx / 1920;
            self.eulerY += dy / 1080;
            self.eulerY = std.math.clamp(gGame.eulerY, core.radians(-90.0), core.radians(90.0));
        }

        lastXPos = position.x;
        lastYPos = position.y;

        self.cameraTime += deltaTime;
        self.camera.rotation = core.zm.quatFromRollPitchYaw(self.eulerY, 0, 0);
        self.cameraHorizontalRotationMat = core.zm.matFromRollPitchYaw(0, self.eulerX, 0);

        var moveRot = core.Vectorf.fromZm(core.zm.mul(self.cameraHorizontalRotationMat, self.movementInput.normalize().toZm()));

        self.camera.position = self.camera.position.add(moveRot.fmul(10.0).fmul(@floatCast(f32, deltaTime)));
        self.camera.updateCamera();
        self.camera.resolve(self.cameraHorizontalRotationMat);

        var i: f32 = 0;
        while (i < 0) : (i += 1) {
            graphics.debugLine(
                .{ .x = -1000, .y = 0, .z = -1000 + i * 10 },
                .{ .x = 1000, .y = 0, .z = -1000 + i * 10 },
                .{},
            );

            graphics.debugLine(
                .{ .x = -1000 + i * 10, .y = 0, .z = -1000 },
                .{ .x = -1000 + i * 10, .y = 0, .z = 1000 },
                .{},
            );
        }
    }

    pub fn uiTick(self: *Self, deltaTime: f64) void {
        _ = deltaTime;

        var idStr: []const u8 = "DockWindow";
        var dockspaceID = c.igGetIDWithSeed(idStr.ptr, &idStr[idStr.len - 1], 0);

        var viewport = c.igGetMainViewport();

        c.igSetNextWindowPos(viewport.?.*.WorkPos, 0, .{ .x = 0, .y = 0 });
        c.igSetNextWindowSize(viewport.?.*.WorkSize, 0);
        c.igPushStyleVar_Float(c.ImGuiStyleVar_WindowRounding, 0.0);
        c.igPushStyleVar_Float(c.ImGuiStyleVar_WindowBorderSize, 0.0);

        c.igPushStyleVar_Vec2(c.ImGuiStyleVar_WindowPadding, .{ .x = 0, .y = 0 });

        var dockspace_flags: c_int = c.ImGuiDockNodeFlags_None;
        var window_flags: c_int = c.ImGuiWindowFlags_MenuBar | c.ImGuiWindowFlags_NoDocking;
        window_flags |= c.ImGuiWindowFlags_NoTitleBar | c.ImGuiWindowFlags_NoCollapse | c.ImGuiWindowFlags_NoResize;
        window_flags |= c.ImGuiWindowFlags_NoMove | c.ImGuiWindowFlags_NoBringToFrontOnFocus | c.ImGuiWindowFlags_NoNavFocus;
        window_flags |= c.ImGuiWindowFlags_NoBackground;

        if (c.igBegin("DockSpace Demo", null, window_flags)) {
            if (c.igBeginMenuBar()) {
                if (c.igBeginMenu("Options", true)) {
                    _ = c.igMenuItem_Bool("Fullscreen", null, true, true);
                    c.igEndMenu();
                }
                c.igEndMenuBar();
            }
            _ = c.igDockSpace(dockspaceID, .{ .x = 0, .y = 0 }, dockspace_flags, null);
            c.igEnd();
        }

        c.igPopStyleVar(3);

        if (self.debugOpen) {
            if (c.igBegin("Debug Menu", &self.debugOpen, 0)) {
                c.igText("Sample Text");

                if (c.igButton("Press me!", .{ .x = 250.0, .y = 30.0 })) {
                    core.engine_logs("I have been pressed!");
                    self.debugOpen = false;
                }
            }
            c.igEnd();
        }

        var showDemo: bool = true;
        c.igShowDemoWindow(&showDemo);
    }

    pub fn prepare_game(self: *Self) !void {
        try graphics.getContext().add_ui_object(.{
            .ptr = self,
            .vtable = &InterfaceUiTable,
        });

        self.gc = graphics.getContext();
        try assets.loadList(AssetReferences);

        self.camera.translate(.{ .x = 0.0, .y = -0.0, .z = -6.0 });
        self.gc.activateCamera(&self.camera);
        self.objHandle = try self.gc.add_renderobject(.{
            .mesh_name = core.MakeName("m_empire"),
            .material_name = core.MakeName("mat_mesh"),
            .init_transform = core.zm.translation(0, -15, 0),
        });

        gGame = self;
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }
};

pub fn main() anyerror!void {
    engine_log("Starting up", .{});

    core.start_module();
    defer core.shutdown_module();

    try platform.start_module(std.heap.c_allocator, "Neonwood: flyaround demo", null);

    assets.start_module();
    defer assets.shutdown_module();

    audio.start_module();
    defer audio.shutdown_module();

    graphics.start_module();
    defer graphics.shutdown_module();

    try ui.start_module(std.heap.c_allocator);
    defer ui.shutdown_module();

    var gameContext = try core.createObject(GameContext, .{ .can_tick = true });
    try gameContext.prepare_game();

    try core.gEngine.run();

    _ = c.glfwSetKeyCallback(@ptrCast(?*c.GLFWwindow, platform.getInstance().window), input_callback);
    try platform.getInstance().installCursorPosCallback(mousePositionCallback);

    while (!core.gEngine.exitSignal) {
        neonwood.platform.getInstance().pollEvents();
    }
}

var lastXPos: f64 = 0;
var lastYPos: f64 = 0;

pub fn mousePositionCallback(window: ?*platform.c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    _ = window;
    _ = xpos;
    _ = ypos;
    // c.cImGui_ImplGlfw_CursorPosCallback(@ptrCast(?*c.GLFWwindow, window), xpos, ypos);
    var t1 = core.tracy.ZoneN(@src(), "Movement Callback");
    defer t1.End();
}

pub fn input_callback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    c.cImGui_ImplGlfw_KeyCallback(window, key, scancode, action, mods);

    // Todo turn these into an events pump

    if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS) {
        core.engine_logs("Escape key pressed, game ends now");
        core.gEngine.exit();
    }

    if (action == c.GLFW_PRESS) {
        if (key == c.GLFW_KEY_W) {
            gGame.movementInput.z += -1;
        }

        if (key == c.GLFW_KEY_S) {
            gGame.movementInput.z += 1;
        }

        if (key == c.GLFW_KEY_A) {
            gGame.movementInput.x += -1;
        }

        if (key == c.GLFW_KEY_D) {
            gGame.movementInput.x += 1;
        }

        if (key == c.GLFW_KEY_LEFT_ALT) {
            platform.getInstance().setCursorEnabled(false);
        }
    }
    if (action == c.GLFW_RELEASE) {
        if (key == c.GLFW_KEY_W) {
            gGame.movementInput.z -= -1;
        }

        if (key == c.GLFW_KEY_S) {
            gGame.movementInput.z -= 1;
        }

        if (key == c.GLFW_KEY_A) {
            gGame.movementInput.x -= -1;
        }

        if (key == c.GLFW_KEY_D) {
            gGame.movementInput.x -= 1;
        }
        if (key == c.GLFW_KEY_LEFT_ALT) {
            platform.getInstance().setCursorEnabled(true);
        }
    }

    if (key == c.GLFW_KEY_SPACE and action == c.GLFW_PRESS) {
        gGame.showDemo = true;
    }
}
