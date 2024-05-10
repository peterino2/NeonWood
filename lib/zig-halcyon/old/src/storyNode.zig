const std = @import("std");
const tokenizer = @import("tokenizer.zig");
const fileHandler = @import("fileHandler.zig");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const TokenStream = tokenizer.TokenStream;
const TokenType = tokenizer.TokenStream.TokenType;

pub const storyStartLabel = "@__STORY_START__";
pub const storyEndLabel = "@__STORY_END__";
const assert = std.debug.assert;
const ParserPrint = std.debug.print;

pub const ParserWarningOrError = ParserError || ParserWarning || StoryNodesError;
pub const StoryNodesError = error{ InstancesNotExistError, GeneralError };

const ParserError = error{
    GeneralParserError,
    UnexpectedTokenError,
    NoNextNodeError,
};

const ParserWarning = error{
    DuplicateLabelWarning,
};

pub const Node = struct {
    id: usize = 0,
    generation: u32 = 0,
};

pub const LocKey = struct {
    key: u32,
    keyName: ArrayList(u8),

    const Self = @This();

    // generates a new localization id with a random value (todo)
    pub fn newAutoKey(alloc: std.mem.Allocator) !LocKey {
        return LocKey{ .key = 0, .keyName = ArrayList(u8).init(alloc) };
    }

    pub fn deinit(self: *Self) void {
        self.keyName.deinit();
    }
};

pub const NodeString = struct {
    string: ArrayList(u8),
    locKey: LocKey,

    const Self = @This();

    pub fn initAuto(alloc: std.mem.Allocator) Self {
        return NodeString{
            .string = try ArrayList(u8).init(alloc),
            .locKey = LocKey.newAutoKey(alloc),
        };
    }

    pub fn deinit(self: *Self) void {
        self.string.deinit();
        self.locKey.deinit();
    }

    pub fn setUtf8NativeText(self: *Self, text: []const u8) *Self {
        if (self.string.items.len > 0) {
            try self.string.clearAndFree();
        }
        try self.string.appendSlice(text);
        return self;
    }

    pub fn fromUtf8(text: []const u8, alloc: std.mem.Allocator) !NodeString {
        var rv = NodeString{
            .string = try ArrayList(u8).initCapacity(alloc, text.len),
            .locKey = try LocKey.newAutoKey(alloc),
        };

        _ = try rv.string.appendSlice(text);
        _ = try rv.string.append(0); // null terminated, for C's pleasure
        return rv;
    }

    // returns the native text
    pub fn asUtf8Native(self: Self) ![]const u8 {
        return self.string.items;
    }
};

pub const NodeStringView = []const u8;

pub const BranchNode = struct {};

pub const NodeData = struct {
    node: Node,
    content: union {
        textContent: NodeString,
    },
    passThrough: bool,
};

