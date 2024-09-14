const std = @import("std");
const c = @cImport({
    @cInclude("stb_ttf.h");
});

pub const Layout = @import("MousePick.zig");
pub const Event = @import("Event.zig");

pub const Font = @import("Font.zig");
pub const FontAtlas = Font.FontAtlas;
pub const BmpRenderer = @import("BmpRenderer.zig");
pub const BmpWriter = BmpRenderer.BmpWriter;

pub const style = @import("style.zig");
pub const ModernStyle = style.ModernStyle;
pub const BurnStyle = style.BurnStyle;

pub const utils = @import("utils.zig");
pub const FileLog = utils.FileLog;
pub const grapvizDotToPng = utils.grapvizDotToPng;
pub const loadFileAlloc = utils.loadFileAlloc;
pub const assertf = utils.assertf;

pub const localization = @import("localization.zig");
pub const LocText = localization.LocText;
pub const MakeText = localization.MakeText;
pub const HandlerError = Event.HandlerError;
pub const PressedType = Event.PressedType;

pub const TextRenderGeometry = @import("textRender/textRenderGeometry.zig");

pub const DrawListBuilder = @import("DrawListBuilder.zig");

pub const NodeProperty_Button = @import("primitives/button.zig");
pub const NodeProperty_TextEntry = @import("primitives/textEntry.zig");

pub const TextEntrySystem = @import("TextEntrySystem.zig");

pub const DrawCommand = @import("DrawCommand.zig");
pub const DrawList = std.ArrayList(DrawCommand);

const core = @import("core");
const colors = core.colors;
pub const Color = colors.Color;
pub const ColorRGBA8 = colors.RGBA8;

const MemoryTracker = core.MemoryTracker;
const Vector2i = core.Vector2i;
const Vector2f = core.Vector2f;
const IndexPool = core.IndexPool;
const Name = core.Name;
const asserts = core.asserts;

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

pub var gContext: *Context = undefined;
pub var gIsInitialized: bool = false;

