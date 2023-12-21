const std = @import("std");
const papyrus = @import("papyrus.zig");

const PapyrusContext = papyrus.PapyrusContext;
const EventType = PapyrusContext.EventType;

const core = @import("root").neonwood.core;
const Vector2i = core.Vector2i;
const Vector2f = core.Vector2f;

const colors = @import("colors.zig");
const Color = colors.Color;

allocator: std.mem.Allocator,
selectedNode: papyrus.NodeHandle = .{},
found: bool = false,

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{
        .allocator = allocator,
    };
}

fn intersect(position: Vector2f, topLeft: Vector2f, size: Vector2f) bool {
    if (position.x > topLeft.x and position.x < topLeft.x + size.x and position.y > topLeft.y and position.y < topLeft.y + size.y) {
        return true;
    }

    return false;
}

pub fn tick(self: *@This(), papyrusCtx: *PapyrusContext, _: f64) !void {
    var layout = papyrusCtx._layout.items;

    var lastFound = self.found;
    var lastSelected = self.selectedNode;

    self.found = false;

    var i: usize = layout.len;

    while (i > 0) {
        i -= 1;

        if (intersect(papyrusCtx.currentCursorPosition, layout[i].pos, layout[i].size)) {
            self.selectedNode = papyrusCtx._layoutNodes.items[i];
            self.found = true;
            break;
        }
    }

    if (lastFound and !self.found) {
        // falling edge
        try papyrusCtx.events.pushMouseOverEvent(lastSelected, .mouseOff);
    } else if (!lastFound and self.found) {
        // rising edge
        try papyrusCtx.events.pushMouseOverEvent(self.selectedNode, .mouseOver);
    } else if (!self.selectedNode.eql(lastSelected)) {
        try papyrusCtx.events.pushMouseOverEvent(self.selectedNode, .mouseOver);
        try papyrusCtx.events.pushMouseOverEvent(lastSelected, .mouseOff);
    }
}

pub fn deinit(self: *@This()) void {
    _ = self;
}

pub fn addMousePickInfo(
    self: @This(),
    papyrusCtx: *const PapyrusContext,
    drawList: *PapyrusContext.DrawList,
) !void {
    if (!self.found)
        return;

    var layoutInfo = papyrusCtx._displayLayout.items[self.selectedNode.index];

    try drawList.append(.{
        .node = .{},
        .primitive = .{
            .Rect = .{
                .tl = layoutInfo.pos,
                .size = layoutInfo.size,
                .borderColor = Color.fromRGBA2(1.0, 0.0, 0.0, 1.0),
                .backgroundColor = Color.fromRGBA2(0.0, 0.0, 0.0, 0.0),
            },
        },
    });
}