pub const StoryNodes = struct {
    instances: ArrayList(Node),
    textContent: ArrayList(NodeString),
    passThrough: ArrayList(bool),

    nodes: ArrayList(NodeData),

    speakerName: AutoHashMap(Node, NodeString),
    conditionalBlock: AutoHashMap(Node, BranchNode),
    choices: AutoHashMap(Node, ArrayList(Node)),
    nextNode: AutoHashMap(Node, Node),
    explicitLink: AutoHashMap(Node, void),
    tags: std.StringHashMap(Node),

    const Self = @This();

    pub fn getNullNode(self: Self) Node {
        return self.instances.items[0];
    }

    pub fn init(allocator: std.mem.Allocator) Self {
        // should actually group nextNode, explicitLinks and all future link based data into an enum or struct.
        // that's a pretty important refactor we should do
        var rv = Self{
            .instances = ArrayList(Node).initCapacity(allocator, 0xffff) catch unreachable,
            .textContent = ArrayList(NodeString).initCapacity(allocator, 0xffff) catch unreachable,
            .passThrough = ArrayList(bool).init(allocator),
            .speakerName = AutoHashMap(Node, NodeString).init(allocator),
            .choices = AutoHashMap(Node, ArrayList(Node)).init(allocator),
            .nextNode = AutoHashMap(Node, Node).init(allocator),
            .tags = std.StringHashMap(Node).init(allocator),
            .conditionalBlock = AutoHashMap(Node, BranchNode).init(allocator),
            .explicitLink = AutoHashMap(Node, void).init(allocator),
            .nodes = ArrayList(NodeData).init(allocator),
        };
        var node = rv.newNodeWithContent("@__STORY_END__", allocator) catch unreachable;
        rv.setLabel(node, "@__STORY_END__") catch unreachable;
        return rv;
    }

    pub fn deinit(self: *Self) void {
        self.instances.deinit();
        self.passThrough.deinit();
        self.explicitLink.deinit();
        self.conditionalBlock.deinit();
        {
            var i: usize = 0;
            while (i < self.textContent.items.len) {
                self.textContent.items[i].deinit();
                i += 1;
            }
            self.textContent.deinit();
        }

        {
            var iter = self.speakerName.iterator();
            while (iter.next()) |instance| {
                instance.value_ptr.deinit();
            }
            self.speakerName.deinit();
        }

        {
            var iter = self.choices.iterator();
            var i: usize = 0;
            while (iter.next()) |instance| {
                instance.value_ptr.deinit();
                i += 1;
            }
            self.choices.deinit();
        }

        self.nextNode.deinit();
        self.tags.deinit();
    }

    pub fn newNodeWithContent(self: *Self, content: []const u8, alloc: std.mem.Allocator) !Node {
        var newString = try NodeString.fromUtf8(content, alloc);
        try self.textContent.append(newString);
        var node = Node{
            .id = self.textContent.items.len - 1,
            .generation = 0, // todo..
        };
        try self.instances.append(node);
        try self.passThrough.append(false);

        if (node.id == 1) {
            try self.setLabel(node, storyStartLabel);
        }
        return node;
    }

    fn newDirectiveNodeFromUtf8(self: *Self, source: []const []const u8, alloc: std.mem.Allocator) !Node {
        // you have access to start and end window here.
        var newString = try NodeString.fromUtf8(source[0], alloc);
        var node = Node{ .id = self.instances.items.len, .generation = 0 };
        try self.textContent.append(newString);
        try self.instances.append(node);
        try self.passThrough.append(false);

        return node;
    }

    pub fn setTextContentFromSlice(self: *Self, node: Node, newContent: []const u8) !void {
        if (node.id >= self.textContent.items.len) return StoryNodesError.InstancesNotExistError;
        self.textContent.items[node.id].string.clearAndFree();
        try self.textContent.items[node.id].string.appendSlice(newContent);
    }

    pub fn setLabel(self: *Self, id: Node, label: []const u8) !void {
        //ParserPrint("SettingLabel  {s}!!\n\n", .{label});
        if (self.tags.contains(label)) {
            return ParserWarning.DuplicateLabelWarning;
        }
        try self.tags.put(label, id);
    }

    pub fn findNodeByLabel(self: Self, label: []const u8) ?Node {
        if (self.tags.contains(label)) {
            return self.tags.getEntry(label).?.value_ptr.*;
        } else {
            std.debug.print("!! unable to find label {s}", .{label});
            return null;
        }
    }

    pub fn setLinkByLabel(self: *Self, id: Node, label: []const u8) !Node {
        var next = self.findNodeByLabel(label) orelse return StoryNodesError.InstancesNotExistError;
        try self.nextNode.put(id, next);
        try self.explicitLink.put(id, .{});
        return next;
    }

    pub fn setLink(self: *Self, from: Node, to: Node) !void {
        try self.nextNode.put(from, to);
    }

    pub fn setEnd(self: *Self, node: Node) !void {
        try self.setLink(node, try self.getNodeFromExplicitId(0));
    }

    pub fn getNodeFromExplicitId(self: Self, id: anytype) StoryNodesError!Node {
        if (id < self.instances.items.len) {
            return self.instances.items[id];
        } else {
            return StoryNodesError.InstancesNotExistError;
        }
    }

    pub fn addChoicesBySlice(self: *Self, node: Node, choices: []const Node, alloc: std.mem.Allocator) !void {
        var value = try self.choices.getOrPut(node);
        value.value_ptr.* = try ArrayList(Node).initCapacity(alloc, choices.len);
        try value.value_ptr.appendSlice(choices);
    }

    pub fn addChoiceByNode(self: *Self, node: Node, choice: Node, alloc: std.mem.Allocator) !void {
        if (!self.choices.contains(node)) {
            var value = try self.choices.getOrPut(node);
            value.value_ptr.* = ArrayList(Node).init(alloc);
        }
        {
            var value = try self.choices.getOrPut(node);
            try value.value_ptr.append(choice);
        }
    }

    pub fn addSpeaker(self: *Self, node: Node, speaker: NodeString) !void {
        try self.speakerName.put(node, speaker);
    }

    pub fn getStoryText(self: Self, id: usize) ![]const u8 {
        return self.textContent.items[id].asUtf8Native();
    }

    pub fn getSpeakerName(self: Self, id: usize) ![]const u8 {
        return self.speakerName.items[id].asUtf8Native();
    }
};

pub fn parserPanic(message: []const u8) !void {
    std.debug.print("Parser Error!: {s}", .{message});
}