pub const AnchorNode = enum {
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

pub const FillMode = enum {
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
pub const NodeJustify = enum {
    // zig fmt: off
    Left,
    Center,
    Right,
    // zig fmt: on
};

pub const HitTestability = enum {
    Testable,
    NotTestable,
};

pub const State = enum {
    Visible,
    Collapsed,
    Hidden,
};

pub const ChildLayout = enum { Free, Vertical, Horizontal };

pub const NodeProperty_Slot = struct {
    layoutMode: ChildLayout = .Free,
};

pub const NodeProperty_Text = struct {
    textSize: f32,
    color: Color,
    font: Font,
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
    TextEntry: NodeProperty_TextEntry,
};

pub const NodePadding = union(enum(u8)) {
    topLeft: Vector2f,
    botLeft: Vector2f,
    all: f32,
    allSides: [2]Vector2f,
};

pub const NodeStyle = struct {
    foregroundColor: Color = BurnStyle.Normal,
    backgroundColor: Color = BurnStyle.SlateGrey,
    borderColor: Color = BurnStyle.Bright2,
    borderWidth: f32 = 1.1,
};

pub const TextRenderMode = enum {
    Simple,
    NoControl,
    Rich,
};

// this is going to follow a pretty object-oriented-like user facing api
pub const Node = struct {
    text: LocText = MakeText("hello world"),
    textMode: TextRenderMode = .Simple,
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

    justify: NodeJustify = .Center,

    pos: Vector2f = .{ .x = 0, .y = 0 },
    anchor: AnchorNode = .TopLeft,
    originAnchor: AnchorNode = .TopLeft, // This specifies where within this node is used for an anchor.
    originOffset: Vector2f = .{}, // this specifies an offset from the chosen origin position
    fill: FillMode = .None,
    layoutPadding: f32 = 5.0,

    // padding is the external padding factor
    padding: NodePadding = .{ .all = 0 },

    state: State = .Visible,
    hittest: HitTestability = .Testable,
    dockingPolicy: enum { Dockable, NotDockable } = .Dockable,

    // standard styling options that all nodes have
    style: NodeStyle = .{},

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
pub const LayoutInfo = struct {
    baseSize: Vector2f,
    pos: Vector2f,
    size: Vector2f,
    childLayoutOffsets: Vector2f,
};

pub const Context = struct {
    backingAllocator: std.mem.Allocator,
    allocator: std.mem.Allocator,
    nodes: IndexPool(Node),
    fonts: std.AutoHashMap(u32, Font),
    defaultFont: Font,
    defaultMonoFont: Font,
    defaultBitmapFont: Font,
    extent: Vector2i = .{ .x = 1920, .y = 1080 },
    currentCursorPosition: Vector2f = .{},

    styleStack: std.ArrayListUnmanaged(NodeStyle) = .{},
    resolvedStyle: NodeStyle = .{},

    mousePick: Layout,

    events: Event,

    textEntry: *TextEntrySystem,

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
        self.clearDebugText();

        try self.mousePick.tick(self, deltaTime);
        try self.textEntry.tick(deltaTime);

        try self.tickDebug(deltaTime);
    }

    pub fn tickDebug(self: *@This(), deltaTime: f64) !void {
        _ = deltaTime;
        try self.pushDebugText("mouse Position: {d}, {d}", .{ self.currentCursorPosition.x, self.currentCursorPosition.y });
        if (self.mousePick.selected_node) |node| {
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
        const defaultFontName: []const u8 = "default";
        const defaultMonoName: []const u8 = "monospace";
        const defaultBitmapFontName: []const u8 = "bitmap";

        var self = try backingAllocator.create(@This());
        var allocator = backingAllocator;

        self.* = .{
            .allocator = allocator,
            .backingAllocator = allocator,
            .nodes = IndexPool(Node).init(allocator),
            .fonts = std.AutoHashMap(u32, Font).init(allocator),
            .events = Event.init(allocator),
            .defaultFont = Font{
                .name = Name.fromUtf8(defaultFontName),
                .atlas = try allocator.create(FontAtlas),
            },
            .defaultMonoFont = Font{
                .name = Name.fromUtf8(defaultMonoName),
                .atlas = try allocator.create(FontAtlas),
            },
            .defaultBitmapFont = Font{
                .name = Name.fromUtf8(defaultBitmapFontName),
                .atlas = try allocator.create(FontAtlas),
            },
            .textEntry = try TextEntrySystem.create(self, allocator),
            ._drawOrder = DrawOrderList.init(allocator),
            ._layout = .{},
            ._layoutNodes = .{},
            ._layoutPositions = .{},
            .debugText = std.ArrayList([]u8).init(allocator),
            .mousePick = Layout.init(allocator),
        };

        for (0..debugTextMax) |_| {
            const textBuffer = try allocator.alloc(u8, 512);
            try self.debugText.append(textBuffer);
        }

        self.defaultFont.atlas.* = try FontAtlas.initDefaultFont(allocator, 64);
        try self.installFontAtlas(self.defaultFont.name.utf8(), self.defaultFont.atlas);

        self.defaultMonoFont.atlas.* = try FontAtlas.initMonoFont(allocator, 64);
        try self.installFontAtlas(self.defaultMonoFont.name.utf8(), self.defaultMonoFont.atlas);

        // this is a 16 px sized default font
        self.defaultBitmapFont.atlas.* = try FontAtlas.initDefaultBitmapFont(allocator, 16);
        try self.installFontAtlas(self.defaultBitmapFont.name.utf8(), self.defaultBitmapFont.atlas);

        // difference between asserts and assertf is asserts is not recoverable,
        // instantly crashes.
        asserts(
            self.defaultBitmapFont.atlas.atlasBuffer != null,
            "expected atlas buffer to be valid {any}",
            .{self.defaultBitmapFont.atlas.atlasBuffer},
            @src().fn_name,
        );

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
        for (0..self.nodes.count()) |i| {
            const maybeNode = self.nodes.indexToHandle(i);
            if (maybeNode) |node| {
                const n = self.nodes.active.items[i];
                if (n.?.nodeType == .TextEntry) {
                    NodeProperty_TextEntry.tearDown(self, node);
                }
            }
        }

        self.mousePick.deinit();

        self.textEntry.destroy();

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
        self._displayLayout.deinit(self.allocator);

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

    pub fn getButton(self: *@This(), handle: NodeHandle) *NodeProperty_Button {
        return &(self.nodes.get(handle).?.nodeType.Button);
    }

    pub fn getText(self: *@This(), handle: NodeHandle) *NodeProperty_Text {
        return &(self.nodes.get(handle).?.nodeType.DisplayText);
    }

    pub fn getTextEntry(self: *@This(), node: NodeHandle) *NodeProperty_TextEntry {
        return &(self.nodes.get(node).?.nodeType.TextEntry);
    }

    pub fn setFont(self: *@This(), handle: NodeHandle, font: []const u8) void {
        const name = Name.fromUtf8(font);

        switch (self.nodes.get(handle).?.nodeType) {
            .DisplayText => {
                var text = &(self.nodes.get(handle).?.nodeType.DisplayText);
                text.font = .{
                    .name = name,
                    .atlas = (self.fonts.get(name.handle())).?.atlas,
                };
            },
            .Panel => {
                var panel = &(self.nodes.get(handle).?.nodeType.Panel);
                panel.font = self.fonts.get(name.handle()).?.atlas;
            },
            .TextEntry => {
                self.getTextEntry(handle).font = self.fonts.get(name.handle()) orelse self.defaultFont;
            },
            else => {},
        }
    }

    // converts a handle to a node pointer
    // invalid after AddNode
    pub fn get(self: *@This(), handle: NodeHandle) *Node {
        return self.nodes.get(handle).?;
    }

    // gets a node as read only
    pub fn getRead(self: @This(), handle: NodeHandle) *const Node {
        if (!self.isValid(handle))
            @panic("handle is invalid");

        return self.nodes.getRead(handle).?;
    }

    fn newNode(self: *@This(), node: Node) !NodeHandle {
        return try self.nodes.new(node);
    }

    pub fn addSlot(self: *@This(), parent: NodeHandle) !NodeHandle {
        const slotNode = Node{ .nodeType = .{ .Slot = .{} } };
        const slot = try self.newNode(slotNode);

        try self.setParent(slot, parent);

        return slot;
    }

    pub fn addText(self: *@This(), parent: NodeHandle, text: []const u8) !NodeHandle {
        const slotNode = Node{
            .text = LocText.fromUtf8(text),
            .nodeType = .{ .DisplayText = .{
                .textSize = 24,
                .color = Color.White,
                .font = self.defaultFont,
            } },
        };
        const slot = try self.newNode(slotNode);

        try self.setParent(slot, parent);

        return slot;
    }

    pub fn addPanel(self: *@This(), parent: NodeHandle) !NodeHandle {
        var slotNode = Node{ .nodeType = .{ .Panel = .{
            .font = self.defaultFont.atlas,
            .imageReference = core.NameInvalid,
        } } };

        if (parent.index == 0) {
            slotNode.anchor = .Free;
        }
        const slot = try self.nodes.new(slotNode);

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

        const parentNode = self.nodes.get(parent).?;
        const thisNode = self.nodes.get(node).?;

        // if we have a previous parent, remove ourselves
        if (thisNode.*.parent.index != 0) {
            // remove myself from that parent.
            const oldParentNode = self.nodes.get(thisNode.*.parent).?;

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

    pub fn addTextEntry_experimental(self: *@This(), parent: NodeHandle, text: ?[]const u8) !NodeHandle {
        var textProperty = NodeProperty_TextEntry{
            .editText = std.ArrayList(u8).init(self.allocator),
            .font = self.defaultFont,
        };

        if (text) |t| {
            try textProperty.editText.appendSlice(t);
        } else {
            try textProperty.editText.appendSlice("click to edit...");
        }

        const n = try self.nodes.new(.{ .nodeType = .{ .TextEntry = textProperty } });
        try self.setParent(n, parent);
        self.get(n).size = .{ .x = 350, .y = 30 };

        try self.events.installOnPressedEventAdvanced(n, .onPressed, .Mouse1, null, NodeProperty_TextEntry.onPressedEvent, true);

        return n;
    }

    // helper functions for a whole bunch of shit
    pub fn addButton(self: *@This(), parent: NodeHandle, text: ?[]const u8) !NodeHandle {
        const buttonProperty = NodeProperty_Button{
            .font = self.defaultFont,
        };

        const button = try self.nodes.new(.{ .nodeType = .{ .Button = buttonProperty } });
        try self.setParent(button, parent);
        self.get(button).size = .{ .x = 100, .y = 50 };

        if (text) |t| {
            self.get(button).text = LocText.fromUtf8(t);
        }

        try self.events.installMouseOverEventAdvanced(button, .mouseOver, null, NodeProperty_Button.buttonMouseOverListener, true);
        try self.events.installMouseOverEventAdvanced(button, .mouseOff, null, NodeProperty_Button.buttonMouseOffListener, true);

        try self.events.installOnPressedEventAdvanced(button, .onPressed, .Mouse1, null, NodeProperty_Button.buttonOnPressedEvent, true);
        try self.events.installOnPressedEventAdvanced(button, .onReleased, .Mouse1, null, NodeProperty_Button.buttonOnPressedEvent, true);

        return button;
    }

    pub fn pushStyle(self: *@This(), node: NodeStyle) void {
        _ = node;
        _ = self;
    }

    // removes this node from its' parent as well as purges all subnodes.
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

        const thisNode = self.getRead(node);
        self.get(thisNode.next).prev = thisNode.prev;
        self.get(thisNode.prev).next = thisNode.next;

        {
            var parent = self.get(thisNode.parent);

            if (thisNode.nodeType == .TextEntry) {
                NodeProperty_TextEntry.tearDown(self, node);
            }

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

        // Uninstall handlers from the events system
        self.events.uninstallAllEvents_OnDestroy(node);
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
            pub fn lessThan(ctx: Context, lhs: NodeHandle, rhs: NodeHandle) bool {
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

    fn resolveAnchoredPosition(parent: LayoutInfo, node: *const Node) Vector2f {
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

    pub fn onKey(self: *@This(), keycode: Event.Key, eventType: Event.PressedType) !void {
        if (self.mousePick.selected_node) |node|
            try self.events.pushPressedEvent(node, eventType, keycode);
    }

    fn resolveAnchoredSize(parent: LayoutInfo, node: *const Node) Vector2f {
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
        n: *const Node,
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

                const rv = ChildLayoutRulesStruct{
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

    pub fn makeDrawList(self: *@This(), drawList: *DrawList, stringArena: *std.heap.ArenaAllocator) !void {
        _ = stringArena.reset(.retain_capacity);

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
            const n = self.getRead(node);

            if (n.state == .Hidden) {
                continue;
            }

            const parentInfo = self._displayLayout.items[n.parent.index];

            var dlb = DrawListBuilder{
                .ctx = self,
                .node = node,
                .drawList = drawList,
                .n = n,
                .parentInfo = self._displayLayout.items[n.parent.index],
                .resolvedSize = resolveAnchoredSize(parentInfo, n),
                .resolvedPos = resolveAnchoredPosition(parentInfo, n),
            };

            // if our parent is a panel then apply layout rules to it.
            if (self.fetchPanel(n.parent)) |parentAsPanel| {
                const results = self.applyLayoutRulesAsChild(parentAsPanel, n, dlb.resolvedSize, dlb.resolvedPos);
                dlb.resolvedPos = results.position;
                dlb.resolvedSize = results.size;
            }

            switch (n.nodeType) {
                .Panel => |panel| {
                    try self._layout.append(self.allocator, .{
                        .baseSize = n.baseSize,
                        .pos = dlb.resolvedPos,
                        .size = dlb.resolvedSize,
                        .childLayoutOffsets = .{},
                    });
                    try self._layoutNodes.append(self.allocator, node);
                    try self._layoutPositions.put(
                        self.allocator,
                        node,
                        .{
                            .pos = dlb.resolvedPos,
                            .size = dlb.resolvedSize,
                            .baseSize = n.baseSize,
                            .childLayoutOffsets = .{},
                        },
                    );

                    if (panel.hasTitle) {

                        // draw the main image.
                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = dlb.resolvedPos.add(.{ .y = panel.titleSize }),
                                .size = dlb.resolvedSize.sub(.{ .y = panel.titleSize }),
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
                                .tl = dlb.resolvedPos,
                                .size = .{ .x = dlb.resolvedSize.x, .y = panel.titleSize },
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
                                .tl = dlb.resolvedPos.add(.{ .x = 3 + 5, .y = 3 }),
                                .size = .{ .x = dlb.resolvedSize.x, .y = panel.titleSize },
                                .text = n.text,
                                .renderMode = n.textMode,
                                .color = panel.titleColor,
                                .textSize = panel.titleSize - 4,
                                .rendererHash = panel.font.rendererHash,
                                .flags = .{
                                    .setSourceGeometry = false,
                                },
                            },
                        } });

                        self._displayLayout.items[node.index] = .{
                            .baseSize = n.baseSize,
                            .pos = dlb.resolvedPos.add(.{ .y = panel.titleSize }).add(Vector2f.Ones),
                            .size = dlb.resolvedSize.sub(.{ .y = -panel.titleSize }).sub(Vector2f.Ones).sub(.{ .x = 0, .y = 30 }),
                            .childLayoutOffsets = .{},
                        };
                    } else {

                        // draw the main image
                        try drawList.append(.{ .node = node, .primitive = .{
                            .Rect = .{
                                .tl = dlb.resolvedPos,
                                .size = dlb.resolvedSize,
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
                            .pos = dlb.resolvedPos.add(Vector2f.Ones),
                            .size = dlb.resolvedSize.sub(Vector2f.Ones.fmul(2)),
                            .childLayoutOffsets = .{},
                        };
                    }
                },
                .DisplayText => |txt| {
                    try drawList.append(.{ .node = node, .primitive = .{
                        .Text = .{
                            .tl = dlb.resolvedPos,
                            .size = n.size,
                            .text = n.text,
                            .renderMode = n.textMode,
                            .color = n.style.foregroundColor,
                            .textSize = txt.textSize,
                            .rendererHash = txt.font.atlas.rendererHash,
                            .flags = .{
                                .setSourceGeometry = false,
                            },
                        },
                    } });

                    self._displayLayout.items[node.index] = .{
                        .baseSize = n.baseSize,
                        .pos = dlb.resolvedPos.add(Vector2f.Ones),
                        .size = dlb.resolvedSize.add(Vector2f.Ones),
                        .childLayoutOffsets = .{},
                    };
                },
                .Button => {
                    try NodeProperty_Button.addToDrawList(dlb);
                },
                .TextEntry => {
                    try NodeProperty_TextEntry.addToDrawList(dlb);
                },
                .Slot => {},
            }
        }

        if (self.drawDebug) {
            try self.addDebugInfo(drawList);
        }

        for (0..drawList.items.len) |i| {
            switch (drawList.items[i].primitive) {
                .Text => |*text| {
                    text.text.utf8 = try core.dupeString(stringArena.allocator(), text.text.utf8);
                },
                .Rect => {},
            }
        }
    }

    fn addDebugInfo(self: @This(), drawList: *DrawList) !void {
        const defaultHeight = 16;
        const sizePerLine: f32 = defaultHeight + 2;
        const yOffsetPerLine: f32 = defaultHeight + 1;
        var yOffset: f32 = sizePerLine;
        const width = defaultHeight / 2 * 120;

        const fontHash = self.defaultMonoFont.atlas.rendererHash;

        try self.mousePick.addMousePickInfo(&self, drawList);

        try drawList.append(.{
            .node = .{},
            .primitive = .{
                .Rect = .{
                    .tl = .{ .x = 30 - 5, .y = yOffset - 5 },
                    .size = .{ .x = width + 5, .y = sizePerLine * @as(f32, @floatFromInt(self.debugTextCount + 2)) },
                    .borderColor = Color.fromRGBA(0x444444ee),
                    .backgroundColor = Color.fromRGBA2(0.0, 0.0, 0.0, 0.94),
                },
            },
        });

        // try drawList.append(.{
        //     .node = .{},
        //     .primitive = .{
        //         .Text = .{
        //             .text = LocText.fromUtf8("Papyrus Debug:"),
        //             .tl = .{ .x = 30, .y = yOffset },
        //             .size = .{ .x = width, .y = 30 },
        //             .renderMode = .NoControl,
        //             //.color = BurnStyle.Highlight3,
        //             .color = Color.Yellow,
        //             .textSize = defaultHeight,
        //             .rendererHash = fontHash,
        //             .flags = .{
        //                 .setSourceGeometry = false,
        //             },
        //         },
        //     },
        // });
        // yOffset += yOffsetPerLine;

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
                        .flags = .{
                            .setSourceGeometry = false,
                        },
                    },
                },
            });
            yOffset += yOffsetPerLine + (yOffsetPerLine / 4);
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
        const text = node.text.getRead();
        if (text.len > 256) {
            std.debug.print("> {d}: {s}...\n", .{ root.index, text[0..128] });
        } else {
            std.debug.print("> {d}: {s}\n", .{ root.index, text });
        }

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

pub fn getContext() *Context {
    return gContext;
}

pub fn initialize(allocator: std.mem.Allocator) !*Context {
    try assertf(gIsInitialized == false, "Unable to initialize Papyrus, already initialized", .{});
    core.ui_log("Papyrus initialized here's some stats:", .{});
    core.ui_log("  - DrawListCommand size: {d}", .{@sizeOf(DrawList)});
    core.ui_log("  - Node size: {d}", .{@sizeOf(Node)});
    gIsInitialized = true;
    gContext = try Context.create(allocator);
    return gContext;
}

pub fn deinitialize() void {
    gContext.deinit();
}

pub const Module = core.ModuleDescription{
    .name = "papyrus",
    .enabledByDefault = true,
};
