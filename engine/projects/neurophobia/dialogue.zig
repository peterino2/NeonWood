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

pub const DialogueChoice = struct {
    text: []const u8,
};

pub const MultipleChoiceUi = struct 
{
    allocator: std.mem.Allocator,
    choices: std.ArrayListUnmanaged(DialogueChoice) = .{},
    active_choice: usize = 0,
    active: bool = false,

    pub fn init(allocator: std.mem.Allocator) @This()
    {
        return .{
            .allocator = allocator,
        };
    }

    pub fn setChoices(self: *@This(), choices: []const []const u8) !void 
    {
        self.choices.clearRetainingCapacity();
        for(choices) |choice|
        {
            try self.choices.append(self.allocator, 
                .{
                    .text = choice,
                }
            );
        }
    }

    pub fn cursorUp(self: *@This()) void 
    {
        if(self.choices.items.len < 1)
            return;

        if(self.active_choice > 0 and self.active)
        {
            audio.gSoundEngine.playSound(core.MakeName("s_menuBlip")) catch unreachable;
            self.active_choice -= 1;
        }
    }

    pub fn cursorDown(self: *@This()) void 
    {
        if(self.choices.items.len < 1)
            return;
        
        if(self.active_choice < self.choices.items.len - 1 and self.active)
        {
            audio.gSoundEngine.playSound(core.MakeName("s_menuBlip")) catch unreachable;
            self.active_choice += 1;
        }
    }

    pub fn display(self: *@This(), gc: *graphics.NeonVkContext) void 
    {
        _ = c.igSetNextWindowPos(
            .{ .x = @intToFloat(f32, gc.actual_extent.width) * 0.5, .y = @intToFloat(f32, gc.actual_extent.height) * 0.6 }, 0, .{ .x = 0, .y = 0 }
        );

        _ = c.igSetNextWindowSize(
            .{ .x = @intToFloat(f32, gc.actual_extent.width) * 0.4, .y = @intToFloat(f32, gc.actual_extent.height) * 0.2 }, 0
        );

        _ = c.igBegin("huh", null, c.ImGuiWindowFlags_NoMove |
            c.ImGuiWindowFlags_NoCollapse |
            c.ImGuiWindowFlags_NoResize |
            c.ImGuiWindowFlags_NoNav |
            c.ImGuiWindowFlags_NoScrollbar |
            c.ImGuiWindowFlags_NoTitleBar
        );

        for(self.choices.items) |choice, i|
        {
            if(self.active_choice == i)
            {
                _ = c.igTextColored(.{.x = 1.0, .y = 1.0, .z = 0.0, .w = 1.0}, choice.text.ptr);
            }
            else 
            {

                _ = c.igText(choice.text.ptr);
            }
        }
        _ = c.igEnd();
    }
};