pub const Interactor = struct {
    story: *const StoryNodes,
    node: Node,
    isRecording: bool,
    history: ArrayList(Node),

    const Self = @This();

    pub fn startRecording(self: *Self) void {
        self.isRecording = true;
    }

    pub fn showHistory(self: Self) void {
        for (self.history.items) |i| {
            std.debug.print("{d} ", .{i.id});
        }
        std.debug.print("\n", .{});
    }

    pub fn init(story: *const StoryNodes, alloc: std.mem.Allocator) Interactor {
        return Interactor{
            .story = story,
            .node = story.findNodeByLabel(storyStartLabel) orelse unreachable,
            .history = ArrayList(Node).init(alloc),
            .isRecording = false,
        };
    }

    pub fn deinit(self: *Self) void {
        self.history.deinit();
    }

    pub fn displayCurrentContent(self: Self) void {
        const str = if (self.story.speakerName.get(self.node)) |speaker| speaker.asUtf8Native() else "narrator";
        std.debug.print("{d}> {!s}: {!s}\n", .{ self.node.id, str, self.story.textContent.items[self.node.id].asUtf8Native() });
    }

    pub fn getCurrentStoryText(self: Self) []const u8 {
        return try self.story.textContent.items[self.node.id].asUtf8Native();
    }

    pub fn getCurrentSpeaker(self: Self) []const u8 {
        const str = if (self.story.speakerName.get(self.node)) |speaker| try speaker.asUtf8Native() else "narrator";
        return str;
    }

    pub fn next(self: *Self) !void {
        var story = self.story;
        if (story.nextNode.contains(self.node)) {
            self.node = story.nextNode.get(self.node).?;
            return;
        } else {
            self.node = Node{ .id = 0 };
            return;
        }
    }

    pub fn iterateChoicesList(self: *Self, iter: []const usize) !void {
        var currentChoiceIndex: usize = 0;
        var story = self.story;

        while (self.node.id > 0) // the zero node is when it is done
        {
            self.displayCurrentContent();
            if (self.isRecording) {
                try self.history.append(self.node);
            }
            if (story.choices.contains(self.node)) {
                self.node = story.choices.get(self.node).?.items[iter[currentChoiceIndex]];
                currentChoiceIndex += 1;
            } else if (story.nextNode.contains(self.node)) {
                self.node = story.nextNode.get(self.node).?;
            }
        }

        if (self.isRecording) {
            try self.history.append(self.node);
        }
    }
};

fn matchFunctionCallGeneric(slice: []const TokenType, data: anytype, functionName: []const u8) bool {
    if (slice.len < 4) return false;

    if (data.len != slice.len) {
        std.debug.print("something is really wrong\n", .{});
        return false;
    }

    if (!std.mem.eql(u8, data[1], functionName)) return false;

    if (slice[0] == TokenType.AT and
        slice[1] == TokenType.LABEL and
        slice[2] == TokenType.L_PAREN and
        slice[slice.len - 1] == TokenType.R_PAREN)
    {
        return true;
    }

    return false;
}

// checks if a sequence of tokens matches the @set(...) directive
fn tokMatchSet(slice: []const TokenType, data: []const []const u8) bool {
    return matchFunctionCallGeneric(slice, data, "set");
}

fn tokMatchEnd(slice: []const TokenType, data: anytype) bool {
    if (slice.len < 2) return false;
    if (slice[0] != TokenType.AT) return false;
    if (slice[1] != TokenType.LABEL) return false;
    if (data.len != slice.len) {
        std.debug.print("something is really wrong\n", .{});
        return false;
    }

    if (!std.mem.eql(u8, data[1], "end")) return false;

    return true;
}

fn tokMatchGoto(slice: []const TokenType, data: anytype) bool {
    if (slice.len < 3) return false;
    if (slice[0] != TokenType.AT) return false;
    if (slice[slice.len - 1] != TokenType.LABEL) return false;
    if (data.len != slice.len) {
        std.debug.print("something is really wrong\n", .{});
        return false;
    }

    if (!std.mem.eql(u8, data[1], "goto")) return false;

    return true;
}

fn tokMatchIf(slice: []const TokenType, data: anytype) bool {
    return matchFunctionCallGeneric(slice, data, "if");
}

fn tokMatchElif(slice: []const TokenType, data: anytype) bool {
    return matchFunctionCallGeneric(slice, data, "elif");
}

fn tokMatchVarsBlock(slice: []const TokenType, data: anytype) bool {
    return matchFunctionCallGeneric(slice, data, "vars");
}

fn tokMatchElse(slice: []const TokenType, data: anytype) bool {
    if (slice.len < 2) return false;

    if (data.len != slice.len) {
        std.debug.print("something is really wrong\n", .{});
        return false;
    }

    if (!std.mem.eql(u8, data[1], "else")) return false;

    if (slice[0] == TokenType.AT and
        slice[1] == TokenType.LABEL)
    {
        return true;
    }

    return false;
}

fn tokMatchGenericDirective(slice: []const TokenType) bool {
    if (slice.len < 4) return false;

    if (slice[0] == TokenType.AT and
        slice[1] == TokenType.LABEL and
        slice[2] == TokenType.L_PAREN and
        slice[slice.len - 1] == TokenType.R_PAREN)
    {
        return true;
    }

    return false;
}

fn tokMatchTabSpace(slice: []const TokenType, data: anytype) bool {
    if (slice.len < 4) return false;
    var i: u32 = 0;
    while (i < slice.len) {
        if ((slice[i] != TokenType.SPACE) or (data[i][0] != ' ')) {
            if (i % 4 != 0)
                std.debug.print("!! inconsistent tabbing, todo. cause some errors here\n", .{});
            return false;
        }
        i += 1;
    }
    return true;
}

fn tokMatchDialogueWithSpeaker(slice: []const TokenType) bool {
    if (slice.len < 3) return false;

    if ((slice[0] == TokenType.LABEL or slice[0] == TokenType.SPEAKERSIGN) and
        slice[1] == TokenType.COLON and
        slice[2] == TokenType.STORY_TEXT)
    {
        return true;
    }

    return false;
}

fn tokMatchDialogueContinuation(slice: []const TokenType) bool {
    if (slice.len < 2) return false;

    if (slice[0] == TokenType.COLON and
        slice[1] == TokenType.STORY_TEXT)
    {
        return true;
    }

    return false;
}

