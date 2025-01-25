allocator: std.mem.Allocator,
camera: graphics.Camera,

const AssetReferences = [_]assets.AssetImportReference{
    assets.MakeImportRefOptions(
        "Mesh",
        "m_empire",
        .{
            .path = "meshes/lost_empire.obj",
        },
    ),
};

pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

pub fn init(allocator: std.mem.Allocator) !*@This() {
    const self = try allocator.create(@This());
    self.* = .{
        .allocator = allocator,
        .camera = graphics.Camera.init(),
    };

    self.camera.rotation = core.zm.quatFromRollPitchYaw(core.radians(0.0), core.radians(0.0), 0.0);
    self.camera.fov = 70.0;
    self.camera.position = .{ .x = 0.0, .y = 0, .z = 0 };
    self.camera.updateCamera();
    // self.camera.resolve(core.zm.translation(0, 0, 0));
    return self;
}

pub fn prepare_game(self: *@This()) !void {
    try assets.loadList(AssetReferences);
    graphics.getContext().activateCamera(&self.camera);
    try core.fs().addContentPath("demo_lua");
    try script.loadTypes("scripts");
    try script.runScriptFile("scripts/prepare.lua");

    ui.getContext().drawDebug = true;
}

pub fn tick(self: *@This(), _: f64) void {
    _ = self;
}

pub fn deinit(self: *@This()) void {
    self.allocator.destroy(self);
}

pub fn main() anyerror!void {
    try neonwood.initializeAndRunStandardProgram(@This(), .{
        .name = "Hello World",
    });
}

const std = @import("std");
const neonwood = @import("NeonWood");
const graphics = neonwood.graphics;
const core = neonwood.core;
const ui = neonwood.ui;
const assets = neonwood.assets;
const script = core.script;
