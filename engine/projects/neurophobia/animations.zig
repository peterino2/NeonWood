const std = @import("std");
const nw = @import("root").neonwood;
const graphics = nw.graphics;
const audio = nw.audio;
const core = nw.core;

const NeonVkImage = graphics.NeonVkImage;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const PixelPos = graphics.PixelPos;

pub const SpriteFrame = struct {
    topLeft: PixelPos,
    size: PixelPos,
};

pub const SpriteAnimCallbackRegistry = struct {
    callbacks: ArrayListUnmanaged(AnimCallback) = .{},
};

pub const AnimCallback = struct {
    triggerFrame: usize,
    context: *anyopaque,
    callback: fn (*anyopaque) void,
};

pub const SpriteAnimation = struct {
    name: core.Name = core.MakeName(""),
    frameStart: usize = 0,
    frameCount: usize = 0,
    frameTime: f64 = 0.0,

    pub fn getDuration(self: @This()) f64 {
        return self.frameTime * self.frameCount;
    }

    pub fn getSheetFrameIndex(self: @This(), animFrameIndex: usize) usize {
        core.assert(animFrameIndex < self.frameCount);
        return self.frameStart + animFrameIndex;
    }
};

pub const SpriteAnimationInstance = struct {
    animation: SpriteAnimation = .{},
    callbacks: ?SpriteAnimCallbackRegistry = null,
    currentFrameTime: f64 = 0.0,
    currentAnimFrameIndex: usize = 0,
    playSpeed: f64 = 1.0,
    looping: bool = false,
    playing: bool = false,
    reverse: bool = false,

    pub fn getCurrentFrame(self: @This()) usize {
        return self.animation.getSheetFrameIndex(self.currentAnimFrameIndex);
    }

    pub fn advance(self: *@This(), deltaTime: f64) void {
        const animation: SpriteAnimation = self.animation;
        self.currentFrameTime += deltaTime * self.playSpeed;

        if (self.currentFrameTime > animation.frameTime) {
            self.currentFrameTime = 0.0;
            self.currentAnimFrameIndex += 1;

            if (self.callbacks) |callbacks| {
                for (callbacks.callbacks.items) |callback| {
                    if (callback.triggerFrame == self.currentAnimFrameIndex) {
                        callback.callback(callback.context);
                    }
                }
            }

            if (!self.looping and self.currentAnimFrameIndex == animation.frameCount) {
                self.playing = false;
            }

            self.currentAnimFrameIndex %= animation.frameCount;
        }
    }
};

const SoundEventWrap = struct {
    soundName: core.Name,

    pub fn exec(ptr: *anyopaque) void
    {
        var this = @ptrCast(*@This(), @alignCast(@alignOf(@This()), ptr));
        audio.gSoundEngine.playSound(this.soundName);
    }
};

pub const SpriteSheet = struct {
    image: *const NeonVkImage,
    frames: ArrayListUnmanaged(SpriteFrame),
    animations: std.AutoHashMapUnmanaged(u32, SpriteAnimation),
    animationCallbacks: std.AutoHashMapUnmanaged(u32, SpriteAnimCallbackRegistry) = .{},
    soundEvents: ArrayListUnmanaged(*SoundEventWrap) = .{},

    pub fn init(image: *const NeonVkImage) @This() {
        var self = @This(){
            .image = image,
            .animations = .{},
            .frames = .{},
        };

        return self;
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.frames.deinit(allocator);
    }

    pub fn addSoundEvent(
        self: *@This(),
        allocator: std.mem.Allocator,
        animationName: core.Name,
        triggerFrame: usize,
        soundName: core.Name,
    ) !void {
        var soundEvent = try allocator.create(SoundEventWrap);
        soundEvent.* = .{.soundName = soundName};
        try self.soundEvents.append(allocator, soundEvent);

        try self.addAnimationCallback(allocator, animationName, triggerFrame, SoundEventWrap.exec, soundEvent);
    }

    pub fn addAnimationCallback(
        self: *@This(),
        allocator: std.mem.Allocator,
        animationName: core.Name,
        triggerFrame: usize,
        func: fn (*anyopaque) void,
        context: *anyopaque,
    ) !void {
        if(!self.animationCallbacks.contains(animationName.hash))
        {
            try self.animationCallbacks.put(
                allocator,
                animationName.hash,
                SpriteAnimCallbackRegistry{},
            );
            //AnimCallback{ .callback = func, .context = context, .triggerFrame = triggerFrame },
        }
        var v = self.animationCallbacks.getEntry(animationName.hash).?;
        try v.value_ptr.*.callbacks.append(allocator, AnimCallback{ .callback = func, .context = context, .triggerFrame = triggerFrame });
    }

    pub fn createAnimationInstance(self: @This(), name: core.Name) ?SpriteAnimationInstance {
        if (self.animations.get(name.hash)) |animation| {
            var rv: SpriteAnimationInstance = .{
                .animation = animation,
                .currentFrameTime = 0.0,
                .currentAnimFrameIndex = 0,
            };

            if (self.animationCallbacks.get(name.hash)) |entry| {
                rv.callbacks = entry;
            }

            return rv;
        }

        return null;
    }

    pub fn addRangeBasedAnimation(
        self: *@This(),
        allocator: std.mem.Allocator,
        animationName: core.Name,
        frameStart: usize,
        frameCount: usize,
        frameRate: f64,
    ) !void {
        var animation = SpriteAnimation{
            .name = animationName,
            .frameStart = frameStart,
            .frameCount = frameCount,
            .frameTime = 1 / frameRate,
        };

        try self.animations.put(allocator, animationName.hash, animation);
    }

    pub fn generateSpriteFrames(
        self: *@This(),
        allocator: std.mem.Allocator,
        frameSize: PixelPos,
    ) !void {
        var currentY: u32 = 0;
        var currentX: u32 = 0;
        var sheetWidth = self.image.pixelWidth;

        while (currentX < sheetWidth) {
            try self.addFrame(allocator, .{
                .topLeft = .{ .x = currentX, .y = currentY },
                .size = frameSize,
            });
            currentX += frameSize.x;
        }
    }

    pub fn getScale(self: @This()) core.Vectorf {
        return core.Vectorf{ .x = 3.4 / self.frames.items[0].size.ratio(), .y = 3.4, .z = 3.4 };
    }

    pub fn getXFrameScaling(self: @This(), scale: f32) core.zm.Mat {
        if (self.frames.items.len == 0) {
            return core.zm.scaling(scale, scale, scale);
        }

        return core.zm.scaling(scale / self.frames.items[0].size.ratio(), scale, scale);
    }

    pub fn addFrame(self: *@This(), allocator: std.mem.Allocator, frame: SpriteFrame) !void {
        try self.frames.append(allocator, frame);
    }

    pub fn getDimensions(self: @This()) PixelPos {
        return .{
            .x = self.image.pixelWidth,
            .y = self.image.pixelHeight,
        };
    }
};