fn tokMatchComment(slice: []const TokenType) bool {
    if (slice.len < 2) return false;

    if (slice[0] == TokenType.HASHTAG and
        slice[1] == TokenType.COMMENT)
    {
        return true;
    }

    return false;
}

fn tokMatchLabelDeclare(slice: []const TokenType) bool {
    if (slice.len < 3) return false;

    if (slice[0] == TokenType.L_SQBRACK and
        slice[1] == TokenType.LABEL and
        slice[2] == TokenType.R_SQBRACK)
    {
        return true;
    }

    return false;
}

fn tokMatchDialogueChoice(slice: []const TokenType) bool {
    if (slice.len < 2) return false;

    var searchSlice = slice;

    if (searchSlice[0] == TokenType.LABEL) {
        searchSlice = slice[1..];
    }

    if (searchSlice[0] == TokenType.R_ANGLE and searchSlice[searchSlice.len - 1] == TokenType.STORY_TEXT) {
        return true;
    }

    return false;
}

pub const DelcarativeParser = struct {
    toks: *const TokenStream,

    pub fn ParseTokStream(toks: TokenStream) !void {
        var self = .{toks};
        _ = self;
    }
};

const TokenWindow = struct {
    startIndex: usize = 0,
    endIndex: usize = 1,
};

const NodeLinkingRules = struct {
    node: Node,
    tabLevel: usize,
    label: ?[]const u8 = null,
    explicit_goto: ?Node = null,
    typeInfo: union(enum) { linear: struct {
        shouldLinkToLast: bool = true,
        lastNode: Node,
    }, choice: struct {} },

    pub fn displayPretty(self: NodeLinkingRules) void {
        if (self.node.id == 0) {
            std.debug.print("node: NULL NODE \n", .{});
            return;
        }
        std.debug.print("node: {d} t={d} ", .{ self.node.id, self.tabLevel });
        if (self.label) |label| {
            std.debug.print("->[{s}]", .{label});
        }
        if (self.explicit_goto) |goto| {
            std.debug.print("->[ID: {d}]", .{goto});
        }

        switch (self.typeInfo) {
            .linear => |info| {
                if (info.shouldLinkToLast) {
                    std.debug.print(" comes from : {d}", .{info.lastNode.id});
                }
            },
            .choice => |info| {
                std.debug.print(" choice node", .{});
                _ = info;
            },
        }
        std.debug.print("\n", .{});
    }
};

pub const ParserWarningOrErrorInfo = struct {
    errorUnion: ParserWarningOrError,
    tokenWindow: TokenWindow,
    fileName: []const u8,
    lineNumber: usize,
};