pub const DialogueSystem = struct 
{
    allocator: std.mem.Allocator,
    gc: *graphics.NeonVkContext,
    papyrusImage: *PapyrusImageSubsystem = undefined,
    speaker1ImageHandle: core.ObjectHandle = undefined,
    speaker2ImageHandle: core.ObjectHandle = undefined,
    choices: MultipleChoiceUi,
    speechWindow: bool = false,
    fadeTime: f32 = 0,
    fadeDuration: f32 = 0.33,
    fadeOut: bool = false,
    text: []const u8 = "test text",
    textDisplayBuffer: [4096]u8 = std.mem.zeroes([4096]u8),
    displaySlice: []const u8 = "",
    textTime: f32 = 0.03,
    speakerName: []const u8 = "denver",
    timeSinceLast: f32 = 0.0,

    speaker1BasePos: f32 = 0.691,
    speaker1Offset: f32 = 0,

    slice_start:usize = 0,
    slice_end:usize = 0,
    slice_id:usize = 0,
    currentTextSlice: usize = 9,
    textBuffer: std.ArrayListUnmanaged(u8) = .{},
    textBufferOffsets: std.ArrayListUnmanaged(usize) = .{},
    charsSinceBlipCount: usize = 0,
    talkBlipCount: usize = 2,

    dialogueIsHidden: bool = false,

    input: core.Vectorf = core.Vectorf.zero(),
    inputCache: core.Vectorf = core.Vectorf.zero(),

    pub fn init(allocator: std.mem.Allocator, gc: *graphics.NeonVkContext) @This()
    {
        var self = DialogueSystem{
            .allocator = allocator,
            .gc = gc,
            .choices = MultipleChoiceUi.init(allocator),
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

        try self.choices.setChoices(&.{
            "make some coffee",
            "dont make some coffee",
            "exit",
        });
        self.choices.active_choice = 1;
    }

    pub fn process_text(self: *@This(), text: []const u8) void 
    {
        self.text = text;
        self.slice_start = 0;
        self.slice_id = 0;
        self.slice_end = text.len;
        var tok = std.mem.tokenize(u8, text, &.{0});
        self.textBuffer.clearRetainingCapacity();
        self.textBufferOffsets.clearRetainingCapacity();

        while(tok.next()) |t|
        {
            self.textBuffer.appendSlice(self.allocator, t) catch unreachable;
            self.textBufferOffsets.append(self.allocator, t.len) catch unreachable;
        }

        self.slice_end = self.textBufferOffsets.items[0] + 1;
    }

    pub fn startDialogue(self: *@This(), speakerIconName: ?core.Name, speakerName: ?[]const u8, text: []const u8) void
    {
        self.process_text(text);
        self.choices.active = false;

        if(speakerName) |speaker|
        {
            self.speakerName = speaker;
        }
        else 
        {
            self.speakerName = " ";
        }
        self.showDialogue();

        if(speakerIconName != null)
        {
            //core.engine_log("loading icon: {s}", .{speakerIconName.?.utf8});
            self.papyrusImage.setNewImageUseDefaults(self.speaker1ImageHandle, speakerIconName.?);
            self.textDisplayBuffer = std.mem.zeroes(@TypeOf(self.textDisplayBuffer));
        }

        if(speakerName == null)
        {
            self.hideSpeaker();
        }
        else 
        {
            self.showSpeaker();
        }
        self.timeSinceLast = 0;
        self.currentTextSlice = 0;
    }

    pub fn showDialogue(self: *@This()) void 
    {
        if(self.speechWindow == false)
        {
            self.speechWindow = true;
            self.fadeTime = 0;
            self.speaker1Offset = -0.3;

            if(!self.fadeOut)
            {
                self.papyrusImage.setAlpha(self.speaker1ImageHandle, 0);
            }
        }
        self.fadeOut = false;
    }

    pub fn hideSpeaker(self: *@This()) void
    {
        self.fadeOut = true;
        self.speechWindow = true;
    }
    
    pub fn showSpeaker(self: *@This()) void
    {
        if(self.fadeOut == true)
        {
            self.fadeOut = false;
            self.fadeTime = 0;
            self.speaker1Offset = -0.3;
        }
    }

    pub fn hideDialogue(self: *@This()) void 
    {
        self.speechWindow = false;
        self.fadeOut = true;
    }

    // must be called from a ui context
    pub fn uiTick(self: *@This(), deltaTime: f64) void 
    {
        if(self.dialogueIsHidden)
            return;

        if(self.speechWindow or self.fadeTime > 0)
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

            if (self.choices.active)
            {
                self.choices.display(self.gc);
            }
        }

        _ = deltaTime;
    }

    pub fn tick(self: *@This(), deltaTime: f64) void
    {
        if(self.dialogueIsHidden)
        {
            self.papyrusImage.setAlpha(self.speaker1ImageHandle, 0);
            self.fadeTime = self.fadeDuration;
            return;
        }
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
            if(self.choices.choices.items.len > 0)
            {
                self.choices.active = true;
            }
        }

        if(self.speechWindow and self.fadeOut)
        {
            if(self.choices.choices.items.len > 0)
            {
                self.choices.active = true;
            }
        }

        self.handleIncrementalPrint(dt);
    }

    pub fn handleIncrementalPrint(self: *@This(), dt: f32) void
    {
        if((self.fadeTime >= (self.fadeDuration + 0.2 ) or self.fadeOut ) and self.speechWindow and self.currentTextSlice < self.slice_end)
        {
            self.timeSinceLast += dt;
            if(self.timeSinceLast > self.textTime)
            {
                self.timeSinceLast = 0;
                self.currentTextSlice += 1;
                self.displaySlice = std.fmt.bufPrint(self.textDisplayBuffer[0..], "{s}", .{self.text[self.slice_start..self.currentTextSlice]}) catch unreachable;

                self.charsSinceBlipCount += 1;

                if(self.charsSinceBlipCount > self.talkBlipCount)
                {
                    audio.gSoundEngine.playSound(core.MakeName("s_talk")) catch unreachable;
                    self.charsSinceBlipCount = 0;
                }
            }
        }
    }

    pub fn finishedCurrentDialogue(self: *@This()) bool
    {
        return (self.currentTextSlice == self.text.len);
    }

    pub fn advanceMultiLine(self: *@This()) void 
    {
        if(self.currentTextSlice != self.slice_end)
        {
            return;
        }

        if(self.slice_id + 1 < self.textBufferOffsets.items.len)
        {
            self.slice_start = self.slice_end + 1;
            self.slice_id += 1;
            self.slice_end += self.textBufferOffsets.items[self.slice_id];
            self.textDisplayBuffer = std.mem.zeroes([4096]u8);
        }
        else 
        {
            self.slice_end = self.text.len;
        }
    }

    pub fn deinit(self: *@This()) void 
    {
        _ = self;
    }
};