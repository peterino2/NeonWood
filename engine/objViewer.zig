const std = @import("std");
const neonwood = @import("modules/neonwood.zig");
const core = neonwood.core;
const graphics = neonwood.graphics;
const engine_log = core.engine_log;

const Camera = graphics.render_object.Camera;
const RenderObject = graphics.render_objects.RenderObject;

const AssetReference = struct {
    name: core.Name,
    path: []const u8,
};

const GameMeshAsset = struct {};

const TextureAssets = [_]AssetReference{
    .{ .name = core.MakeName("test_sprite"), .path = "content/singleSpriteTest.png" },
    .{ .name = core.MakeName("lost_empire"), .path = "content/lost_empire-RGBA.png" },
};

const MeshAssets = [_]AssetReference{
    .{ .name = core.MakeName("m_monkey"), .path = "content/monkey.obj" },
    .{ .name = core.MakeName("m_room"), .path = "content/SCUFFED_Room.obj" },
    .{ .name = core.MakeName("m_empire"), .path = "content/lost_empire.obj" },
};

// primarily a test file that exists to create a simple application for
// basic engine onboarding
const GameContext = struct {
    const Self = @This();
    pub const NeonObjectTable = core.RttiData.from(Self);

    allocator: std.mem.Allocator,
    camera: Camera,
    gc: *graphics.NeonVkContext,

    isRotating: bool = false,
    shouldExit: bool = false,
    textureAssets: std.ArrayListUnmanaged(AssetReference),
    meshAssets: std.ArrayListUnmanaged(AssetReference),

    pub fn init(allocator: std.mem.Allocator) Self {
        var self = Self{
            .allocator = allocator,
            .camera = Camera.init(),
            .textureAssets = .{},
            .meshAssets = .{},
            .gc = graphics.getContext(),
        };

        self.textureAssets.appendSlice(self.allocator, &TextureAssets) catch unreachable;
        self.meshAssets.appendSlice(self.allocator, &MeshAssets) catch unreachable;

        return self;
    }

    pub fn load_texture(self: *Self, assetRef: AssetReference) !void {
        _ = try self.gc.create_standard_texture_from_file(assetRef.name, assetRef.path);
        try self.gc.make_mesh_image_from_texture(assetRef.name);
    }

    pub fn load_mesh(self: *Self, assetRef: AssetReference) !void {
        _ = try self.gc.new_mesh_from_obj(assetRef.name, assetRef.path);
    }

    pub fn prepare_game(self: *Self) !void {
        for (self.textureAssets.items) |asset| {
            try self.load_texture(asset);
        }

        for (self.meshAssets.items) |asset| {
            try self.load_mesh(asset);
        }
    }

    pub fn tick(self: *Self, deltaTime: f64) void {
        _ = self;
        _ = deltaTime;
        core.gEngine.exit();
    }

    pub fn deinit(self: *Self) void {
        _ = self;
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
