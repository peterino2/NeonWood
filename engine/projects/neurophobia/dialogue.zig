const std = @import("std");
pub const neonwood = @import("../../modules/neonwood.zig");

const animations = @import("animations.zig");
const papyrusSprite = @import("papyrus.zig");
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

pub const DialogueLine = struct {
    text: []const u8,
};

pub const DialogueSystem = struct {

    allocator: std.mem.Allocator,
    gc: *graphics.NeonVkContext,

    pub fn init(allocator: std.mem.Allocator, gc: graphics.NeonVkContext) @This()
    {
        var self = DialogueSystem{
            .allocator = allocator,
            .gc = gc,
        };

        return self;
    }

    // must be called from a ui context
    pub fn uiTick(self: *@This(), deltaTime: f64) void 
    {

        _ = deltaTime;
        _ = self;
    }

    pub fn tick(self: *@This(), deltaTime: f64) void
    {
        _ = self;
        _ = deltaTime;
    }

    pub fn deinit(self: *@This()) void 
    {
        _ = self;
    }
};