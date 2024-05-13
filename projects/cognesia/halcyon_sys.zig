const std = @import("std");
const root = @import("root");

const nw = root.neonwood;
const core = nw.core;
const dialogue = root.dialogue;
const audio = nw.audio;

pub const halcyon = @import("zig-halcyon/halcyon.zig");

//const story_src: []const u8 = undefined;//@embedFile("story.halc");

pub const HalcyonSys = struct {

    story: halcyon.StoryNodes,
    storyLoaded: bool = false,
    allocator: std.mem.Allocator,
    dialogue: *dialogue.DialogueSystem,
    interactor: ?halcyon.Interactor,
    speakerImage0: core.Name = core.MakeName("t_denver_big"),
    speakerImage1: core.Name = core.MakeName("t_denver_big"),
    choices: std.ArrayListUnmanaged([]const u8),
    tags: std.ArrayList([]const u8),
    parserErrors: *halcyon.ParserErrorContext,
    intBlackBoard: std.AutoHashMapUnmanaged(u32, u32),

    pub fn setSpeaker(self: *@This(), params: []const u8) void 
    {
        var toks = std.mem.tokenize(u8, params, " ");
        var speakerId: []const u8 = "";
        var speakerRef: []const u8 = "";

        var argsCount: usize = 0;
        while(toks.next()) |tok|
        {
            switch (argsCount)
            {
                0 => {
                    speakerId = tok;
                },
                1 => {
                    speakerRef = tok;
                },
                else => {
                    core.engine_errs("setSpeaker called with an invalid number of arguments > 3");
                    unreachable;
                }
            }
            core.engine_log("{s}", .{tok});
            argsCount += 1;
        }

        if(argsCount < 2)
        {
            core.engine_errs("setSpeaker called with an invalid number of arguments < 2");
        }


        if(speakerId[0] == '0')
        {
            core.engine_log("setting speaker1: {s}", .{params});
            self.speakerImage0 = core.Name.fromUtf8(speakerRef);
            return;
        }
        if(speakerId[1] == '1')
        {
            core.engine_log("setting speaker1: {s}", .{params});
            self.speakerImage1 = core.Name.fromUtf8(speakerRef);
            return;
        }
        else 
        {
            core.engine_log("setting speaker: {s}??", .{params});
        }
    }

    pub fn setTextSpeed(self: *@This(), params: []const u8) void 
    {
        _ = self;
        var float: f32 = std.fmt.parseFloat(f32, params) catch 0;
        float = core.clamp(float, 0.03, 1.0);

        if(float > 0.3)
        {
            root.gGame.dialogueSys.talkBlipCount = 0;
        }
        else if(float > 0.1)
        {
            root.gGame.dialogueSys.talkBlipCount = 1;
        }
        else
        {
            root.gGame.dialogueSys.talkBlipCount = 2;
        }
        
        root.gGame.dialogueSys.textTime = float;
    }

    pub fn hideMesh(_: @This(), params: []const u8) void
    {
        var index: usize= std.fmt.parseInt(usize, params, 10) catch 0;
        if(index < root.gGame.sceneMeshes.items.len)
        {
            core.engine_log("{d} {any}", .{root.gGame.sceneMeshes.items.len, root.gGame.sceneMeshes.items[index],});
            root.gGame.gc.setObjectVisibility(root.gGame.sceneMeshes.items[index], false);
            root.gGame.currentSceneVisibilities.items[index] = false;
        }
    }

    pub fn showMesh(_: @This(), params: []const u8) void
    {
        var index: usize= std.fmt.parseInt(usize, params, 10) catch 0;
        if(index < root.gGame.sceneMeshes.items.len)
        {
            root.gGame.gc.setObjectVisibility(root.gGame.sceneMeshes.items[index], true);
            root.gGame.currentSceneVisibilities.items[index] = true;
        }
    }

    pub fn jumpIf(self: *@This(), params: []const u8) void {
        var toks = std.mem.tokenize(u8, params, " ");
        var argsCount: usize = 0;
        var jumpTo: []const u8 = "@__STORY_END__";
        var condition: []const u8 = undefined;
        core.engine_log("jumpif: `{s}`", .{params});
        while(toks.next()) |tok|
        {
            switch (argsCount)
            {
                0 => {
                    condition = tok;
                },
                1 => {
                    jumpTo = tok;
                },
                else => {
                    core.engine_errs("jumpif is messed up");
                    unreachable;
                }
            }
            core.engine_log("jumpif {s}", .{tok});
            argsCount += 1;
        }

        core.engine_log("checking condition = {any} @0x{x}", .{condition, @ptrToInt(&self.intBlackBoard)});
        var iter = self.intBlackBoard.iterator();
        while(iter.next()) |i|
        {
            core.engine_log("key = {any}", .{i.key_ptr.*});
            core.engine_log("condition = {any}", .{i.key_ptr.*});
        }

        var conditionName = core.Name.fromUtf8(condition);
        core.engine_log("conditionName = {d} self = @x{x} count = {d}", .{conditionName.hash, @ptrToInt(self), self.intBlackBoard.count()});

        if(self.intBlackBoard.get(conditionName.hash)) |value|
        {
            if(value > 0) 
            {
                core.engine_log("jumping to {s} {s}", .{condition, jumpTo});
                var node = self.story.tags.get(jumpTo) orelse {
                    core.engine_err("unable to jump to tag {s}", .{jumpTo});
                    return;
                };
                self.interactor.?.node = node;
                self.interactor.?.retryNode = true;
            }
            else
            {
                core.engine_log("not jumping, {s} <= 0", .{condition});
            }
        }
        else 
        {
            core.engine_log("not jumping, {any} not in blackboard 0x{x} count = {d}", .{conditionName, @ptrToInt(self), self.intBlackBoard.count()});
        }
    }

    pub fn setGameInt(self: *@This(), params: []const u8) void 
    {
        var toks = std.mem.tokenize(u8, params, " ");
        var arg: []const u8 = "";
        var value: u32 = 0;

        var argsCount: usize = 0;
        while(toks.next()) |tok|
        {
            switch (argsCount)
            {
                0 => {
                    arg = tok;
                },
                1 => {
                    value = std.fmt.parseInt(u32, tok, 10) catch return;
                },
                else => {
                    core.engine_errs("setSpeaker called with an invalid number of arguments > 3");
                    unreachable;
                }
            }
            argsCount += 1;
        }
        core.engine_log("set game integer: {s}: {d}", .{params, value});

        core.engine_log("conditionName = {d} self = @x{x}", .{core.Name.fromUtf8(arg).hash, @ptrToInt(self)});
        self.intBlackBoard.put(self.allocator, core.Name.fromUtf8(arg).hash, value) catch unreachable;

        //var r = self.intBlackBoard.getOrPut(arg) catch unreachable;
        //r.value_ptr.* = value;
    }

    pub fn playSound(self: *@This(), params: []const u8) void 
    {
        _ = self;
        //core.engine_log("playing sound: `{s}` `{any}` `{any}`", .{params, core.Name.fromUtf8(params), core.MakeName("s_coffee_made")});

        audio.gSoundEngine.playSound(core.Name.fromUtf8(params)) catch {
            audio.sound_err("unable to play sound {s}", .{params});
        };
    }

    pub fn stopSound(self: *@This(), params: []const u8) void 
    {
        _ = self;
        //core.engine_log("playing sound: `{s}` `{any}` `{any}`", .{params, core.Name.fromUtf8(params), core.MakeName("s_coffee_made")});

        audio.gSoundEngine.stopSound(core.Name.fromUtf8(params));
    }

    pub fn shakeScreen(self: *@This(), params: []const u8) void 
    {
        _ = self;
        core.engine_log("playing shaking screen: {s}", .{params});
        root.gGame.doShakeScreen();
    }

    pub fn fadeIn(_: *@This(), _: []const u8) void
    {
        root.gGame.fadeIn();
    }

    pub fn fadeOut(_: *@This(), _: []const u8) void 
    {
        root.gGame.fadeOut();
    }

    pub fn sortTags(_: *@This(), lhs: []const u8, rhs: []const u8) bool
    {
        if(lhs.len == 0)
            return true;
        if(rhs.len == 0)
            return false;
        return lhs[0] < rhs[0];
    }

    pub fn init(allocator: std.mem.Allocator) @This()
    {
        return .{
            .choices = .{},
            .story = undefined,
            .allocator = allocator,
            .dialogue = undefined,
            .interactor = null,
            .parserErrors = undefined,
            .tags = std.ArrayList([]const u8).init(allocator),
            .intBlackBoard = std.AutoHashMapUnmanaged(u32, u32){},
        };
    }

    pub fn deinit(self: @This()) void 
    {
        if(self.interactor == null)
        {
            self.interactor.?.deinit();
        }
    }

    pub fn showPage(self: *@This(), pageName: []const u8) void
    {
        _ = self;
        root.gGame.screenEffects.showPage(core.Name.fromUtf8(pageName));
    }

    pub fn unloadStory(self: *@This()) void
    {
        if(self.storyLoaded)
        {
            self.story.deinit();
            self.storyLoaded = false;
            for(self.tags.items) |tag|
            {
                self.allocator.free(tag);
            }
            self.tags.clearRetainingCapacity();
            self.intBlackBoard.deinit(self.allocator);
            self.intBlackBoard = .{};
        }
    }

    pub fn loadStory(self: *@This(), storyPath: []const u8) !void
    {
        var z = core.tracy.ZoneNC(@src(), "Halcyon Compile story", 0xAAFFFF);
        defer z.End();
        self.forceEndDialogue();
        core.assert(self.interactor == null);
        self.unloadStory();
        var z1 = core.tracy.ZoneNC(@src(), "Halcyon Load File", 0xAAFFFF);
        // parser.tokenStream.test_display();
        var story_src = try core.loadFileAlloc(storyPath, 1, self.allocator);
        z1.End();
        // core.engine_log("{s}", .{story_src});
        core.assert(self.storyLoaded == false);

        var parser = halcyon.NodeParser.init(self.allocator);
        defer parser.deinit();
        errdefer parser.story.deinit();


        var z2 = core.tracy.ZoneNC(@src(), "Halcyon Tokenize", 0xAAFFFF);
        try parser.loadSource(story_src, storyPath);
        z2.End();
        //parser.tokenStream.test_display();

        try parser.installDirective("setSpeaker", self, "setSpeaker");
        try parser.installDirective("setGameInt", self, "setGameInt");
        try parser.installDirective("playSound", self, "playSound");
        try parser.installDirective("stopSound", self, "stopSound");
        try parser.installDirective("blackOut", self, "blackOut");
        try parser.installDirective("lightsOn", self, "lightsOn");
        try parser.installDirective("shakeScreen", self, "shakeScreen");
        try parser.installDirective("changeRooms", self, "changeRooms");
        try parser.installDirective("inHallway", self, "inHallway");
        try parser.installDirective("notInHallway", self, "notInHallway");
        try parser.installDirective("jumpIf", self, "jumpIf");
        try parser.installDirective("setMovementEnabled", self, "setMovementEnabled");
        try parser.installDirective("setPlayerVisible", self, "setPlayerVisible");
        try parser.installDirective("setTextSpeed", self, "setTextSpeed");
        try parser.installDirective("hideMesh", self, "hideMesh");
        try parser.installDirective("showMesh", self, "showMesh");
        try parser.installDirective("showPage", self, "showPage");
        try parser.installDirective("startEndGame", self, "startEndGame");

        var z3 = core.tracy.ZoneNC(@src(), "Halcyon Parse and Compile", 0xAAFFFF);
        const tstart = core.getEngineTimeStamp();
        var story = parser.parseAll() catch |e| {
            core.engine_errs("Unable to parse file, some parser error happened");
            return e;
        };
        const tend = core.getEngineTimeStamp();
        core.engine_log("Halcyon {d} nodes parsed in {d} us", .{story.instances.items.len, @intToFloat(f32, tend - tstart)/1000.0});
        z3.End();

        self.storyLoaded = true;
        self.story = story;
        var iterator = self.story.tags.iterator();
        while(iterator.next()) |iter|
        {
            var fmtprint = try std.fmt.allocPrintZ(self.allocator, "{s}", .{iter.key_ptr.*});
            try self.tags.append(fmtprint);
        }

        std.sort.sort([]const u8, self.tags.items, self, @This().sortTags);
    }

    pub fn prepare(self: *@This(), dialogueSystem: *dialogue.DialogueSystem) !void 
    {
        self.dialogue = dialogueSystem;
        self.parserErrors = try self.allocator.create(halcyon.ParserErrorContext);
        self.parserErrors.* = halcyon.ParserErrorContext.init(self.allocator);
        self.loadStory("content/story.halc") catch {

        };
    }

    pub fn nextNode(self: *@This()) void
    {
        _ = self;
    }
    
    pub fn forceEndDialogue(self: *@This()) void
    {
        if(self.interactor == null)
            return;

        
        self.interactor.?.node = .{};

        self.postProgress();
    }

    pub fn blackOut(_: *@This(), _: []const u8) void
    {
        root.gGame.screenEffects.setVignetteStrength(1.0);
    }

    pub fn lightsOn(_: *@This(), _: []const u8) void
    {
        root.gGame.screenEffects.setVignetteStrength(0);
    }

    pub fn startEndGame(_: *@This(), _: []const u8) void 
    {
        root.gGame.screenEffects.startEndGame();
    }

    pub fn changeRooms(self: *@This(), params: []const u8) void
    {
        var toks = std.mem.tokenize(u8, params, " ");
        
        var argCount: usize = 0;
        var positionSelect: usize = 0;
        var room: []const u8 = "";

        while(toks.next()) |arg|
        {
            switch(argCount)
            {
                0 =>{
                    positionSelect = std.fmt.parseInt(usize, arg, 10) catch 0;
                },
                1 =>{
                    room = arg;
                },
                else => unreachable,
            }

            argCount += 1;
        }
        var x = std.fmt.allocPrint(self.allocator, "{s}.json", .{room}) catch unreachable;
        defer self.allocator.free(x);
        core.engine_log("{s} {d} {s}", .{params, positionSelect, x});
        root.gGame.loadStageFromFile(x, positionSelect) catch unreachable;
    }

    pub fn setPlayerVisible(_: *@This(), params: []const u8) void
    {
        if(params[0] == '0')
        {
            root.gGame.setPlayerVisible(false);
        }
        if(params[0] == '1')
        {
            root.gGame.setPlayerVisible(true);
        }
    }

    pub fn setMovementEnabled(_: *@This(), params: []const u8) void
    {
        if(params[0] == '0')
        {
            root.gGame.setMovementEnabled(false);
        }
        if(params[0] == '1')
        {
            root.gGame.setMovementEnabled(true);
        }
    }

    pub fn inHallway(_: *@This(), _: []const u8) void 
    {
        root.gGame.bInHallway = true;
    }

    pub fn notInHallway(_: *@This(), _: []const u8) void 
    {
        root.gGame.bInHallway = false;
    }

    pub fn startDialogue(self: *@This(), tag:[]const u8) void 
    {
        if(!self.storyLoaded)
        {
            core.engine_log("Unable to start dialogue, story is not loaded.", .{});
            return;
        }

        core.engine_log("starting dialogue with tag: {s}", .{tag});
        if(!self.story.tags.contains(tag))
        {
            core.engine_err("Unable to load tag {s} using BAD_NODE instead", .{tag});
            self.startDialogue("BAD_NODE");
            return;
        }
        // self.dialogue.start();

        if(self.interactor != null)
        {
            self.interactor.?.deinit();
            self.interactor = null;
        }
        
        self.interactor = halcyon.Interactor.startInteraction(&self.story, tag, self.allocator);
        self.interactor.?.displayCurrentContent();
        self.interactor.?.resolve() catch {
            core.engine_errs("Interactor was unable to resolve it's state, ending interaction", .{});
            self.interactor.?.deinit();
            self.interactor = null;
            return;
        };

        self.postProgress();
    }

    pub fn postProgress(self: *@This()) void 
    {
        if(self.interactor.?.isFinished())
        {
            self.dialogue.startDialogue(
                null,
                null,
                "story has been reloaded",
            );

            self.dialogue.hideDialogue();
            self.interactor.?.deinit();
            self.interactor = null;
            return;
        }

        var story = self.interactor.?.story;
        self.dialogue.choices.choices.clearRetainingCapacity();
        self.dialogue.choices.active_choice = 0;
        if(story.choices.get(self.interactor.?.node)) |choices|
        {
            for(choices.items) |choice|
            {
                var storyText = story.getStoryUtf8(choice);
                self.choices.append(self.allocator, storyText) catch unreachable;
            }
            self.dialogue.choices.setChoices(self.choices.items) catch unreachable;
        }

        // if this is just a normal text then just start the next dialogue
        self.dialogue.startDialogue(
            self.speakerImage0,
            self.story.getSpeakerName(self.interactor.?.node),
            self.story.getStoryUtf8(self.interactor.?.node),
        );

    }

    pub fn progress(self: *@This(), selection: ?usize) void
    {
        if(!self.dialogue.finishedCurrentDialogue())
        {
            self.dialogue.advanceMultiLine();
            return;
        }

        if(self.interactor == null)
            return;

        if(selection != null)
        {
            self.interactor.?.chooseAndProgress(selection.?);
        }
        else 
        {
            self.interactor.?.proceed() catch unreachable;
        }

        self.interactor.?.displayCurrentContent();
        self.choices.clearRetainingCapacity();
        self.postProgress();
    }
};