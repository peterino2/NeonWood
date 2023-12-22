const std = @import("std");
const c = @cImport({
    @cInclude("stb_ttf.h");
});

pub const PapyrusLayout = @import("PapyrusMousePick.zig");
pub const PapyrusEvent = @import("PapyrusEvent.zig");

pub usingnamespace PapyrusEvent;

pub const PapyrusFont = @import("PapyrusFont.zig");
pub const FontAtlas = PapyrusFont.FontAtlas;
pub const BmpRenderer = @import("BmpRenderer.zig");
pub const BmpWriter = BmpRenderer.BmpWriter;

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

const core = @import("root").neonwood.core;
const Vector2i = core.Vector2i;
const Vector2f = core.Vector2f;
const IndexPool = core.IndexPool;
const Name = core.Name;

pub const NodeHandle = core.IndexPoolHandle;

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
    FillX,      // Size will scale to X scaling of the parent (relative to reference), if set, then the size value of x will be interpreted as a percentage of the parent
    FillY,      // Size will scale to Y scaling of the parent (relative to reference), if set, then the size value of y will be interpreted as a percentage of the parent
    FillXY,     // Size will scale to both X and Y of the parent (relative to reference), if set, then the size value of both x and y will be interpreted as a percentage of the parent
    UniformX,   // Size will scale both X and Y based on a ratio of the parent's current X vs the parent's original X
    UniformY,   // Size will scale both X and Y based on a ratio of the parent's current Y vs the parent's original Y
    // zig fmt: on
};

// When this element is used as part of a VBox it's left/right position
// shall be arranged according this justificiation value
pub const PapyrusNodeJustify = enum {
    // zig fmt: off
    Left,
    Center,
    Right,
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
    titleSize: f32 = 20,
    layoutMode: ChildLayout = .Free, // when set to anything other than free, we will override anchors from inferior nodes.
    hasTitle: bool = false,
    font: *FontAtlas,
    useImage: bool = false,
    imageReference: core.Name, // Image resource reference
    rounding: struct {
        tl: f32 = 0,
        tr: f32 = 0,
        bl: f32 = 0,
        br: f32 = 0,
    } = .{}, // rounding
};

pub const NodePropertiesBag = union(enum(u8)) {
    Slot: NodeProperty_Slot,
    DisplayText: NodeProperty_Text,
    Button: NodeProperty_Button,
    Panel: NodeProperty_Panel,
};

pub const NodePadding = union(enum(u8)) {
    topLeft: Vector2f,
    botLeft: Vector2f,
    all: f32,
    allSides: [2]Vector2f,
};

pub const PapyrusNodeStyle = struct {
    foregroundColor: Color = BurnStyle.Normal,
    backgroundColor: Color = BurnStyle.SlateGrey,
    borderColor: Color = BurnStyle.Bright2,
};

pub const PapyrusTextRenderMode = enum {
    Simple,
    NoControl,
    Rich,
};

// this is going to follow a pretty object-oriented-like user facing api
pub const PapyrusNode = struct {
    text: LocText = MakeText("hello world"),
    textMode: PapyrusTextRenderMode = .Simple,
    textRenderedSize: Vector2f = .{ .x = 0.0, .y = 0.0 },

    parent: NodeHandle = .{}, // 0 corresponds to true root

    // all children of the same parent operate as a doubly linked list
    child: NodeHandle = .{},
    end: NodeHandle = .{},
    next: NodeHandle = .{},
    prev: NodeHandle = .{},

    zOrder: i32 = 0, // higher number is rendered on top.

    // Not sure what's the best way to go about this.
    // I want to provide good design time metrics
    // which can scale into good runtime metrics

    // Resolutions and scalings are a real headspinner
    // DPI awareness and content scaling is also a huge problem.
    baseSize: Vector2f = .{ .x = 0, .y = 0 },
    sizeInitialized: bool = false,
    size: Vector2f = .{ .x = 0, .y = 0 },

    justify: PapyrusNodeJustify = .Center,

    pos: Vector2f = .{ .x = 0, .y = 0 },
    anchor: PapyrusAnchorNode = .TopLeft,
    originAnchor: PapyrusAnchorNode = .TopLeft, // This specifies where within this node is used for an anchor.
    originOffset: Vector2f = .{}, // this specifies an offset from the chosen origin position
    fill: PapyrusFillMode = .None,
    layoutPadding: f32 = 5.0,

    // padding is the external
    padding: NodePadding = .{ .all = 0 },

    state: PapyrusState = .Visible,
    hittest: PapyrusHitTestability = .Testable,
    dockingPolicy: enum { Dockable, NotDockable } = .Dockable,

    // standard styling options that all nodes have
    style: PapyrusNodeStyle = .{},

    nodeType: NodePropertiesBag,

    pub fn setSize(self: *@This(), s: Vector2f) void {
        if (!self.sizeInitialized) {
            self.baseSize = s;
            self.sizeInitialized = true;
        }

        self.size = s;
    }
};

