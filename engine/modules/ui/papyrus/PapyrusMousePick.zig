const std = @import("std");
const papyrus = @import("papyrus.zig");

const PapyrusContext = papyrus.PapyrusContext;
const vectors = @import("vectors.zig");

const Vector2i = vectors.Vector2i;
const Vector2 = vectors.Vector2;
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

fn intersect(position: Vector2, topLeft: Vector2, size: Vector2) bool {
    if (position.x > topLeft.x and position.x < topLeft.x + size.x and position.y > topLeft.y and position.y < topLeft.y + size.y) {
        return true;
    }

    return false;
}

pub fn tick(self: *@This(), papyrusCtx: *PapyrusContext, _: f64) !void {
    var layout = papyrusCtx._layout.items;

    self.found = false;

    var x: isize = @as(isize, @intCast(layout.len)) - 1;
    while (x >= 0) : (x -= 1) {
        var i = @as(usize, @intCast(x));
        if (intersect(papyrusCtx.currentCursorPosition, layout[i].pos, layout[i].size)) {
            self.selectedNode = papyrusCtx._layoutNodes.items[i];
            self.found = true;
            break;
        }
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

    var posSize = papyrusCtx._layoutPositions.get(self.selectedNode).?;

    try drawList.append(.{
        .node = .{},
        .primitive = .{
            .Rect = .{
                .tl = posSize.pos,
                .size = posSize.size,
                .borderColor = Color.fromRGBA2(1.0, 0.0, 0.0, 1.0),
                .backgroundColor = Color.fromRGBA2(0.0, 0.0, 0.0, 0.0),
            },
        },
    });
}