pub const NodeParser = struct {
    const Self = @This();

    tokenStream: TokenStream,
    isParsing: bool = true,
    tabLevel: usize = 0,
    lineNumber: usize = 1,
    story: StoryNodes,
    currentTokenWindow: TokenWindow = .{},
    currentNodeForChoiceEval: Node = .{},
    lastNode: Node = .{},
    lastLabel: []const u8,
    hasLastLabel: bool = false,
    isNewLining: bool = true,
    nodeLinkingRules: ArrayList(NodeLinkingRules),
    errors: ArrayList(ParserWarningOrErrorInfo),
    warnings: ArrayList(ParserWarningOrErrorInfo),
    filename: []const u8 = "__halcyon_no_file",

    pub fn pushError(self: *Self, errorType: ParserWarningOrError, fmt: []const u8, args: anytype) !void {
        _ = args;
        _ = fmt;
        try self.errors.append(.{
            .errorUnion = errorType,
            .tokenWindow = self.currentTokenWindow,
            .fileName = self.filename,
            .lineNumber = self.lineNumber,
        });
    }

    pub fn pushWarning(self: *Self, errorType: ParserWarningOrError, fmt: []const u8, args: anytype) !void {
        _ = args;
        _ = fmt;
        try self.warnings.append(.{
            .errorUnion = errorType,
            .tokenWindow = self.currentTokenWindow,
            .fileName = self.filename,
            .lineNumber = self.lineNumber,
        });
    }

    fn makeLinkingRules(self: *Self, node: Node) NodeLinkingRules {
        _ = self;
        return NodeLinkingRules{
            .node = node,
            .tabLevel = self.tabLevel,
            .typeInfo = .{ .linear = .{ .lastNode = self.lastNode } },
        };
    }

    fn addCurrentDialogueChoiceFromUtf8Content(self: *Self, choiceContent: []const u8, alloc: std.mem.Allocator) !void {
        var node = try self.story.newNodeWithContent(choiceContent, alloc);
        var rules = self.makeLinkingRules(node);
        rules.typeInfo = .{ .choice = .{} };
        try self.finishCreatingNode(node, rules);
        _ = alloc;
    }

    fn matchFunctionCallGeneric(slice: []const TokenType, data: anytype, functionName: []const u8) bool {
        if (slice.len < 4) return false;

        if (data.len != slice.len) {
            std.debug.print("something is really wrong\n", .{});
            return false;
        }

        if (!std.mem.eql(u8, data[1], functionName)) return false;

        if (slice[0] == TokenType.AT and
            slice[1] == TokenType.LABEL and
            slice[2] == TokenType.L_PAREN and
            slice[slice.len - 1] == TokenType.R_PAREN)
        {
            return true;
        }

        return false;
    }

    fn finishCreatingNode(self: *Self, node: Node, params: NodeLinkingRules) !void {
        self.lastNode = node;

        try self.nodeLinkingRules.append(params);

        // handle linking
        if (self.hasLastLabel) {
            self.hasLastLabel = false;
            try self.story.setLabel(node, self.lastLabel);
        }
    }

    fn deinit(self: *Self) void {
        // we dont release the storyNodes
        self.tokenStream.deinit();
        self.nodeLinkingRules.deinit();
        self.errors.deinit();
        self.warnings.deinit();
    }

    pub fn MakeParser(source: []const u8, alloc: std.mem.Allocator) !Self {
        var rv = Self{
            .tokenStream = try TokenStream.MakeTokens(source, alloc),
            .story = StoryNodes.init(alloc),
            .nodeLinkingRules = ArrayList(NodeLinkingRules).init(alloc),
            .lastLabel = "",
            .hasLastLabel = false,
            .errors = ArrayList(ParserWarningOrErrorInfo).init(alloc),
            .warnings = ArrayList(ParserWarningOrErrorInfo).init(alloc),
        };

        try rv.nodeLinkingRules.append(rv.makeLinkingRules(.{}));
        return rv;
    }

    const TabScope = struct {
        leafNodes: ArrayList(Node),
        ownerNode: Node,

        pub fn addNewNode(self: *TabScope, node: Node) !void {
            try self.leafNodes.append(node);
        }
        pub fn joinScope(self: *TabScope, other: *TabScope) !void {
            try other.leafNodes.appendSlice(self.leafNodes.items);
        }
        pub fn init(node: Node, alloc: std.mem.Allocator) TabScope {
            return .{ .leafNodes = ArrayList(Node).init(alloc), .ownerNode = node };
        }
        pub fn deinit(self: *TabScope) void {
            self.leafNodes.deinit();
        }
        pub fn deinitAllScopes(scopes: *ArrayList(TabScope)) void {
            var i: usize = 0;
            while (i < scopes.items.len) {
                scopes.items[i].deinit();
                i += 1;
            }
            scopes.deinit();
        }
    };

    pub fn LinkNodes(self: *Self, alloc: std.mem.Allocator) !void {
        assert(self.nodeLinkingRules.items.len == self.story.instances.items.len);

        // first pass, link all linear nodes and choices
        {
            var i: usize = 0;
            while (i < self.nodeLinkingRules.items.len) {
                const rule = self.nodeLinkingRules.items[i];
                // rule.displayPretty();
                switch (rule.typeInfo) {
                    .linear => |info| {
                        if (!self.story.nextNode.contains(info.lastNode)) {
                            try self.story.setLink(info.lastNode, rule.node);
                        }
                    },
                    .choice => {},
                }

                if (rule.label) |label| {
                    std.debug.print("goto from {any} -> {s}\n", .{ rule.node, label });
                    _ = try self.story.setLinkByLabel(rule.node, label);
                } else if (rule.explicit_goto) |goto| {
                    _ = try self.story.setLink(rule.node, goto);
                }
                i += 1;
            }
        }

        // second pass, collapse blocks based on tabscoping
        var scopes = ArrayList(TabScope).init(alloc);
        try scopes.append(TabScope.init(.{}, alloc));
        defer TabScope.deinitAllScopes(&scopes);

        {
            var i: usize = 0;
            while (i < self.nodeLinkingRules.items.len) {
                const rule = self.nodeLinkingRules.items[i];
                // std.debug.print("STATE {s} -> {s}\n", .{rule.node, self.story.nextNode.get(rule.node)});
                if ((rule.tabLevel + 1) == scopes.items.len + 1) {
                    var newScope = TabScope.init(self.nodeLinkingRules.items[i - 1].node, alloc);
                    try scopes.append(newScope);
                    switch (rule.typeInfo) {
                        .linear => {
                            if (!self.story.nextNode.contains(rule.node)) {
                                // this is a leaf node. add it to the scope leaf nodes
                                // std.debug.print("adding leaf node {s}\n", .{rule.node});
                                try scopes.items[scopes.items.len - 1].addNewNode(rule.node);
                            }
                        },
                        .choice => {
                            try self.story.addChoiceByNode(scopes.items[scopes.items.len - 1].ownerNode, rule.node, alloc);
                        },
                    }
                } else if ((rule.tabLevel + 1) < scopes.items.len) {
                    var popCount: usize = scopes.items.len - (rule.tabLevel + 1);
                    while (popCount > 0) {
                        var scope = scopes.pop();
                        try scope.joinScope(&scopes.items[scopes.items.len - 1]);
                        scope.deinit();
                        popCount -= 1;
                    }
                    // std.debug.print("leafcount: {d} {d}\n", .{ i, scopes.items[scopes.items.len - 1].leafNodes.items.len});

                    switch (rule.typeInfo) {
                        .linear => {
                            for (scopes.items[scopes.items.len - 1].leafNodes.items) |fromNode| {
                                if (!self.story.nextNode.contains(fromNode)) {
                                    // std.debug.print("SETLINK {s} -> {s}\n", .{fromNode, rule.node});
                                    try self.story.setLink(fromNode, rule.node);
                                }
                            }
                            scopes.items[scopes.items.len - 1].leafNodes.clearAndFree();
                        },
                        .choice => {
                            try self.story.addChoiceByNode(scopes.items[scopes.items.len - 1].ownerNode, rule.node, alloc);
                        },
                    }
                } else if ((rule.tabLevel + 1) > scopes.items.len + 1) {
                    // std.debug.print("{d} {d}\n", .{rule.tabLevel, scopes.items.len});
                    try parserPanic("Inconsistent tab level \n");
                } else {
                    switch (rule.typeInfo) {
                        .linear => {
                            if (!self.story.nextNode.contains(rule.node)) {
                                // this is a leaf node. add it to the scope leaf nodes
                                // std.debug.print("adding leaf node {s}\n", .{rule.node});
                                try scopes.items[scopes.items.len - 1].addNewNode(rule.node);
                            }
                        },
                        .choice => {
                            try self.story.addChoiceByNode(scopes.items[scopes.items.len - 1].ownerNode, rule.node, alloc);
                        },
                    }
                }
                i += 1;
            }
        }

        // Bad optimization pass blow away nodes marked with passThrough
        {
            var i: usize = 0;
            while (i < self.story.instances.items.len) : (i += 1) {
                var thisNode = self.story.instances.items[i];
                if (self.story.nextNode.get(thisNode)) |nextNode| {
                    if (self.story.passThrough.items[nextNode.id]) {
                        if (self.story.nextNode.get(nextNode)) |nextNextNode| {
                            try self.story.setLink(thisNode, nextNextNode);
                        }
                    }
                }
            }
        }
    }

    pub fn DoParse(source: []const u8, alloc: std.mem.Allocator) !StoryNodes {
        var self = try Self.MakeParser(source, alloc);
        defer self.deinit();

        const tokenTypes = self.tokenStream.token_types;
        const tokenData = self.tokenStream.tokens;

        var nodesCount: u32 = 0;

        ParserPrint("\n", .{});
        while (self.isParsing) {
            const newestTokenIndex = self.currentTokenWindow.endIndex - 1;
            const tokenType = tokenTypes.items[newestTokenIndex];
            _ = tokenType;
            const tokenTypeSlice = tokenTypes.items[self.currentTokenWindow.startIndex..self.currentTokenWindow.endIndex];
            const dataSlice = tokenData.items[self.currentTokenWindow.startIndex..self.currentTokenWindow.endIndex];
            //ParserPrint("current window: {s} `{s}`\n", .{ self.currentTokenWindow, dataSlice });

            var shouldBreak = false;
            if (!shouldBreak and tokMatchComment(tokenTypeSlice)) {
                ParserPrint(" comment (not a real node) latsNode = {d}\n", .{self.lastNode.id});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchSet(tokenTypeSlice, dataSlice)) {
                nodesCount += 1;
                ParserPrint("{d}: Set var\n", .{nodesCount});
                const node = try self.story.newDirectiveNodeFromUtf8(dataSlice, alloc);
                try self.story.setTextContentFromSlice(node, "Set var");
                try self.finishCreatingNode(node, self.makeLinkingRules(node));
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchGoto(tokenTypeSlice, dataSlice)) {
                ParserPrint("{d}: Goto -> {s}\n", .{ self.lastNode.id, dataSlice[dataSlice.len - 1] });
                if (self.lastNode.id > 0) {
                    if (self.nodeLinkingRules.items[self.lastNode.id].tabLevel > self.tabLevel) {
                        const node = try self.story.newNodeWithContent("Goto Node", alloc);
                        self.story.passThrough.items[node.id] = true;
                        var linkRules = self.makeLinkingRules(node);
                        linkRules.label = dataSlice[dataSlice.len - 1];
                        try self.finishCreatingNode(node, linkRules);
                    } else {
                        self.nodeLinkingRules.items[self.lastNode.id].label = dataSlice[dataSlice.len - 1];
                    }
                } else {
                    return ParserError.GeneralParserError;
                }
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchEnd(tokenTypeSlice, dataSlice)) {
                if (self.lastNode.id > 0) {
                    //try self.story.setLink(self.lastNode, self.story.instances.items[0]);

                    ParserPrint("{d}: end of story\n", .{self.lastNode.id});

                    if (self.nodeLinkingRules.items[self.lastNode.id].tabLevel > self.tabLevel) {
                        const node = try self.story.newNodeWithContent("Goto Node", alloc);
                        self.story.passThrough.items[node.id] = true;
                        var linkRules = self.makeLinkingRules(node);
                        linkRules.label = "@__STORY_END__";
                        try self.finishCreatingNode(node, linkRules);
                    } else {
                        self.nodeLinkingRules.items[self.lastNode.id].label = "@__STORY_END__";
                    }
                } else {
                    return ParserError.GeneralParserError;
                }

                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchIf(tokenTypeSlice, dataSlice)) {
                nodesCount += 1;

                ParserPrint("{d}: If block start\n", .{nodesCount});
                const node = try self.story.newDirectiveNodeFromUtf8(dataSlice, alloc);
                try self.story.conditionalBlock.put(node, .{});
                try self.story.setTextContentFromSlice(node, "If block");
                try self.finishCreatingNode(node, self.makeLinkingRules(node));
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchElif(tokenTypeSlice, dataSlice)) {
                ParserPrint("If block start\n", .{});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchElse(tokenTypeSlice, dataSlice)) {
                ParserPrint("else block\n", .{});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchVarsBlock(tokenTypeSlice, dataSlice)) {
                nodesCount += 1;
                const node = try self.story.newDirectiveNodeFromUtf8(dataSlice, alloc);
                try self.story.setTextContentFromSlice(node, "Vars block");
                try self.finishCreatingNode(node, self.makeLinkingRules(node));
                ParserPrint("{d}: Vars block\n", .{nodesCount});
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchGenericDirective(tokenTypeSlice)) {
                nodesCount += 1;
                const max = @min(10, dataSlice.len);
                ParserPrint("{d}: Generic Directive: {s}\n", .{ nodesCount, dataSlice[0..max] });
                const node = try self.story.newDirectiveNodeFromUtf8(dataSlice, alloc);
                try self.story.setTextContentFromSlice(node, "Generic Directive");
                try self.finishCreatingNode(node, self.makeLinkingRules(node));
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchTabSpace(tokenTypeSlice, dataSlice)) {
                ParserPrint("    ", .{});
                self.tabLevel += 1;
                shouldBreak = true;
            }
            // inline space clause
            if (!shouldBreak and tokenTypeSlice[0] == TokenType.SPACE) {
                var i: usize = 0;
                var shouldPushStart: bool = false;
                while (i < tokenTypeSlice.len and i < 4) : (i += 1) {
                    if (tokenTypeSlice[i] != TokenType.SPACE) {
                        shouldPushStart = true;
                        break;
                    }
                }
                if (shouldPushStart) {
                    self.currentTokenWindow.endIndex -= 1;
                    shouldBreak = true;
                }
            }
            if (!shouldBreak and tokMatchLabelDeclare(tokenTypeSlice)) {
                ParserPrint("> Label declare {s}\n", .{dataSlice[1]});
                if (self.story.tags.contains(dataSlice[1])) {
                    try self.pushWarning(ParserWarning.DuplicateLabelWarning, "duplicate label: {s}", .{dataSlice[1]});
                }
                self.hasLastLabel = true;
                self.lastLabel = dataSlice[1];
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchDialogueWithSpeaker(tokenTypeSlice)) {
                const node = try self.story.newNodeWithContent(dataSlice[2], alloc);
                nodesCount += 1;

                if (tokenTypeSlice[0] == TokenType.LABEL) {
                    try self.story.addSpeaker(node, try NodeString.fromUtf8(dataSlice[0], alloc));
                }

                try self.finishCreatingNode(node, self.makeLinkingRules(node));
                ParserPrint("{d}: story node {d}\n", .{ nodesCount, self.tabLevel });
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchDialogueContinuation(tokenTypeSlice)) {
                ParserPrint("Continuation of dialogue detected\n", .{});
                try self.story.textContent.items[self.lastNode.id].string.appendSlice(" ");
                try self.story.textContent.items[self.lastNode.id].string.appendSlice(dataSlice[1]);
                shouldBreak = true;
            }
            if (!shouldBreak and tokMatchDialogueChoice(tokenTypeSlice)) {
                nodesCount += 1;
                ParserPrint("{d}: Choice Node\n", .{nodesCount});
                try self.addCurrentDialogueChoiceFromUtf8Content(dataSlice[dataSlice.len - 1], alloc);
                shouldBreak = true;
            }
            if (!shouldBreak and tokenTypeSlice[0] == TokenType.NEWLINE) {
                self.tabLevel = 0;
                self.isNewLining = true;
                self.currentTokenWindow.startIndex += 1;
            }
            if (shouldBreak) {
                self.currentTokenWindow.startIndex = self.currentTokenWindow.endIndex;
            }
            if (self.currentTokenWindow.endIndex - self.currentTokenWindow.startIndex > 3 and self.currentTokenWindow.endIndex >= tokenTypes.items.len) {
                ParserPrint("Unexpected end of file, parsing object from `{s}`", .{tokenData.items[self.currentTokenWindow.startIndex]});
                return self.story;
            }
            if (self.currentTokenWindow.endIndex == tokenTypes.items.len) {
                break;
            } else {
                self.currentTokenWindow.endIndex += 1;
            }
            if (tokenTypeSlice[0] != TokenType.NEWLINE) {
                self.isNewLining = false;
            }
        }

        try self.LinkNodes(alloc);
        return self.story;
    }
};

