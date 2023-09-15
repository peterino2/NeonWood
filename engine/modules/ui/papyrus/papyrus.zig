const std = @import("std");
const c = @cImport({
    @cInclude("stb_ttf.h");
});

pub const events = @import("papyrus_events.zig");

pub const PapyrusFont = @import("PapyrusFont.zig");
pub const FontAtlas = PapyrusFont.FontAtlas;
pub const BmpRenderer = @import("BmpRenderer.zig");
pub const BmpWriter = BmpRenderer.BmpWriter;
pub const HashStr = @import("HashStr.zig");

pub const colors = @import("colors.zig");
pub const Color = colors.Color;
pub const ColorRGBA8 = colors.RGBA8;
pub const ModernStyle = colors.ModernStyle;
pub const BurnStyle = colors.BurnStyle;

pub const utils = @import("utils.zig");
pub const FileLog = utils.FileLog;
pub const grapvizDotToPng = utils.grapvizDotToPng;
pub const loadFileAlloc = utils.loadFileAlloc;
pub const assertf = utils.assertf;

pub const localization = @import("localization.zig");
pub const LocText = localization.LocText;
pub const MakeText = localization.MakeText;

const pool = @import("pool.zig");
pub const DynamicPool = pool.DynamicPool;

const vectors = @import("vectors.zig");
pub const Vector2i = vectors.Vector2i;
pub const Vector2 = vectors.Vector2;

// Mixed mode implementation agnostic UI library
//
// Intended for use with real time applications.
// This file only contains the core layout engine and events pump for the IO processor.
//
// Actual hook up of the IO Processor and graphics is done elsewhere.

// =================================== Document: How should the layout engine work ===========================
//
// In terms of goals I want to be able to support both screen space proportional UIs as well as UIs for
// creating general purpose applications.
//
//
// Notes on some other applications like remedybg.
//
// - Panels are either free floating or docked
// - Their position is described as an anchor offset
// - Elements have a minimum size which they are happy to shrink to.
//
// Docked:
// - when docked, the panel's size layout is described as a percentage of their parent's docking space
// - Text should stay the same and not proportionally follow the window.
// - Images and image based layouts should.
//
// Free:
//
// - Their size is absolute, and their position is relative to the reference anchor.
//
// Text:
// - Text should build their geometry requirements ahead of time, and only be looked up when we're ready to render.
// - For a given length of text and a maximum width, we should be able to figure out it's height requirements.
//
// Tasks:
//  - Panel Layout
//      - internal layout:
//          - free:
//          - grid:
//          - verticalList:
//          - horizontalList:
//
//  - Layout algorithm
//      - for each node
//          - get parent context
//          - create current layout context
//          - call into sub layout function with current context
//
// =================================== /Document: How should the layout engine work ===========================

pub var gPapyrusContext: *PapyrusContext = undefined;
pub var gPapyrusIsInitialized: bool = false;

pub const PapyrusEvent = struct {};

pub const PapyrusAnchorNode = enum {
    // zig fmt: off
    Free,       // Anchored to 0,0 absolute on the screen
    TopLeft,    // Anchored such that 0,0 corresponds to the top left corner of the parent node
    MidLeft,    // Anchored such that 0,0 corresponds to the left edge midpoint of the parent node
    BotLeft,    // Anchored such that 0,0 corresponds to the bottom left corner of the parent node
    TopMiddle,  // Anchored such that 0,0 corresponds to the top edge midpoint of the parent node
    MidMiddle,  // Anchored such that 0,0 corresponds to the center of the parent node
    BotMiddle,  // Anchored such that 0,0 corresponds to the bottom edge midpoint of the parent node
    TopRight,   // Anchored such that 0,0 corresponds to the top right corner of the parent node
    MidRight,   // Anchored such that 0,0 corresponds to the right edge midpoint of the parent node
    BotRight,   // Anchored such that 0,0 corresponds to the bottom right corner of the parent node
    // zig fmt: on
};

