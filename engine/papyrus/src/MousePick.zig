const std = @import("std");
const papyrus = @import("papyrus.zig");

const Context = papyrus.Context;
const EventType = Context.EventType;

const core = @import("core");
const Vector2i = core.Vector2i;
const Vector2f = core.Vector2f;

const colors = core.colors;
const Color = colors.Color;

allocator: std.mem.Allocator,
selected_node: ?papyrus.NodeHandle = null,

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

pub fn tick(self: *@This(), papyrusCtx: *Context, _: f64) !void {
    const layout = papyrusCtx._layout.items;

    const last_selected = self.selected_node;
    self.selected_node = null;

    var i: usize = layout.len;
    self.selected_node = while (i > 0) {
        i -= 1;
        if (intersect(papyrusCtx.currentCursorPosition, layout[i].pos, layout[i].size)) {
            const node = papyrusCtx._layoutNodes.items[i];
            if (!papyrusCtx.isValid(node))
                break null;

            break node;
        }
    } else null;

    if (last_selected != null and self.selected_node == null) {
        // falling edge
        if (papyrusCtx.isValid(last_selected.?))
            try papyrusCtx.events.pushMouseOverEvent(last_selected.?, .mouseOff);
    } else if (last_selected == null and self.selected_node != null) {
        // rising edge
        try papyrusCtx.events.pushMouseOverEvent(self.selected_node.?, .mouseOver);
    } else if (self.selected_node != null and !self.selected_node.?.eql(last_selected.?)) {
        try papyrusCtx.events.pushMouseOverEvent(self.selected_node.?, .mouseOver);
        if (papyrusCtx.isValid(last_selected.?))
            try papyrusCtx.events.pushMouseOverEvent(last_selected.?, .mouseOff);
    }
}

pub fn deinit(self: *@This()) void {
    _ = self;
}

pub fn addMousePickInfo(
    self: @This(),
    papyrusCtx: *const Context,
    drawList: *papyrus.DrawList,
) !void {
    const selected_node = self.selected_node orelse return;
    const layoutInfo = papyrusCtx._displayLayout.items[selected_node.index];

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
