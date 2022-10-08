const std = @import("std");
const neonwood = @import("modules/neonwood.zig");
const core = neonwood.core;
const graphics = neonwood.graphics;
const assets = neonwood.assets;
const engine_log = core.engine_log;
const c = graphics.c;

const Vectorf = core.Vectorf;
const Vector2 = core.Vector2;
const Camera = graphics.render_object.Camera;
const RenderObject = graphics.render_objects.RenderObject;
const AssetReference = assets.AssetReference;
const MakeName = core.MakeName;
const mul = core.zm.mul;

const TextureAssets = [_]AssetReference{
    .{ .name = core.MakeName("t_sprite"), .path = "content/singleSpriteTest.png" },
};

const MeshAssets = [_]AssetReference{
};

var gGame: *GameContext = undefined;

// spriteTool: 
// 1. loads a texture and displays it on the screen

// primarily a test file that exists to create a simple application for
// basic engine onboarding
const GameContext = struct {
    const Self = @This();
    pub const NeonObjectTable = core.RttiData.from(Self);
    pub const InterfaceUiTable = core.InterfaceUiData.from(Self);

    allocator: std.mem.Allocator,
    camera: Camera,
    gc: *graphics.NeonVkContext,

    isRotating: bool = false,
    shouldExit: bool = false,
    sensitivity: f64 = 0.005,

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
            .camera = Camera.init(),
            .gc = graphics.getContext(),
        };
        self.camera.updateCamera();
        return self;
    }

    pub fn load_texture(self: *Self, assetRef: AssetReference) !void {
        _ = try self.gc.create_standard_texture_from_file(assetRef.name, assetRef.path);
        try self.gc.make_mesh_image_from_texture(assetRef.name);
    }

    pub fn init_objects(self: *Self) !void {
        _ = self;
        var gc = self.gc;

        var renderObject = try gc.add_renderobject(.{
            .mesh_name = MakeName("mesh_quad"),
            .material_name = MakeName("mat_mesh"),
            .init_transform = mul(core.zm.scaling(3.0, 3.0, 3.0), core.zm.translation(2.0, 1.5, 1.0)),
        });

        var ptr = gc.renderObjectSet.get(renderObject, .renderObject).?;
        ptr.setTextureByName(self.gc, MakeName("t_sprite"));
        ptr.applyRelativeRotationX(core.radians(-15.0));
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

    pub fn prepare_game(self: *Self) !void {
        gGame = self;

        for (self.textureAssets.items) |asset| {
            try self.load_texture(asset);
        }

        for (self.meshAssets.items) |asset| {
            try self.load_mesh(asset);
        }

        _ = c.glfwSetKeyCallback(self.gc.window, input_callback);
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
        self.camera.translate(.{ .x = movement_v[0], .y = movement_v[1], .z = movement_v[2] });
        self.handleCameraPan(deltaTime);
    }

    pub fn deinit(self: *Self) void {
        self.textureAssets.deinit(self.allocator);
        self.meshAssets.deinit(self.allocator);
    }
};

pub fn main() anyerror!void {
    engine_log("Starting up", .{});

    core.start_module();
    defer core.shutdown_module();
    graphics.start_module();
    defer graphics.shutdown_module();

    // Setup the game
    var gameContext = try core.createObject(GameContext, .{ .can_tick = true });
    try gameContext.prepare_game();

    // run the game
    core.gEngine.run();
}

pub fn input_callback(
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

    if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS) {
        core.engine_logs("Escape key test ends now.");
        core.gEngine.exit();
    }
}
