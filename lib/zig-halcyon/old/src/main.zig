//
const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;

// Aliases

// These nodes are how the true runtime works underneath the hood.
// These nodes will be grouped different in the visual editor.

// The Text based editor won't have a concept of nodes, but rather is based on scopes
// Instead

const Node = u32;
const NodeString = ArrayList(u8);
const NodeStringView = []const u8;

const NodeType = enum(u8) {
    Dead, // set to this to effectively mark this node as dead
    Text,
    Response,
};

// master entities
const NodeEntities = struct {
    instances: ArrayList(NodeString),
    nodeTypes: ArrayList(NodeType),

    const Self = @This();

    // memory management interface
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .instances = ArrayList(NodeString).init(allocator),
            .nodeTypes = ArrayList(NodeType).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.instances.items) |instance| {
            instance.deinit();
        }
        self.instances.deinit();
        self.nodeTypes.deinit();
    }

    // management interface
    pub fn newEntity(self: *Self, allocator: std.mem.Allocator) !Node {
        try self.instances.append(ArrayList(u8).init(allocator));
        try self.nodeTypes.append(NodeType.Text);

        std.debug.assert(self.instances.items.len > 0);
        return @intCast(u32, self.instances.items.len - 1);
    }

    pub fn newEntityFromPlainText(self: *Self, allocator: std.mem.Allocator, string: NodeStringView) !Node {
        const id = @intCast(u32, try self.newEntity(allocator));
        try self.instances.items[id].appendSlice(string);
        return id;
    }

    // direct access to node type
    pub fn setNodeType(self: *Self, node: Node, newType: NodeType) void {
        if (node < self.instances.items.len) {
            self.nodeTypes.items[node] = newType;
        }
    }
};

const SpeakerNames = struct {
    instances: AutoHashMap(Node, NodeString),
    const Self = @This();

    // memory management interface
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .instances = AutoHashMap(Node, NodeString).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        var iter = self.instances.iterator();
        while (iter.next()) |instance| {
            instance.value_ptr.deinit();
        }

        self.instances.deinit();
    }

    pub fn setSpeakerName(self: *Self, allocator: std.mem.Allocator, node: Node, newString: NodeStringView) !void {
        var result = (try self.instances.getOrPut(node));

        if (!result.found_existing) {
            result.value_ptr.* = NodeString.init(allocator);
        }

        var instance = result.value_ptr;
        instance.resize(newString.len) catch unreachable;
        const range = instance.items[0..instance.items.len];
        try instance.replaceRange(0, instance.items.len, newString);
        _ = range;
    }
};

const Choices = struct {
    instances: AutoHashMap(u32, []const u32),
    const Self = @This();

    // memory management interface
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .instances = AutoHashMap(u32, []const u32).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.instances.deinit();
    }
};

const NextNode = struct {
    instances: AutoHashMap(Node, Node),
    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .instances = AutoHashMap(Node, Node).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.instances.deinit();
    }

    pub fn setNextNode(self: *Self, from: Node, to: Node) !void {
        try self.instances.put(from, to);
    }
};

const HalcInteractor = struct {
    ecs: *HalcECS,
    currentNode: Node,
    isInteracting: bool,

    const Self = @This();

    pub fn nextNode(self: *Self) void {
        if (self.ecs.nextNodeComponents.instances.get(self.currentNode)) |n| {
            self.currentNode = n;
        } else {
            self.isInteracting = false;
        }
        _ = self;
    }

    pub fn choose(self: *Self, choice: u32) void {
        if (self.ecs.choicesComponents.instances.get(self.currentNode)) |currentChoices| {
            if (choice < currentChoices.len) {
                const choiceNode = currentChoices[choice];
                if (self.ecs.nextNodeComponents.instances.get(currentChoices[choice])) |n| {
                    self.currentNode = n;
                } else {
                    std.debug.print(
                        "\nchoice {d} node {d} refers to node {d} which does not exist",
                        .{ choice, self.currentNode, choiceNode },
                    );
                }
            } else {
                std.debug.print(
                    "choice slot {d} not implemented for node {d}, this node has{d} choices available\n",
                    .{
                        choice,
                        self.currentNode,
                        currentChoices.len,
                    },
                );
            }
        } else {
            std.debug.print("node {d} has no choices available\n", .{self.currentNode});
        }
    }
};

const HalcECS = struct {
    entities: NodeEntities,
    speakerNameComponents: SpeakerNames,
    choicesComponents: Choices,
    nextNodeComponents: NextNode,

    const Self = @This();

    // management interface
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .entities = NodeEntities.init(allocator),
            .speakerNameComponents = SpeakerNames.init(allocator),
            .choicesComponents = Choices.init(allocator),
            .nextNodeComponents = NextNode.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.entities.deinit();
        self.speakerNameComponents.deinit();
        self.choicesComponents.deinit();
        self.nextNodeComponents.deinit();
    }
};

