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

pub const DialogueSystem = struct 
{
    allocator: std.mem.Allocator,
    gc: *graphics.NeonVkContext,
    papyrusImage: *PapyrusImageSubsystem = undefined,
    speaker1ImageHandle: core.ObjectHandle = undefined,
    speaker2ImageHandle: core.ObjectHandle = undefined,
    speechWindow: bool = false,
    fadeTime: f32 = 0,
    fadeDuration: f32 = 0.33,
    fadeOut: bool = false,
    text: []const u8 = "test text",
    textDisplayBuffer: [4096]u8 = std.mem.zeroes([4096]u8),
    displaySlice: []const u8 = "",
    currentTextSlice: usize = 9,
    textTime: f32 = 0.03,
    speakerName: []const u8 = "denver",
    timeSinceLast: f32 = 0.0,

    speaker1BasePos: f32 = 0.691,
    speaker1Offset: f32 = 0,

    pub fn init(allocator: std.mem.Allocator, gc: *graphics.NeonVkContext) @This()
    {
        var self = DialogueSystem{
            .allocator = allocator,
            .gc = gc,
        };

        return self;
    }

    pub fn setup(self: *@This(), papyrusImage: *PapyrusImageSubsystem) !void
    {
        self.papyrusImage = papyrusImage;

        self.speaker1ImageHandle = self.papyrusImage.newDisplayImage(
            core.MakeName("t_salina_big"),
            .{ .x = 0.4, .y = 0.9 }, // by default it's anchored from the top left
            null, //default size
        );
        self.papyrusImage.setImagePosition(self.speaker1ImageHandle, .{ .x = 0.691, .y = 1.252 });
        self.papyrusImage.setImageScale(self.speaker1ImageHandle, .{.x = -0.416, .y = 0.416});
        self.papyrusImage.setAlpha(self.speaker1ImageHandle, 0);


        self.speaker2ImageHandle = self.papyrusImage.newDisplayImage(
            core.MakeName("t_salina_big"),
            .{ .x = 0.4, .y = 0.9 }, // by default it's anchored from the top left
            null, //default size
        );
        self.papyrusImage.setImagePosition(self.speaker2ImageHandle, .{ .x = 0.691, .y = 1.252 });
        self.papyrusImage.setImageScale(self.speaker2ImageHandle, .{.x = -0.416, .y = 0.416});
        self.papyrusImage.setAlpha(self.speaker2ImageHandle, 0);
    }

    pub fn startDialogue(self: *@This(), speakerIconName: ?core.Name, speakerName: ?[]const u8, text: []const u8) void
    {
        self.text = text;
        if(speakerName) |speaker|
        {
            self.speakerName = speaker;
        }

        if(speakerIconName != null)
        {
            self.papyrusImage.setNewImageUseDefaults(self.speaker1ImageHandle, speakerIconName.?);
            self.textDisplayBuffer = std.mem.zeroes(@TypeOf(self.textDisplayBuffer));
        }
        self.timeSinceLast = 0;
        self.currentTextSlice = 0;
        self.showDialogue();
    }

    pub fn showDialogue(self: *@This()) void 
    {
        self.speechWindow = true;
        self.fadeTime = 0;
        self.speaker1Offset = -0.3;
        if(!self.fadeOut)
        {
            self.papyrusImage.setAlpha(self.speaker1ImageHandle, 0);
        }
        self.fadeOut = false;
    }

    pub fn hideDialogue(self: *@This()) void 
    {
        self.speechWindow = false;
        self.fadeOut = true;
    }

    // must be called from a ui context
    pub fn uiTick(self: *@This(), deltaTime: f64) void 
    {
        if(self.fadeTime > 0)
        {
            _ = c.igSetNextWindowPos(.{ .x = @intToFloat(f32, self.gc.actual_extent.width) * 0.1, .y = @intToFloat(f32, self.gc.actual_extent.height) * 0.8 }, 0, .{ .x = 0, .y = 0 });
            _ = c.igSetNextWindowSize(.{ .x = @intToFloat(f32, self.gc.actual_extent.width) * 0.8, .y = @intToFloat(f32, self.gc.actual_extent.height) * 0.2 }, 0);
            _ = c.igBegin(self.speakerName.ptr, null, c.ImGuiWindowFlags_NoMove |
                c.ImGuiWindowFlags_NoCollapse |
                c.ImGuiWindowFlags_NoResize |
                c.ImGuiWindowFlags_NoNav |
                c.ImGuiWindowFlags_NoScrollbar 
                //| c.ImGuiWindowFlags_NoTitleBar
            );
            _ = c.igText(self.displaySlice.ptr);
            _ = c.igEnd();
        }

        _ = deltaTime;
    }

    pub fn tick(self: *@This(), deltaTime: f64) void
    {
        var dt = @floatCast(f32, deltaTime);
        if(self.speechWindow and self.fadeTime < self.fadeDuration and !self.fadeOut)
        {
            self.fadeTime += dt;
            self.speaker1Offset = -(self.fadeDuration - self.fadeTime) * 0.3 / self.fadeDuration;
            if(self.fadeTime > self.fadeDuration)
            {
                self.fadeTime = self.fadeDuration;
                self.speaker1Offset = 0;
            }
            self.papyrusImage.setImagePosition(self.speaker1ImageHandle, .{ .x = self.speaker1BasePos + self.speaker1Offset, .y = 1.252 });
            self.papyrusImage.setAlpha(self.speaker1ImageHandle, self.fadeTime/self.fadeDuration);
        }

        if(self.fadeOut and self.fadeTime > 0)
        {
            if(self.fadeTime > self.fadeDuration)
            {
                self.fadeTime = self.fadeDuration;
            }
            self.fadeTime -= dt;
            if(self.fadeTime < 0.0)
            {
                self.fadeTime = 0;
            }
            self.papyrusImage.setAlpha(self.speaker1ImageHandle, self.fadeTime/self.fadeDuration);
        }

        if(self.fadeTime >= self.fadeDuration)
        {
            self.fadeTime += dt;
        }

        if(self.fadeTime >= (self.fadeDuration + 0.2 ) and self.speechWindow and self.currentTextSlice < self.text.len)
        {
            self.timeSinceLast += dt;
            if(self.timeSinceLast > self.textTime)
            {
                self.timeSinceLast = 0;
                self.currentTextSlice += 1;
                self.displaySlice = std.fmt.bufPrint(self.textDisplayBuffer[0..], "{s}", .{self.text[0..self.currentTextSlice]}) catch unreachable;
            }
        }
    }

    pub fn deinit(self: *@This()) void 
    {
        _ = self;
    }
};