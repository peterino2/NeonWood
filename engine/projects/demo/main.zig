const std = @import("std");
pub const neonwood = @import("root").neonwood;

const core = neonwood.core;
const platform = neonwood.platform;
const ui = neonwood.ui;
const NodeHandle = ui.NodeHandle;
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
        },
    ),
    assets.MakeImportRefOptions("Texture", "t_empire", .{
        .path = testimage1,
        .textureUseBlockySampler = false,
    }),
};

// Primarily a test file that exists to create a simple application for
// basic engine onboarding
pub const GameContext = struct {
    const Self = @This();
    pub var NeonObjectTable: core.RttiData = core.RttiData.from(Self);

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

    time: f64 = 0,
    movingAverage: f64 = 0,
    panel: NodeHandle = .{},
    panelText: ?[]u8 = null,

    frameCount: u32 = 5,

    pub fn init(allocator: std.mem.Allocator) !*Self {
        var self = try allocator.create(@This());
        self.* = Self{
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
            const texName = core.MakeName("t_empire");
            if (self.gc.textures.contains(texName.handle())) {
                var obj = self.gc.renderObjectSet.get(self.objHandle, .renderObject).?;
                obj.setTextureByName(self.gc, texName);
                self.assetReady = true;
            }
        }

        const position = platform.getInstance().getCursorPosition();
        var dx = @as(f32, @floatCast(position.x - (@as(f32, @floatCast(lastXPos)))));
        var dy = @as(f32, @floatCast(position.y - (@as(f32, @floatCast(lastYPos)))));

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

        self.camera.position = self.camera.position.add(moveRot.fmul(10.0).fmul(@as(f32, @floatCast(deltaTime))));
        self.camera.updateCamera();
        self.camera.resolve(self.cameraHorizontalRotationMat);

        var i: f32 = 0;
        while (i < 1000) : (i += 1) {
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
        self.tickPanel(deltaTime) catch unreachable;
    }

    pub fn tickPanel(self: *@This(), deltaTime: f64) !void {
        self.time += deltaTime;
        self.frameCount -= 1;
        if (self.frameCount == 0) {
            self.frameCount = 5;
            var ctx = ui.getContext();

            if (self.panelText) |t| {
                self.allocator.free(t);
            }

            self.panelText = try std.fmt.allocPrint(self.allocator, "Testing Quality: Lorem Ipsum, fps: {d:.2}", .{1 / deltaTime});
            ctx.get(self.panel).text = ui.papyrus.LocText.fromUtf8(self.panelText.?);
        }

        if (gIpsumDown) {
            var ctx = ui.getContext();
            var mousePos = platform.getInstance().getCursorPosition();
            ctx.get(unk).pos = .{ .x = mousePos.x + gSavedMouseOffset.x, .y = mousePos.y + gSavedMouseOffset.y };
            gIpsumPos = .{ .x = ctx.getRead(unk).pos.x, .y = ctx.getRead(unk).pos.y };
        }
    }

    pub fn uiTick(self: *Self, deltaTime: f64) void {
        _ = deltaTime;
        _ = self;
    }

    pub fn prepare_game(self: *Self) !void {
        self.gc = graphics.getContext();
        try assets.loadList(AssetReferences);

        self.camera.translate(.{ .x = 0.0, .y = -0.0, .z = -6.0 });
        self.gc.activateCamera(&self.camera);
        self.objHandle = try self.gc.add_renderobject(.{
            .mesh_name = core.MakeName("m_empire"),
            .material_name = core.MakeName("t_mesh"),
            .init_transform = core.zm.translation(0, -15, 0),
        });

        var ctx = ui.getContext();

        {
            const ModernStyle = ui.papyrus.ModernStyle;
            var panel = try ctx.addPanel(.{});
            self.panel = panel;
            ctx.getPanel(panel).hasTitle = true;
            ctx.getPanel(panel).titleColor = ModernStyle.GreyDark;
            ctx.get(panel).text = ui.papyrus.MakeText("Testing Quality: Lorem Ipsum");
            ctx.get(panel).style.backgroundColor = ModernStyle.Grey;
            ctx.get(panel).style.foregroundColor = ModernStyle.Yellow;
            ctx.get(panel).style.borderColor = ModernStyle.BrightGrey;
            ctx.get(panel).pos = .{ .x = gIpsumPos.x, .y = gIpsumPos.y };
            ctx.get(panel).setSize(.{ .x = 500, .y = 150 });
        }

        gGame = self;

        unk = try ctx.addPanel(.{});
        ctx.get(unk).pos = .{ .x = 900, .y = 30 };
        ctx.get(unk).setSize(.{ .x = 300, .y = 300 });
        ctx.get(unk).style.borderColor = BurnStyle.Diminished;
        ctx.get(unk).style.backgroundColor = BurnStyle.DarkSlateGrey;

        try ctx.events.installOnPressedEvent(unk, .onReleased, .Mouse1, &onPressed);
        try ctx.events.installOnPressedEvent(unk, .onPressed, .Mouse1, &onPressed);

        const unk2 = try ctx.addPanel(unk);
        {
            ctx.get(unk2).pos = .{ .x = 20, .y = 20 };
            ctx.get(unk2).setSize(.{ .x = 100, .y = 20 });
            ctx.get(unk2).style.backgroundColor = BurnStyle.LightGrey;
            try ctx.events.installOnPressedEvent(unk2, .onPressed, .Mouse1, &onUnk2);
            try ctx.events.installOnPressedEvent(unk2, .onReleased, .Mouse1, &onUnk2);
            try ctx.events.installMouseOverEvent(unk2, .mouseOff, &onUnk2MouseOff);

            const unk2Text = try ctx.addText(unk2, "click me!");
            ctx.get(unk2Text).pos = .{ .x = 5, .y = 5 };
            ctx.get(unk2Text).setSize(.{ .x = 150, .y = 75 });
            ctx.setFont(unk2Text, "roboto");
            ctx.getText(unk2Text).textSize = 12;
        }
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }
};

var unk: ui.NodeHandle = undefined;
var gIpsumPos: core.Vector2f = .{ .x = 900, .y = 30 };
var gSavedMouseOffset: core.Vector2f = .{};
var gIpsumDown: bool = false;

fn onPressed(node: ui.NodeHandle, eventType: ui.PressedEventType) ui.EventHandlerError!void {
    _ = node;
    if (eventType == .onPressed) {
        gIpsumDown = true;
        var mousePos = platform.getInstance().getCursorPosition();
        gSavedMouseOffset = gIpsumPos.sub(core.Vector2f{ .x = mousePos.x, .y = mousePos.y });
    }
    if (eventType == .onReleased) {
        gIpsumDown = false;
    }
}

const BurnStyle = ui.papyrus.BurnStyle;

fn onUnk2(node: ui.NodeHandle, eventType: ui.PressedEventType) ui.EventHandlerError!void {
    var ctx = ui.getContext();

    if (eventType == .onPressed) {
        core.engine_logs("I GOT CLICKED!!!");
        ctx.get(node).style.backgroundColor = BurnStyle.DarkSlateGrey;
        ui.getContext().drawDebug = !ui.getContext().drawDebug;
    }

    if (eventType == .onReleased) {
        ctx.get(node).style.backgroundColor = BurnStyle.LightGrey;
    }
}

fn onUnk2MouseOff(node: ui.NodeHandle) ui.EventHandlerError!void {
    ui.getContext().get(node).style.backgroundColor = BurnStyle.LightGrey;
}

var lastXPos: f64 = 0;
var lastYPos: f64 = 0;

pub fn mousePositionCallback(window: ?*platform.c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    _ = window;
    _ = xpos;
    _ = ypos;
    var t1 = core.tracy.ZoneN(@src(), "Movement Callback");
    defer t1.End();
}

pub fn input_callback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    _ = mods;
    _ = scancode;
    _ = window;

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

        if (key == c.GLFW_KEY_E) {
            gGame.movementInput.y += 1;
        }

        if (key == c.GLFW_KEY_Q) {
            gGame.movementInput.y -= 1;
        }

        if (key == c.GLFW_KEY_A) {
            gGame.movementInput.x += -1;
        }

        if (key == c.GLFW_KEY_D) {
            gGame.movementInput.x += 1;
        }

        if (action == c.GLFW_PRESS) {
            if (key == c.GLFW_KEY_P) {
                neonwood.ui.getSystem().displayDemo = !neonwood.ui.getSystem().displayDemo;
            }
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

        if (key == c.GLFW_KEY_E) {
            gGame.movementInput.y -= 1;
        }

        if (key == c.GLFW_KEY_Q) {
            gGame.movementInput.y += 1;
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

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .stack_trace_frames = 20,
    }){};

    defer {
        const cleanupStatus = gpa.deinit();
        if (cleanupStatus == .leak) {
            std.debug.print("gpa cleanup leaked memory\n", .{});
        }
    }
    var allocator = std.heap.c_allocator;

    engine_log("Starting up", .{});

    var args = try neonwood.getArgs();

    if (args.useGPA) {
        core.engine_logs("Using GPA allocator");
        allocator = gpa.allocator();
    }

    core.start_module(allocator);
    defer core.shutdown_module(allocator);

    try platform.start_module(allocator, "Neonwood: flyaround demo", null);
    defer platform.shutdown_module(allocator);

    assets.start_module(allocator);
    defer assets.shutdown_module(allocator);

    graphics.start_module(allocator);
    defer graphics.shutdown_module();

    audio.start_module(allocator);
    defer audio.shutdown_module();

    try ui.start_module(allocator);
    defer ui.shutdown_module();

    var gameContext = try core.createObject(GameContext, .{ .can_tick = true });
    try gameContext.prepare_game();

    try core.gEngine.run();

    _ = c.glfwSetKeyCallback(@as(?*c.GLFWwindow, @ptrCast(platform.getInstance().window)), input_callback);
    try platform.getInstance().installCursorPosCallback(mousePositionCallback);

    while (!core.gEngine.exitConfirmed) {
        neonwood.platform.getInstance().pollEvents();
    }
}