pub const PapyrusFillMode = enum {
    // zig fmt: off
    None,       // Size will be absolute as specified by content
    FillX,  // Size will scale to X scaling of the parent (relative to reference), if set, then the size value of x will be interpreted as a percentage of the parent
    FillY,  // Size will scale to Y scaling of the parent (relative to reference), if set, then the size value of y will be interpreted as a percentage of the parent
    FillXY, // Size will scale to both X and Y of the parent (relative to reference), if set, then the size value of both x and y will be interpreted as a percentage of the parent
    // zig fmt: on
};

pub const PapyrusHitTestability = enum {
    Testable,
    NotTestable,
};

pub const PapyrusState = enum {
    Visible,
    Collapsed,
    Hidden,
};

pub const ChildLayout = enum { Free, Vertical, Horizontal };

pub const NodeProperty_Slot = struct {
    layoutMode: ChildLayout = .Free,
};

pub const NodeProperty_Button = struct {
    textSignal: LocText,
    onPressedSignal: u32,
    genericListener: u32,
};

pub const NodeProperty_Text = struct {
    textSize: f32,
    color: Color,
    font: PapyrusFont,
};

pub const NodeProperty_Panel = struct {
    titleColor: Color = ModernStyle.GreyDark,
    titleSize: f32 = 24,
    layoutMode: ChildLayout = .Free, // when set to anything other than free, we will override anchors from inferior nodes.
    hasTitle: bool = false,
    font: *FontAtlas,
};

pub const NodePropertiesBag = union(enum(u8)) {
    Slot: NodeProperty_Slot,
    DisplayText: NodeProperty_Text,
    Button: NodeProperty_Button,
    Panel: NodeProperty_Panel,
};

pub const NodePadding = union(enum(u8)) {
    topLeft: Vector2,
    botLeft: Vector2,
    all: f32,
    allSides: [2]Vector2,
};

pub const PapyrusNodeStyle = struct {
    foregroundColor: Color = BurnStyle.Normal,
    backgroundColor: Color = BurnStyle.SlateGrey,
    borderColor: Color = BurnStyle.Bright2,
};

// this is going to follow a pretty object-oriented-like user facing api
pub const PapyrusNode = struct {
    text: LocText = MakeText("hello world"),
    parent: u32 = 0, // 0 corresponds to true root

    // all children of the same parent operate as a doubly linked list
    child: u32 = 0,
    end: u32 = 0,
    next: u32 = 0, //
    prev: u32 = 0,

    zOrder: i32 = 0, // higher order goes first

    // Not sure what's the best way to go about this.
    // I want to provide good design time metrics
    // which can scale into good runtime metrics

    // Resolutions and scalings are a real headspinner
    // DPI awareness and content scaling is also a huge problem.
    size: Vector2 = .{ .x = 0, .y = 0 },
    pos: Vector2 = .{ .x = 0, .y = 0 },
    anchor: PapyrusAnchorNode = .TopLeft,
    fill: PapyrusFillMode = .None,

    // padding is the external
    padding: NodePadding = .{ .all = 0 },

    state: PapyrusState = .Visible,
    hittest: PapyrusHitTestability = .Testable,
    dockingPolicy: enum { Dockable, NotDockable } = .Dockable,

    // standard styling options that all nodes have
    style: PapyrusNodeStyle = .{},

    nodeType: NodePropertiesBag,

    pub fn getSize(self: @This()) Vector2 {
        _ = self;
        return .{};
    }
};