// ========================= Testing =========================
fn makeSimpleTestStory(alloc: std.mem.Allocator) !StoryNodes {
    //[hello]
    //$: Hello!
    //$: I'm going to ask you a question.
    //: Do you like cats or dogs?
    //> Cats:
    //    $: Hmm I guess we can't be friends
    //> Dogs:
    //    $: Nice!
    //    Lee: Yeah man they're delicious
    //> Both:
    //    $: Don't be stupid you have to pick one.
    //    @goto hello
    //$: you walk away in disgust
    //@end

    var story = StoryNodes.init(alloc);

    // node 0
    var currentNode = try story.newNodeWithContent("Hello!", alloc);
    try story.setLabel(currentNode, "hello");
    var lastNode = currentNode;

    // node 1
    currentNode = try story.newNodeWithContent("I'm going to ask you a question. Do you like cats or dogs?", alloc);
    try story.setLink(lastNode, currentNode);
    lastNode = currentNode;

    const finalNode = try story.newNodeWithContent("You walk away in disgust", alloc);
    try story.setEnd(finalNode);

    // create nodes for responses
    const catNode = try story.newNodeWithContent("Hmm I guess we can't be friends.", alloc);
    try story.setLink(catNode, finalNode);

    // next node
    {
        const choiceNodes: []Node = &.{
            try story.newNodeWithContent("Cats", alloc),
            try story.newNodeWithContent("Dogs", alloc),
            try story.newNodeWithContent("Both", alloc),
        };

        try story.addChoicesBySlice(lastNode, choiceNodes, alloc);

        var node = try story.newNodeWithContent("Don't be stupid you can't pick both!", alloc);
        try story.setLink(choiceNodes[0], catNode);

        node = try story.newNodeWithContent("Yeah man they're delicious!", alloc);
        try story.addSpeaker(node, try NodeString.fromUtf8("Lee", alloc));
        try story.setLink(node, finalNode);
        try story.setLink(choiceNodes[1], node);

        node = try story.newNodeWithContent("Don't be stupid you can't pick both!", alloc);
        _ = try story.setLinkByLabel(node, "hello");
        try story.setLink(choiceNodes[2], node);
    }
    return story;
}