fn test_simple_branching_story(allocator: std.mem.Allocator) !HalcECS {
    var ecs = HalcECS.init(allocator);

    // create the base content for the
    var n = try ecs.entities.newEntityFromPlainText(allocator, "Hello I am the narrator."); // 0
    _ = try ecs.entities.newEntityFromPlainText(allocator, "Do you like cats or dogs."); // 1
    _ = try ecs.entities.newEntityFromPlainText(allocator, "Guess we can't be friends."); // 2
    _ = try ecs.entities.newEntityFromPlainText(allocator, "You leave in disgust."); // 3
    _ = try ecs.entities.newEntityFromPlainText(allocator, "They taste delicious."); // 4
    _ = try ecs.entities.newEntityFromPlainText(allocator, "You can't choose both, that's stupid"); // 5

    const chongs_line = try ecs.entities.newEntityFromPlainText(allocator, "YOU TAKE THAT BACK."); // 6

    n = try ecs.entities.newEntityFromPlainText(allocator, "cats"); // 7
    ecs.entities.setNodeType(n, NodeType.Response);

    n = try ecs.entities.newEntityFromPlainText(allocator, "dogs"); // 8
    ecs.entities.setNodeType(n, NodeType.Response);

    n = try ecs.entities.newEntityFromPlainText(allocator, "both"); // 9
    ecs.entities.setNodeType(n, NodeType.Response);

    try ecs.nextNodeComponents.setNextNode(0, 1);
    try ecs.nextNodeComponents.setNextNode(2, 3);
    try ecs.nextNodeComponents.setNextNode(4, 6);
    try ecs.nextNodeComponents.setNextNode(6, 3);
    try ecs.nextNodeComponents.setNextNode(5, 1);

    try ecs.nextNodeComponents.setNextNode(7, 2);
    try ecs.nextNodeComponents.setNextNode(8, 4);
    try ecs.nextNodeComponents.setNextNode(9, 5);

    try ecs.choicesComponents.instances.put(1, &.{ 7, 8, 9 });

    _ = try ecs.speakerNameComponents.setSpeakerName(allocator, chongs_line, "chong");

    return ecs;
}

test "simple branching story" {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var allocator = std.testing.allocator;

    var ecs = try test_simple_branching_story(allocator);
    defer ecs.deinit();

    // test allocation and cleanup of entities
    for (ecs.entities.instances.items) |entityText, i| {
        const speaker = ecs.speakerNameComponents.instances.get(@intCast(u32, i));
        var speakerName = if (speaker) |s| s.items else "default";
        try stdout.print("\n {s} id {d} : {s}", .{ speakerName, i, entityText.items });
    }

    // test an interactor

    {
        var i = HalcInteractor{ .ecs = &ecs, .currentNode = 0, .isInteracting = true };

        i.nextNode();
        try std.testing.expect(i.currentNode == 1);

        var i_path1 = HalcInteractor{
            .ecs = i.ecs,
            .currentNode = i.currentNode,
            .isInteracting = i.isInteracting,
        };

        var i_path2 = HalcInteractor{
            .ecs = i.ecs,
            .currentNode = i.currentNode,
            .isInteracting = i.isInteracting,
        };

        var i_path3 = HalcInteractor{
            .ecs = i.ecs,
            .currentNode = i.currentNode,
            .isInteracting = i.isInteracting,
        };

        i_path1.choose(0);
        try std.testing.expect(i_path1.currentNode == 2);

        i_path2.choose(1);
        try std.testing.expect(i_path2.currentNode == 4);

        i_path3.choose(2);
        try std.testing.expect(i_path3.currentNode == 5);
    }

    try stdout.print("\n", .{});

    _ = stdout;
    _ = stdin;
    _ = allocator;
}

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var allocator = std.heap.page_allocator;

    var dialogueTexts = ArrayList([]const u8).init(allocator);
    var speakerNames = AutoHashMap(u32, []const u8).init(allocator);
    var choices = AutoHashMap(u32, []const u32).init(allocator);
    var next = AutoHashMap(u32, u32).init(allocator);

    try dialogueTexts.appendSlice(&.{
        "Hello I am the narrator.", // 0
        "Do you like cats or dogs.", // 1
        "Guess we can't be friends.", // 2
        "You leave in disgust.", //3
        "They taste delicious.", //4
        "You can't choose both, that's stupid", // 5
        "YOU TAKE THAT BACK.", // 6
        "cats", // 7
        "dogs", // 8
        "both", // 9
    });

    try speakerNames.put(6, "chong");
    try choices.put(1, &.{ 7, 8, 9 });

    try next.put(0, 1);
    try next.put(2, 3);
    try next.put(4, 6);
    try next.put(6, 3);
    try next.put(5, 1);

    try next.put(7, 2);
    try next.put(8, 4);
    try next.put(9, 5);

    // -- interactor --

    var currentNode: u32 = 0;
    var shouldBreak: bool = false;
    var buffer: [4096]u8 = undefined;

    while (!shouldBreak) {
        // print out speaker: content
        const name = speakerNames.get(currentNode) orelse "narrator";
        try stdout.print("{s}: {s}\n", .{ name, dialogueTexts.items[currentNode] });

        // if there's choices print out choices
        if (choices.get(currentNode)) |currentChoices| {
            for (currentChoices) |printChoice, i| {
                const choiceContent = if (printChoice < dialogueTexts.items.len)
                    dialogueTexts.items[printChoice]
                else
                    "Unknown choice.";
                try stdout.print("{}: {s}\n", .{ i + 1, choiceContent });
            }
            const chosenValue = while (true) {
                const selection = (try stdin.readUntilDelimiterOrEof(&buffer, '\r')) orelse unreachable;
                try stdin.skipBytes(1, .{});
                const value = std.fmt.parseInt(u32, selection, 10) catch {
                    try stdout.print("Couldn't parse that\r\n", .{});
                    continue;
                };
                if (value < 1 or value > currentChoices.len) {
                    try stdout.print("Invalid selection\r\n", .{});
                    continue;
                }
                break value;
            } else unreachable;
            currentNode = next.get(currentChoices[chosenValue - 1]) orelse unreachable;
        } else {
            _ = try stdin.readUntilDelimiterOrEof(&buffer, '\n');
            currentNode = next.get(currentNode) orelse endLoop: {
                shouldBreak = true;
                break :endLoop 0;
            };
        }
    }

    try stdout.print("bye.\n", .{});
    _ = stdout;
    _ = stdin;
}