pub const PapyrusContext = struct {
    allocator: std.mem.Allocator,
    nodes: DynamicPool(PapyrusNode),
    fonts: std.AutoHashMap(u32, PapyrusFont),
    fallbackFont: PapyrusFont,
    extent: Vector2i = .{ .x = 1920, .y = 1080 },
    currentCursorPosition: Vector2 = .{},

    // internals
    _drawOrder: DrawOrderList,
    _layout: std.AutoHashMap(u32, PosSize),

    debugText: std.ArrayList([]u8),
    debugTextCount: u32 = 0,

    const debugTextMax = 32;

    pub fn create(backingAllocator: std.mem.Allocator) !*@This() {
        const fallbackFontName: []const u8 = "default";
        const fallbackFontFile: []const u8 = "fonts/ProggyClean.ttf";

        var self = try backingAllocator.create(@This());

        self.* = .{
            .allocator = backingAllocator,
            .nodes = DynamicPool(PapyrusNode).init(backingAllocator),
            .fonts = std.AutoHashMap(u32, PapyrusFont).init(backingAllocator),
            .fallbackFont = PapyrusFont{
                .name = HashStr.fromUtf8(fallbackFontName),
                .atlas = try backingAllocator.create(FontAtlas),
            },
            ._drawOrder = DrawOrderList.init(backingAllocator),
            ._layout = std.AutoHashMap(u32, PosSize).init(backingAllocator),
            .debugText = std.ArrayList([]u8).init(backingAllocator),
        };

        for (0..debugTextMax) |_| {
            var textBuffer = try backingAllocator.alloc(u8, 512);
            try self.debugText.append(textBuffer);
        }

        self.fallbackFont.atlas.* = try FontAtlas.initFromFile(backingAllocator, fallbackFontFile, 18);
        try self.installFontAtlas(self.fallbackFont.name.utf8, self.fallbackFont.atlas);

        // constructing the root node
        _ = try self.nodes.new(.{
            .text = MakeText("root"),
            .parent = 0,
            .nodeType = .{ .Slot = .{} },
        });

        try self.pushDebugText("mouse position: {d}, {d}", .{ 0, 0 });

        return self;
    }

    pub fn pushDebugText(self: *@This(), comptime fmt: []const u8, args: anytype) !void {
        if (self.debugTextCount < debugTextMax) {
            _ = try std.fmt.bufPrintZ(self.debugText.items[self.debugTextCount], fmt, args);
            self.debugTextCount += 1;
        }
    }

    pub fn clearDebugText(self: *@This()) void {
        self.debugTextCount = 0;
    }

    pub fn tick(self: *@This(), deltaTime: f64) !void {
        _ = deltaTime;
        self.clearDebugText();
        try self.pushDebugText("mouse Position: {d}, {d}", .{ self.currentCursorPosition.x, self.currentCursorPosition.y });
    }

    pub fn deinit(self: *@This()) void {
        var iter = self.fonts.iterator();
        while (iter.next()) |i| {
            i.value_ptr.atlas.deinit();
            self.allocator.destroy(i.value_ptr.atlas);
        }

        self.fonts.deinit();
        self.nodes.deinit();
        self._drawOrder.deinit();
        self._layout.deinit();

        for (self.debugText.items) |text| {
            self.allocator.free(text);
        }
        self.debugText.deinit();
        self.allocator.destroy(self);
    }

    pub fn installFontAtlas(self: *@This(), fontName: []const u8, atlas: *FontAtlas) !void {
        const name = HashStr.fromUtf8(fontName);
        try self.fonts.put(name.hash, .{ .atlas = atlas, .name = name });
    }

    pub fn getPanel(self: *@This(), handle: u32) *NodeProperty_Panel {
        return &(self.nodes.get(handle).?.nodeType.Panel);
    }

    pub fn getText(self: *@This(), handle: u32) *NodeProperty_Text {
        return &(self.nodes.get(handle).?.nodeType.DisplayText);
    }

    pub fn setFont(self: *@This(), handle: u32, font: []const u8) void {
        const name = HashStr.fromUtf8(font);

        switch (self.nodes.get(handle).?.nodeType) {
            .DisplayText => {
                var text = &(self.nodes.get(handle).?.nodeType.DisplayText);
                text.font = .{
                    .name = name,
                    .atlas = self.fonts.get(name.hash).?.atlas,
                };
            },
            .Panel => {
                var panel = &(self.nodes.get(handle).?.nodeType.Panel);
                panel.font = self.fonts.get(name.hash).?.atlas;
            },
            else => {},
        }
    }

    // converts a handle to a node pointer
    // invalid after AddNode
    pub fn get(self: *@This(), handle: u32) *PapyrusNode {
        return self.nodes.get(handle).?;
    }

    // gets a node as read only
    pub fn getRead(self: @This(), handle: u32) *const PapyrusNode {
        return self.nodes.getRead(handle).?;
    }

    fn newNode(self: *@This(), node: PapyrusNode) !u32 {
        return try self.nodes.new(node);
    }

    pub fn addSlot(self: *@This(), parent: u32) !u32 {
        var slotNode = PapyrusNode{ .nodeType = .{ .Slot = .{} } };
        var slot = try self.newNode(slotNode);

        try self.setParent(slot, parent);

        return slot;
    }

    pub fn addText(self: *@This(), parent: u32, text: []const u8) !u32 {
        var slotNode = PapyrusNode{
            .text = LocText.fromUtf8(text),
            .nodeType = .{ .DisplayText = .{
                .textSize = 24,
                .color = Color.White,
                .font = self.fallbackFont,
            } },
        };
        var slot = try self.newNode(slotNode);

        try self.setParent(slot, parent);

        return slot;
    }

    pub fn addPanel(self: *@This(), parent: u32) !u32 {
        var slotNode = PapyrusNode{ .nodeType = .{ .Panel = .{
            .font = self.fallbackFont.atlas,
        } } };

        if (parent == 0) {
            slotNode.anchor = .Free;
        }
        var slot = try self.nodes.new(slotNode);

        try self.setParent(slot, parent);

        return slot;
    }

    pub fn setParent(self: *@This(), node: u32, parent: u32) !void {
        try assertf(self.nodes.get(parent) != null, "tried to assign node {d} to parent {d} but parent does not exist", .{ node, parent });
        try assertf(self.nodes.get(node) != null, "tried to assign node {d} to parent {d} but node does not exist", .{ node, parent });

        var parentNode = self.nodes.get(parent).?;
        var thisNode = self.nodes.get(node).?;

        // if we have a previous parent, remove ourselves
        if (thisNode.*.parent != 0) {
            // remove myself from that parent.
            var oldParentNode = self.nodes.get(thisNode.*.parent).?;

            // special case for when we're the first child element
            if (oldParentNode.*.child == node) {
                oldParentNode.*.child = thisNode.next;
            } else {
                // otherwise remove ourselves from the linked list
                self.nodes.get(thisNode.prev).?.*.next = thisNode.next;
            }
        }

        // assign ourselves the new parent
        self.nodes.get(node).?.*.parent = parent;

        if (parentNode.*.child == 0) {
            parentNode.*.child = node;
        } else {
            self.nodes.get(parentNode.*.end).?.*.next = node;
            thisNode.*.prev = parentNode.*.end;
        }

        parentNode.*.end = node;
    }

    // helper functions for a whole bunch of shit
    pub fn addButton(self: *@This(), text: LocText) !u32 {
        var button = NodeProperty_Button{ .text = text };
        return try self.nodes.new(.{ .nodeType = .{ .Button = button } });
    }

    pub fn removeFromParent(self: *@This(), node: u32) !void {
        // this also deletes all children
        // 1. gather all children.
        try assertf(node != 0, "removeFromParent CANNOT be called on the root node", .{});

        var killList = std.ArrayList(u32).init(self.allocator);
        defer killList.deinit();
        self.walkNodesToRemove(node, &killList) catch {
            for (killList.items) |n| {
                std.debug.print("{d}, ", .{n});
            }
            return error.BadWalk;
        };

        var thisNode = self.getRead(node);
        self.get(thisNode.next).prev = thisNode.prev;
        self.get(thisNode.prev).next = thisNode.next;

        {
            var parent = self.get(thisNode.parent);

            if (parent.child == node) {
                parent.child = thisNode.next;
            }

            if (parent.end == node) {
                parent.end = thisNode.prev;
            }
        }

        for (killList.items) |killed| {
            self.nodes.destroy(killed);
        }
    }

    fn walkNodesToRemove(self: @This(), root: u32, killList: *std.ArrayList(u32)) !void {
        try killList.append(root);

        var next = self.getRead(root).child;

        while (next != 0) {
            try self.walkNodesToRemove(next, killList);
            next = self.getRead(next).next;
        }
    }

    // ============================= Rendering and Layout ==================
    pub const DrawCommand = struct {
        node: u32,
        primitive: union(enum(u8)) {
            Rect: struct {
                tl: Vector2,
                size: Vector2,
                borderColor: Color,
                backgroundColor: Color,
                rounding: struct {
                    tl: f32 = 0,
                    tr: f32 = 0,
                    bl: f32 = 0,
                    br: f32 = 0,
                } = .{},
            },
            Text: struct {
                tl: Vector2,
                size: Vector2,
                text: LocText,
                color: Color,
                textSize: f32,
                rendererHash: u32,
            },
        },
    };
    pub const DrawList = std.ArrayList(DrawCommand);
    const DrawOrderList = std.ArrayList(u32);

    fn assembleDrawOrderListForNode(self: @This(), node: u32, list: *DrawOrderList) !void {
        var next: u32 = self.getRead(node).child;
        while (next != 0) : (next = self.getRead(next).next) {
            try list.append(next);
            try self.assembleDrawOrderListForNode(next, list);
        }
    }

    fn assembleDrawOrderList(self: @This(), list: *DrawOrderList) !void {
        var rootNodes = std.ArrayList(u32).init(self.allocator);
        defer rootNodes.deinit();

        var next: u32 = self.getRead(0).child;
        while (next != 0) : (next = self.getRead(next).next) {
            try rootNodes.append(next);
        }

        const SortFunc = struct {
            pub fn lessThan(ctx: PapyrusContext, lhs: u32, rhs: u32) bool {
                return ctx.getRead(lhs).zOrder < ctx.getRead(rhs).zOrder;
            }
        };

        std.sort.insertion(
            u32,
            rootNodes.items,
            self,
            SortFunc.lessThan,
        );

        for (rootNodes.items) |rootNode| {
            try list.append(rootNode);
            try self.assembleDrawOrderListForNode(rootNode, list);
        }
    }

    const PosSize = struct {
        pos: Vector2,
        size: Vector2,
    };

    fn resolveAnchoredPosition(parent: PosSize, node: *const PapyrusNode) Vector2 {
        switch (node.anchor) {
            .Free => {
                return node.pos;
            },
            .TopLeft => {
                return parent.pos.add(node.pos);
            },
            .MidLeft => {
                return parent.pos.add(.{ .y = parent.size.y / 2 }).add(node.pos);
            },
            .BotLeft => {
                return parent.pos.add(.{ .y = parent.size.y }).add(node.pos);
            },
            .TopMiddle => {
                return parent.pos.add(.{ .x = parent.size.x / 2 }).add(node.pos);
            },
            .MidMiddle => {
                return parent.pos.add(.{ .x = parent.size.x / 2, .y = parent.size.y / 2 }).add(node.pos);
            },
            .BotMiddle => {
                return parent.pos.add(.{ .x = parent.size.x / 2, .y = parent.size.y }).add(node.pos);
            },
            .TopRight => {
                return parent.pos.add(.{ .x = parent.size.x }).add(node.pos);
            },
            .MidRight => {
                return parent.pos.add(.{ .x = parent.size.x, .y = parent.size.y / 2 }).add(node.pos);
            },
            .BotRight => {
                return parent.pos.add(.{ .x = parent.size.x, .y = parent.size.y }).add(node.pos);
            },
        }
    }

    fn resolveAnchoredSize(parent: PosSize, node: *const PapyrusNode) Vector2 {
        switch (node.fill) {
            .None => {
                return node.size;
            },
            .FillX => {
                return .{ .x = node.size.x * parent.size.x, .y = node.size.y };
            },
            .FillY => {
                return .{ .x = node.size.x, .y = node.size.y * parent.size.y };
            },
            .FillXY => {
                return node.size.mul(parent.size);
            },
        }
    }

    const DebugDrawList: bool = true;

    pub fn makeDrawList(self: *@This(), drawList: *DrawList) !void {
        // do not re allocate these, instead use a preallocated pool
        self._drawOrder.clearRetainingCapacity();
        self._layout.clearRetainingCapacity();

        try self.assembleDrawOrderList(&self._drawOrder);

        var layout = std.AutoHashMap(u32, PosSize).init(self.allocator);
        defer layout.deinit();

        try layout.put(0, .{ .pos = .{ .x = 0, .y = 0 }, .size = Vector2.fromVector2i(self.extent) });

        drawList.clearRetainingCapacity();

        for (self._drawOrder.items) |node| {
            var n = self.getRead(node);

            if (n.state == .Hidden) {
                continue;
            }

            var parentInfo = layout.get(n.parent).?;

            var resolvedPos = resolveAnchoredPosition(parentInfo, n);
            var resolvedSize = resolveAnchoredSize(parentInfo, n);

            switch (n.nodeType) {
                .Panel => |panel| {
                    if (panel.hasTitle) {
                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = resolvedPos.add(.{ .y = panel.titleSize }),
                                .size = resolvedSize.sub(.{ .y = panel.titleSize }),
                                .borderColor = n.style.borderColor,
                                .backgroundColor = n.style.backgroundColor,
                            },
                        } });

                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = resolvedPos,
                                .size = .{ .x = resolvedSize.x, .y = panel.titleSize },
                                .borderColor = n.style.borderColor,
                                .backgroundColor = n.style.borderColor,
                                .rounding = .{ .tl = 10, .tr = 10 },
                            },
                        } });

                        try drawList.append(.{ .node = node, .primitive = .{
                            .Text = .{
                                .tl = resolvedPos.add(.{ .x = 3 + 5, .y = 1 }),
                                .size = .{ .x = resolvedSize.x, .y = panel.titleSize },
                                .text = n.text,
                                .color = panel.titleColor,
                                .textSize = panel.titleSize - 3,
                                .rendererHash = panel.font.rendererHash,
                            },
                        } });

                        try layout.put(node, .{
                            .pos = resolvedPos.add(.{ .y = panel.titleSize }).add(Vector2.Ones),
                            .size = resolvedSize.sub(.{ .y = -panel.titleSize }).add(Vector2.Ones),
                        });
                    } else {
                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = resolvedPos,
                                .size = resolvedSize,
                                .borderColor = n.style.borderColor,
                                .backgroundColor = n.style.backgroundColor,
                            },
                        } });

                        try layout.put(node, .{
                            .pos = resolvedPos.add(Vector2.Ones),
                            .size = resolvedSize.add(Vector2.Ones),
                        });
                    }
                },
                .DisplayText => |txt| {
                    try drawList.append(.{ .node = node, .primitive = .{
                        .Text = .{
                            .tl = resolvedPos,
                            .size = n.size,
                            .text = n.text,
                            .color = n.style.foregroundColor,
                            .textSize = txt.textSize - 3,
                            .rendererHash = txt.font.atlas.rendererHash,
                        },
                    } });

                    try layout.put(node, .{
                        .pos = resolvedPos.add(Vector2.Ones),
                        .size = resolvedSize.add(Vector2.Ones),
                    });
                },
                .Slot, .Button => {},
            }
        }

        if (DebugDrawList) {
            try self.addDebugInfo(drawList);
        }
    }

    pub fn addDebugInfo(self: @This(), drawList: *PapyrusContext.DrawList) !void {
        const offsetPerLine: f32 = 50.0;
        var yOffset: f32 = offsetPerLine;
        try drawList.append(.{
            .node = 0,
            .primitive = .{
                .Rect = .{
                    .tl = .{ .x = 30 - 3, .y = yOffset - 3 },
                    .size = .{ .x = 500 + 5, .y = offsetPerLine * @as(f32, @floatFromInt(self.debugTextCount + 2)) },
                    .borderColor = Color.Yellow,
                    .backgroundColor = Color.Black,
                },
            },
        });

        try drawList.append(.{
            .node = 0,
            .primitive = .{
                .Text = .{
                    .text = LocText.fromUtf8("Papyrus Debug:"),
                    .tl = .{ .x = 30, .y = yOffset },
                    .size = .{ .x = 500, .y = 30 },
                    .color = BurnStyle.Highlight3,
                    .textSize = 18,
                    .rendererHash = self.fallbackFont.atlas.rendererHash,
                },
            },
        });

        yOffset += offsetPerLine;

        for (self.debugText.items, 0..) |textData, i| {
            if (i >= self.debugTextCount) {
                break;
            }

            try drawList.append(.{
                .node = 0,
                .primitive = .{
                    .Text = .{
                        .text = LocText.fromUtf8Z(textData),
                        .tl = .{ .x = 30, .y = yOffset },
                        .size = .{ .x = 500, .y = 30 },
                        .color = BurnStyle.Highlight3,
                        .textSize = 18,
                        .rendererHash = self.fallbackFont.atlas.rendererHash,
                    },
                },
            });
            yOffset += offsetPerLine + (offsetPerLine / 4);
        }
    }

    pub fn printTree(self: @This(), root: u32) void {
        std.debug.print("\n ==== tree ==== \n", .{});
        self.printTreeInner(root, 0);
        std.debug.print(" ==== /tree ====   \n\n", .{});
    }

    fn printTreeInner(self: @This(), root: u32, indentLevel: u32) void {
        var i: u32 = 0;
        while (i < indentLevel) : (i += 1) {
            std.debug.print(" ", .{});
        }

        const node = self.getRead(root);
        std.debug.print("> {d}: {s}\n", .{ root, node.text.getRead() });

        var next = node.child;
        while (next != 0) {
            self.printTreeInner(next, indentLevel + 1);
            next = self.getRead(next).*.next;
        }
    }

    pub fn writeTree(self: @This(), root: u32, outFile: []const u8) !void {
        var log = try FileLog.init(self.allocator, outFile);
        defer log.deinit();

        try log.write("digraph G {{\n", .{});
        try self.writeTreeInner(root, &log);
        try log.write("}}\n", .{});

        try log.writeOut();
    }

    fn writeTreeInner(self: @This(), root: u32, log: *FileLog) !void {
        var node = self.getRead(root);
        try log.write("  {s}->{s}", .{ self.getRead(node.parent).text.getRead(), node.text.getRead() });

        var next = node.child;
        while (next != 0) {
            try self.writeTreeInner(next, log);
            next = self.getRead(next).*.next;
        }
    }

    // Sets the current cursor location
    pub fn setCursorLocation(self: *@This(), position: Vector2) void {
        self.currentCursorPosition = position;
    }
};

pub fn getContext() *PapyrusContext {
    try assertf(gPapyrusIsInitialized == true, "Unable to initialize Papyrus, already initialized", .{});
    return gPapyrusContext;
}

pub fn initialize(allocator: std.mem.Allocator) !*PapyrusContext {
    try assertf(gPapyrusIsInitialized == false, "Unable to initialize Papyrus, already initialized", .{});
    gPapyrusIsInitialized = true;
    gPapyrusContext = try PapyrusContext.create(allocator);
    return gPapyrusContext;
}

pub fn deinitialize() void {
    gPapyrusContext.deinit();
}