test "parse with nodes" {
    var story = try NodeParser.DoParse(tokenizer.easySampleData, std.testing.allocator);
    defer story.deinit();
    // try testChoicesList(story, &.{0,0,0,0}, std.testing.allocator);

    std.debug.print("\n", .{});
    for (story.textContent.items) |content, i| {
        const node = story.instances.items[i];
        std.debug.assert(node.id == i);
        std.debug.print("{d}> {!s}\n", .{ i, content.asUtf8Native() });
    }
    std.debug.print("\n", .{});
}

test "parse simplest with no-conditionals" {
    var story = try NodeParser.DoParse(tokenizer.simplest_v1, std.testing.allocator);
    defer story.deinit();
    // try testChoicesList(story, &.{0,0,0,0}, std.testing.allocator);

    std.debug.print("\n", .{});
    for (story.textContent.items) |content, i| {
        if (i == 0) continue;
        const node = story.instances.items[i];
        std.debug.assert(node.id == i);
        if (story.conditionalBlock.contains(node)) {
            std.debug.print("{d}> {!s}\n", .{ i, content.asUtf8Native() });
        } else {
            if (story.speakerName.get(node)) |speaker| {
                std.debug.print("{d}> STORY_TEXT> {!s}: {!s} ", .{ i, speaker.asUtf8Native(), content.asUtf8Native() });
            } else {
                std.debug.print("{d}> STORY_TEXT> $: {!s} ", .{ i, content.asUtf8Native() });
            }

            if (story.passThrough.items[node.id]) {
                std.debug.print("-", .{});
            }

            if (story.nextNode.get(node)) |next| {
                std.debug.print("-> {d}", .{next.id});
            }
        }

        if (story.choices.get(node)) |choices| {
            std.debug.print("\n", .{});
            for (choices.items) |c| {
                std.debug.print("    -> {any}\n", .{c});
            }
        }
        std.debug.print("\n", .{});
    }

    var iter = story.tags.iterator();

    std.debug.print("\nLabels\n", .{});
    while (iter.next()) |instance| {
        std.debug.print("key: {s} -> {d}\n", .{ instance.key_ptr.*, instance.value_ptr.*.id });
    }

    std.debug.print("\n", .{});
}