// final resolved size
const LayoutInfo = struct {
    baseSize: Vector2f,
    pos: Vector2f,
    size: Vector2f,
    childLayoutOffsets: Vector2f,
};

pub const PapyrusContext = struct {
    backingAllocator: std.mem.Allocator,
    allocator: std.mem.Allocator,
    nodes: IndexPool(PapyrusNode),
    fonts: std.AutoHashMap(u32, PapyrusFont),
    fallbackFont: PapyrusFont,
    defaultMonoFont: PapyrusFont,
    extent: Vector2i = .{ .x = 1920, .y = 1080 },
    currentCursorPosition: Vector2f = .{},

    mousePick: PapyrusLayout,

    events: PapyrusEvent,

    // internals
    _drawOrder: DrawOrderList,
    _layoutNodes: std.ArrayListUnmanaged(NodeHandle),
    _layout: std.ArrayListUnmanaged(LayoutInfo), // bad name, this is used for hittest, not display
    _layoutPositions: std.AutoHashMapUnmanaged(NodeHandle, LayoutInfo),
    _displayLayout: std.ArrayListUnmanaged(LayoutInfo) = .{},

    debugText: std.ArrayList([]u8),
    debugTextCount: u32 = 0,
    drawDebug: bool = false,

    const debugTextMax = 32;

    pub fn tick(self: *@This(), deltaTime: f64) !void {
        try self.mousePick.tick(self, deltaTime);

        self.clearDebugText();
        try self.pushDebugText("mouse Position: {d}, {d}", .{ self.currentCursorPosition.x, self.currentCursorPosition.y });
        if (self.mousePick.found) {
            const node = self.mousePick.selectedNode;
            const n = self.getRead(node);
            const layout = self._displayLayout.items[node.index];
            try self.pushDebugText("found node: {d},{d} size={d}x{d} layoutpos={d},{d} layoutsize={d},{d}", .{
                node.index,
                node.generation,
                n.size.x,
                n.size.y,
                layout.pos.x,
                layout.pos.y,
                layout.size.x,
                layout.size.y,
            });
        }
    }

    pub fn create(backingAllocator: std.mem.Allocator) !*@This() {
        const fallbackFontName: []const u8 = "default";

        const defaultMonoName: []const u8 = "monospace";

        var self = try backingAllocator.create(@This());
        var allocator = backingAllocator;

        self.* = .{
            .allocator = allocator,
            .backingAllocator = allocator,
            .nodes = IndexPool(PapyrusNode).init(allocator),
            .fonts = std.AutoHashMap(u32, PapyrusFont).init(allocator),
            .events = PapyrusEvent.init(allocator),
            .fallbackFont = PapyrusFont{
                .name = Name.fromUtf8(fallbackFontName),
                .atlas = try allocator.create(FontAtlas),
            },
            .defaultMonoFont = PapyrusFont{
                .name = Name.fromUtf8(defaultMonoName),
                .atlas = try allocator.create(FontAtlas),
            },
            ._drawOrder = DrawOrderList.init(allocator),
            ._layout = .{},
            ._layoutNodes = .{},
            ._layoutPositions = .{},
            .debugText = std.ArrayList([]u8).init(allocator),
            .mousePick = PapyrusLayout.init(allocator),
        };

        for (0..debugTextMax) |_| {
            var textBuffer = try allocator.alloc(u8, 512);
            try self.debugText.append(textBuffer);
        }

        self.fallbackFont.atlas.* = try FontAtlas.initDefaultFont(allocator, 64);
        try self.installFontAtlas(self.fallbackFont.name.utf8(), self.fallbackFont.atlas);

        self.defaultMonoFont.atlas.* = try FontAtlas.initMonoFont(allocator, 64);
        try self.installFontAtlas(self.defaultMonoFont.name.utf8(), self.defaultMonoFont.atlas);

        // constructing the root node
        _ = try self.nodes.new(.{
            .text = MakeText("root"),
            .parent = .{},
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

    pub fn deinit(self: *@This()) void {
        self.mousePick.deinit();

        var iter = self.fonts.iterator();
        while (iter.next()) |i| {
            i.value_ptr.atlas.deinit();
            self.allocator.destroy(i.value_ptr.atlas);
        }

        self.fonts.deinit();
        self.nodes.deinit();
        self.events.deinit();
        self._drawOrder.deinit();
        self._layout.deinit(self.allocator);
        self._layoutNodes.deinit(self.allocator);
        self._layoutPositions.deinit(self.allocator);

        for (self.debugText.items) |text| {
            self.allocator.free(text);
        }
        self.debugText.deinit();
        self.backingAllocator.destroy(self);
    }

    pub fn installFontAtlas(self: *@This(), fontName: []const u8, atlas: *FontAtlas) !void {
        const name = Name.fromUtf8(fontName);
        try self.fonts.put(name.handle(), .{ .atlas = atlas, .name = name });
    }

    pub fn fetchPanel(self: *@This(), handle: NodeHandle) ?*NodeProperty_Panel {
        if (self.nodes.get(handle)) |node| {
            switch (node.nodeType) {
                .Panel => {
                    return &(node.nodeType.Panel);
                },
                else => {
                    return null;
                },
            }
        }
        return null;
    }

    pub fn isValid(self: @This(), handle: NodeHandle) bool {
        return self.nodes.isValid(handle);
    }

    pub fn getPanel(self: *@This(), handle: NodeHandle) *NodeProperty_Panel {
        return &(self.nodes.get(handle).?.nodeType.Panel);
    }

    pub fn getText(self: *@This(), handle: NodeHandle) *NodeProperty_Text {
        return &(self.nodes.get(handle).?.nodeType.DisplayText);
    }

    pub fn setFont(self: *@This(), handle: NodeHandle, font: []const u8) void {
        const name = Name.fromUtf8(font);

        switch (self.nodes.get(handle).?.nodeType) {
            .DisplayText => {
                var text = &(self.nodes.get(handle).?.nodeType.DisplayText);
                text.font = .{
                    .name = name,
                    .atlas = (self.fonts.get(name.handle()) orelse self.fonts.get(Name.fromUtf8("default").handle()).?).atlas,
                };
            },
            .Panel => {
                var panel = &(self.nodes.get(handle).?.nodeType.Panel);
                panel.font = self.fonts.get(name.handle()).?.atlas;
            },
            else => {},
        }
    }

    // converts a handle to a node pointer
    // invalid after AddNode
    pub fn get(self: *@This(), handle: NodeHandle) *PapyrusNode {
        return self.nodes.get(handle).?;
    }

    // gets a node as read only
    pub fn getRead(self: @This(), handle: NodeHandle) *const PapyrusNode {
        return self.nodes.getRead(handle).?;
    }

    fn newNode(self: *@This(), node: PapyrusNode) !NodeHandle {
        return try self.nodes.new(node);
    }

    pub fn addSlot(self: *@This(), parent: NodeHandle) !NodeHandle {
        var slotNode = PapyrusNode{ .nodeType = .{ .Slot = .{} } };
        var slot = try self.newNode(slotNode);

        try self.setParent(slot, parent);

        return slot;
    }

    pub fn addText(self: *@This(), parent: NodeHandle, text: []const u8) !NodeHandle {
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

    pub fn addPanel(self: *@This(), parent: NodeHandle) !NodeHandle {
        var slotNode = PapyrusNode{ .nodeType = .{ .Panel = .{
            .font = self.fallbackFont.atlas,
            .imageReference = core.NameInvalid,
        } } };

        if (parent.index == 0) {
            slotNode.anchor = .Free;
        }
        var slot = try self.nodes.new(slotNode);

        try self.setParent(slot, parent);

        return slot;
    }

    pub fn setParent(self: *@This(), node: NodeHandle, parent: NodeHandle) !void {
        try assertf(
            self.nodes.get(parent) != null,
            "tried to assign node {d}.{d} to parent {d}.{d} but parent does not exist",
            .{ node.index, node.generation, parent.index, parent.generation },
        );

        try assertf(
            self.nodes.get(node) != null,
            "tried to assign node {d}.{d} to parent {d}.{d} but node does not exist",
            .{ node.index, node.generation, parent.index, parent.generation },
        );

        var parentNode = self.nodes.get(parent).?;
        var thisNode = self.nodes.get(node).?;

        // if we have a previous parent, remove ourselves
        if (thisNode.*.parent.index != 0) {
            // remove myself from that parent.
            var oldParentNode = self.nodes.get(thisNode.*.parent).?;

            // special case for when we're the first child element
            if (oldParentNode.*.child.index == node.index) {
                oldParentNode.*.child = thisNode.next;
            } else {
                // otherwise remove ourselves from the linked list
                self.nodes.get(thisNode.prev).?.*.next = thisNode.next;
            }
        }

        // assign ourselves the new parent
        self.nodes.get(node).?.*.parent = parent;

        if (parentNode.*.child.index == 0) {
            parentNode.*.child = node;
        } else {
            self.nodes.get(parentNode.*.end).?.*.next = node;
            thisNode.*.prev = parentNode.*.end;
        }

        parentNode.*.end = node;
    }

    // helper functions for a whole bunch of shit
    pub fn addButton(self: *@This(), text: LocText) !NodeHandle {
        var button = NodeProperty_Button{ .text = text };
        return try self.nodes.new(.{ .nodeType = .{ .Button = button } });
    }

    pub fn removeFromParent(self: *@This(), node: NodeHandle) !void {
        // this also deletes all children
        // 1. gather all children.

        if (!self.nodes.isValid(node)) {
            return;
        }

        try assertf(node.index != 0, "removeFromParent CANNOT be called on the root node", .{});

        var killList = std.ArrayList(NodeHandle).init(self.allocator);
        defer killList.deinit();
        self.walkNodesToRemove(node, &killList) catch {
            for (killList.items) |n| {
                _ = n;
            }
            return error.BadWalk;
        };

        var thisNode = self.getRead(node);
        self.get(thisNode.next).prev = thisNode.prev;
        self.get(thisNode.prev).next = thisNode.next;

        {
            var parent = self.get(thisNode.parent);

            if (parent.child.eql(node)) {
                parent.child = thisNode.next;
            }

            if (parent.end.eql(node)) {
                parent.end = thisNode.prev;
            }
        }

        for (killList.items) |killed| {
            self.nodes.destroy(killed);
        }
    }

    fn walkNodesToRemove(self: @This(), root: NodeHandle, killList: *std.ArrayList(NodeHandle)) !void {
        try killList.append(root);

        var next = self.getRead(root).child;

        while (next.index != 0) {
            try self.walkNodesToRemove(next, killList);
            next = self.getRead(next).next;
        }
    }

    // ============================= Rendering and Layout ==================
    pub const DrawCommand = struct {
        node: NodeHandle,
        primitive: union(enum(u8)) {
            Rect: struct {
                tl: Vector2f,
                size: Vector2f,
                borderColor: Color,
                backgroundColor: Color,
                rounding: struct {
                    tl: f32 = 0,
                    tr: f32 = 0,
                    bl: f32 = 0,
                    br: f32 = 0,
                } = .{},
                imageRef: ?core.Name = null,
            },
            Text: struct {
                tl: Vector2f,
                size: Vector2f,
                renderMode: PapyrusTextRenderMode,
                text: LocText,
                color: Color,
                textSize: f32,
                rendererHash: u32,
            },
        },
    };
    pub const DrawList = std.ArrayList(DrawCommand);
    const DrawOrderList = std.ArrayList(NodeHandle);

    fn assembleDrawOrderListForNode(self: @This(), node: NodeHandle, list: *DrawOrderList) !void {
        var next: NodeHandle = self.getRead(node).child;
        while (next.index != 0) : (next = self.getRead(next).next) {
            try list.append(next);
            try self.assembleDrawOrderListForNode(next, list);
        }
    }

    fn assembleDrawOrderList(self: @This(), list: *DrawOrderList) !void {
        var rootNodes = std.ArrayList(NodeHandle).init(self.allocator);
        defer rootNodes.deinit();

        var next: NodeHandle = self.getRead(.{}).child;
        while (next.index != 0) : (next = self.getRead(next).next) {
            try rootNodes.append(next);
        }

        const SortFunc = struct {
            pub fn lessThan(ctx: PapyrusContext, lhs: NodeHandle, rhs: NodeHandle) bool {
                return ctx.getRead(lhs).zOrder < ctx.getRead(rhs).zOrder;
            }
        };

        std.sort.insertion(
            NodeHandle,
            rootNodes.items,
            self,
            SortFunc.lessThan,
        );

        for (rootNodes.items) |rootNode| {
            try list.append(rootNode);
            try self.assembleDrawOrderListForNode(rootNode, list);
        }
    }

    fn resolveAnchoredPosition(parent: LayoutInfo, node: *const PapyrusNode) Vector2f {
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

    pub fn onKey(self: *@This(), keycode: PapyrusEvent.Key, eventType: PapyrusEvent.PressedEventType) !void {
        if (self.mousePick.found) {
            try self.events.pushPressedEvent(self.mousePick.selectedNode, eventType, keycode);
        }
    }

    fn resolveAnchoredSize(parent: LayoutInfo, node: *const PapyrusNode) Vector2f {
        switch (node.fill) {
            .None => {
                return node.size;
            },
            .FillX => {
                return .{ .x = node.size.x * parent.size.x / parent.baseSize.x, .y = node.size.y };
            },
            .FillY => {
                return .{ .x = node.size.x, .y = node.size.y * parent.size.y / parent.baseSize.y };
            },
            .FillXY => {
                return node.size.vmul(parent.size);
            },
            .UniformX => {
                return node.size.fmul(parent.size.x / parent.baseSize.x);
            },
            .UniformY => {
                return node.size.fmul(parent.size.y / parent.baseSize.y);
            },
        }
    }

    const ChildLayoutRulesStruct = struct {
        position: Vector2f,
        size: Vector2f,
    };

    pub fn applyLayoutRulesAsChild(
        self: *@This(),
        parentAsPanel: *NodeProperty_Panel,
        n: *const PapyrusNode,
        resolvedSize: Vector2f,
        resolvedPos: Vector2f,
    ) ChildLayoutRulesStruct {
        _ = resolvedPos;
        var parentInfo = &self._displayLayout.items[n.parent.index];

        switch (parentAsPanel.layoutMode) {
            .Vertical => {
                var offsetX: f32 = 0.0;

                switch (n.justify) {
                    .Left => {
                        offsetX = n.pos.x;
                    },
                    .Center => {
                        offsetX = n.pos.x + @divFloor(parentInfo.size.x - resolvedSize.x, 2);
                    },
                    .Right => {
                        offsetX = n.pos.x + parentInfo.size.x - resolvedSize.x + offsetX - 1;
                    },
                }

                var rv = ChildLayoutRulesStruct{
                    .position = parentInfo.pos.add(.{
                        .x = offsetX,
                        .y = parentInfo.childLayoutOffsets.y,
                    }),
                    .size = resolvedSize,
                };

                // Make one more adjustment to the offsetX position based on the  justification.
                // Justification is taken from the AnchorMode.

                parentInfo.childLayoutOffsets.y += resolvedSize.y + self.get(n.parent).layoutPadding;

                return rv;
            },
            .Horizontal => {},
            .Free => {},
        }

        return .{
            .size = resolveAnchoredSize(parentInfo.*, n),
            .position = resolveAnchoredPosition(parentInfo.*, n),
        };
    }

    pub fn makeDrawList(self: *@This(), drawList: *DrawList) !void {
        // do not re allocate these, instead use a preallocated pool
        self._drawOrder.clearRetainingCapacity();
        self._layout.clearRetainingCapacity();
        self._layoutNodes.clearRetainingCapacity();
        self._displayLayout.clearRetainingCapacity();

        try self.assembleDrawOrderList(&self._drawOrder);

        // todo: remove this layout hashmap, stash it in the main context.
        try self._displayLayout.resize(self.allocator, self.nodes.count());

        self._displayLayout.items[0] = .{
            .pos = .{ .x = 0, .y = 0 },
            .size = Vector2f.from(self.extent),
            .baseSize = Vector2f.from(self.extent),
            .childLayoutOffsets = .{},
        };

        drawList.clearRetainingCapacity();

        for (self._drawOrder.items) |node| {
            var n = self.getRead(node);

            if (n.state == .Hidden) {
                continue;
            }

            var parentInfo = self._displayLayout.items[n.parent.index];

            // First, resolve positions and size as if it was a simple layout.
            var resolvedSize = resolveAnchoredSize(parentInfo, n);
            var resolvedPos = resolveAnchoredPosition(parentInfo, n);

            // if our parent is a panel then apply layout rules to it.
            if (self.fetchPanel(n.parent)) |parentAsPanel| {
                var results = self.applyLayoutRulesAsChild(parentAsPanel, n, resolvedSize, resolvedPos);
                resolvedPos = results.position;
                resolvedSize = results.size;
            }

            switch (n.nodeType) {
                .Panel => |panel| {
                    try self._layout.append(self.allocator, .{
                        .baseSize = n.baseSize,
                        .pos = resolvedPos,
                        .size = resolvedSize,
                        .childLayoutOffsets = .{},
                    });
                    try self._layoutNodes.append(self.allocator, node);
                    try self._layoutPositions.put(
                        self.allocator,
                        node,
                        .{
                            .pos = resolvedPos,
                            .size = resolvedSize,
                            .baseSize = n.baseSize,
                            .childLayoutOffsets = .{},
                        },
                    );

                    if (panel.hasTitle) {

                        // draw the main image.
                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = resolvedPos.add(.{ .y = panel.titleSize }),
                                .size = resolvedSize.sub(.{ .y = panel.titleSize }),
                                .borderColor = n.style.borderColor,
                                .backgroundColor = n.style.backgroundColor,
                                .rounding = .{
                                    .bl = panel.rounding.bl,
                                    .br = panel.rounding.br,
                                },
                                .imageRef = if (panel.useImage) panel.imageReference else null,
                            },
                        } });

                        // draw the title bar
                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = resolvedPos,
                                .size = .{ .x = resolvedSize.x, .y = panel.titleSize },
                                .borderColor = n.style.borderColor,
                                .backgroundColor = n.style.borderColor,
                                .rounding = .{
                                    .tl = panel.rounding.tl,
                                    .tr = panel.rounding.tr,
                                },
                            },
                        } });

                        try drawList.append(.{ .node = node, .primitive = .{
                            .Text = .{
                                .tl = resolvedPos.add(.{ .x = 3 + 5, .y = 3 }),
                                .size = .{ .x = resolvedSize.x, .y = panel.titleSize },
                                .text = n.text,
                                .renderMode = n.textMode,
                                .color = panel.titleColor,
                                .textSize = panel.titleSize - 4,
                                .rendererHash = panel.font.rendererHash,
                            },
                        } });

                        self._displayLayout.items[node.index] = .{
                            .baseSize = n.baseSize,
                            .pos = resolvedPos.add(.{ .y = panel.titleSize }).add(Vector2f.Ones),
                            .size = resolvedSize.sub(.{ .y = -panel.titleSize }).sub(Vector2f.Ones).sub(.{ .x = 0, .y = 30 }),
                            .childLayoutOffsets = .{},
                        };
                    } else {

                        // draw the main image
                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = resolvedPos,
                                .size = resolvedSize,
                                .borderColor = n.style.borderColor,
                                .backgroundColor = n.style.backgroundColor,
                                .rounding = .{
                                    .tl = panel.rounding.tl,
                                    .tr = panel.rounding.tr,
                                    .bl = panel.rounding.bl,
                                    .br = panel.rounding.br,
                                },
                                .imageRef = if (panel.useImage) panel.imageReference else null,
                            },
                        } });

                        self._displayLayout.items[node.index] = .{
                            .baseSize = n.baseSize,
                            .pos = resolvedPos.add(Vector2f.Ones),
                            .size = resolvedSize.sub(Vector2f.Ones.fmul(2)),
                            .childLayoutOffsets = .{},
                        };
                    }
                },
                .DisplayText => |txt| {
                    try drawList.append(.{ .node = node, .primitive = .{
                        .Text = .{
                            .tl = resolvedPos,
                            .size = n.size,
                            .text = n.text,
                            .renderMode = n.textMode,
                            .color = n.style.foregroundColor,
                            .textSize = txt.textSize,
                            .rendererHash = txt.font.atlas.rendererHash,
                        },
                    } });

                    self._displayLayout.items[node.index] = .{
                        .baseSize = n.baseSize,
                        .pos = resolvedPos.add(Vector2f.Ones),
                        .size = resolvedSize.add(Vector2f.Ones),
                        .childLayoutOffsets = .{},
                    };
                },
                .Slot, .Button => {},
            }
        }

        if (self.drawDebug) {
            try self.addDebugInfo(drawList);
        }
    }

    fn addDebugInfo(self: @This(), drawList: *PapyrusContext.DrawList) !void {
        const defaultHeight = 16;
        const offsetPerLine: f32 = defaultHeight + 2;
        var yOffset: f32 = offsetPerLine;
        const width = defaultHeight / 2 * 120;

        var fontHash = self.defaultMonoFont.atlas.rendererHash;

        try self.mousePick.addMousePickInfo(&self, drawList);

        try drawList.append(.{
            .node = .{},
            .primitive = .{
                .Rect = .{
                    .tl = .{ .x = 30 - 5, .y = yOffset - 5 },
                    .size = .{ .x = width + 5, .y = offsetPerLine * @as(f32, @floatFromInt(self.debugTextCount + 2)) },
                    .borderColor = Color.fromRGBA(0x222222ee),
                    .backgroundColor = Color.fromRGBA2(0.0, 0.0, 0.0, 0.9),
                },
            },
        });

        try drawList.append(.{
            .node = .{},
            .primitive = .{
                .Text = .{
                    .text = LocText.fromUtf8("Papyrus Debug:"),
                    .tl = .{ .x = 30, .y = yOffset },
                    .size = .{ .x = width, .y = 30 },
                    .renderMode = .NoControl,
                    //.color = BurnStyle.Highlight3,
                    .color = Color.Yellow,
                    .textSize = defaultHeight,
                    .rendererHash = fontHash,
                },
            },
        });

        yOffset += offsetPerLine;

        for (self.debugText.items, 0..) |textData, i| {
            if (i >= self.debugTextCount) {
                break;
            }

            try drawList.append(.{
                .node = .{},
                .primitive = .{
                    .Text = .{
                        .text = LocText.fromUtf8Z(textData),
                        .tl = .{ .x = 30, .y = yOffset },
                        .size = .{ .x = width, .y = 30 },
                        .renderMode = .NoControl,
                        .color = Color.Yellow,
                        .textSize = defaultHeight,
                        .rendererHash = fontHash,
                    },
                },
            });
            yOffset += offsetPerLine + (offsetPerLine / 4);
        }
    }

    pub fn printTree(self: @This(), root: NodeHandle) void {
        std.debug.print("\n ==== tree ==== \n", .{});
        self.printTreeInner(root, 0);
        std.debug.print(" ==== /tree ====   \n\n", .{});
    }

    fn printTreeInner(self: @This(), root: NodeHandle, indentLevel: u32) void {
        var i: u32 = 0;
        while (i < indentLevel) : (i += 1) {
            std.debug.print(" ", .{});
        }

        const node = self.getRead(root);
        std.debug.print("> {d}: {s}\n", .{ root.index, node.text.getRead() });

        var next = node.child;
        while (next.index != 0) {
            self.printTreeInner(next, indentLevel + 1);
            next = self.getRead(next).*.next;
        }
    }

    pub fn writeTree(self: @This(), root: NodeHandle, outFile: []const u8) !void {
        var log = try FileLog.init(self.allocator, outFile);
        defer log.deinit();

        try log.write("digraph G {{\n", .{});
        try self.writeTreeInner(root, &log);
        try log.write("}}\n", .{});

        try log.writeOut();
    }

    fn writeTreeInner(self: @This(), root: NodeHandle, log: *FileLog) !void {
        var node = self.getRead(root);
        try log.write("  {s}->{s}", .{ self.getRead(node.parent).text.getRead(), node.text.getRead() });

        var next = node.child;
        while (next.index != 0) {
            try self.writeTreeInner(next, log);
            next = self.getRead(next).*.next;
        }
    }

    // Sets the current cursor location
    pub fn setCursorLocation(self: *@This(), position: Vector2f) void {
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