fn testChoicesList(story: StoryNodes, choicesList: []const usize, alloc: std.mem.Allocator) !void {
    var interactor = Interactor.init(&story, alloc);
    defer interactor.deinit();
    interactor.startRecording();
    try interactor.iterateChoicesList(choicesList); // path 1
    interactor.showHistory();
}

test "parsed simple storyNode" {
    const alloc = std.testing.allocator;
    var story = try NodeParser.DoParse(tokenizer.simplest_v1, std.testing.allocator);
    defer story.deinit();
    {
        std.debug.print("\nPath 1 test -----\n", .{});
        try testChoicesList(story, &.{0}, alloc);
    }
    {
        std.debug.print("\nPath 2 test -----\n", .{});
        try testChoicesList(story, &.{1}, alloc);
    }
    {
        std.debug.print("\nPath 3 test -----\n", .{});
        try testChoicesList(story, &.{ 2, 2, 1 }, alloc);
    }
}

test "manual simple storyNode" {
    const alloc = std.testing.allocator;
    var story = try makeSimpleTestStory(alloc);
    defer story.deinit();
    {
        std.debug.print("\nPath 1 test -----\n", .{});
        try testChoicesList(story, &.{0}, alloc);
    }
    {
        std.debug.print("\nPath 2 test -----\n", .{});
        try testChoicesList(story, &.{1}, alloc);
    }
    {
        std.debug.print("\nPath 3 test -----\n", .{});
        try testChoicesList(story, &.{ 2, 2, 1 }, alloc);
    }
}

test "init and deinit" {
    var x = StoryNodes.init(std.testing.allocator);
    defer x.deinit();
}
