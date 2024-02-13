textSize: f32 = 24,
font: papyrus.Font,
disabled: bool = false,
entryState: TextEntryState = .Normal,
entryStubPosition: u32 = 0,
textEntryStyle: TextEntryStyle = .{},
editText: std.ArrayList(u8),
enterSendsNewline: bool = true,

pub const TextEntryStyle = struct {
    normal: papyrus.NodeStyle = .{
        .borderColor = BurnStyle.Diminished,
    },
    typing: papyrus.NodeStyle = .{
        .borderColor = BurnStyle.LightGrey,
    },
};

const std = @import("std");
const papyrus = @import("../../papyrus.zig");
const LocText = papyrus.LocText;
const MakeText = papyrus.MakeText;

const Node = papyrus.Node;
const DrawListBuilder = @import("../DrawListBuilder.zig");
const core = @import("root").neonwood.core;
const Vector2f = core.Vector2f;
const colors = @import("../colors.zig");
const BurnStyle = colors.BurnStyle;

pub const TextEntryState = enum {
    Normal,
    Entering,
    Pressed,
};

pub const TextEntrySystem = struct {
    node: papyrus.NodeHandle,
};

pub fn addToDrawList(dlb: DrawListBuilder) !void {
    var drawlist = dlb.drawList;
    const te = dlb.n.nodeType.TextEntry;

    var backgroundColor = te.textEntryStyle.normal.backgroundColor;
    var foregroundColor = te.textEntryStyle.normal.foregroundColor;
    var borderColor = te.textEntryStyle.normal.borderColor;
    var borderWidth = te.textEntryStyle.normal.borderWidth;

    // 0. select colors
    if (te.entryState == .Pressed) {
        backgroundColor = te.textEntryStyle.typing.backgroundColor;
        foregroundColor = te.textEntryStyle.typing.foregroundColor;
        borderColor = te.textEntryStyle.typing.borderColor;
        borderWidth = te.textEntryStyle.typing.borderWidth;
    }

    // 1. draw the main rect for Text.
    try drawlist.append(.{
        .node = dlb.node,
        .primitive = .{ .Rect = .{
            .tl = dlb.resolvedPos,
            .size = dlb.resolvedSize,
            .backgroundColor = backgroundColor,
            .borderColor = borderColor,
            .borderWidth = borderWidth,
        } },
    });

    try drawlist.append(.{
        .node = dlb.node,
        .primitive = .{ .Text = .{
            .color = foregroundColor,
            .tl = dlb.resolvedPos.add(.{ .x = 5, .y = 2 }),
            .size = dlb.resolvedSize,
            .renderMode = dlb.n.textMode,
            .textSize = te.textSize,
            .text = LocText.fromUtf8(te.editText.items),
            .rendererHash = te.font.atlas.rendererHash,
            .flags = .{
                .setSourceGeometry = (te.entryState == .Pressed),
            },
        } },
    });

    try dlb.ctx._layout.append(dlb.ctx.allocator, .{
        .baseSize = dlb.n.baseSize,
        .pos = dlb.resolvedPos,
        .size = dlb.resolvedSize,
        .childLayoutOffsets = .{},
    });

    try dlb.ctx._layoutNodes.append(dlb.ctx.allocator, dlb.node);

    dlb.ctx._displayLayout.items[dlb.node.index] = .{
        .baseSize = dlb.n.baseSize,
        .pos = dlb.resolvedPos.add(Vector2f.Ones),
        .size = dlb.resolvedSize.add(Vector2f.Ones.fmul(2)),
        .childLayoutOffsets = .{},
    };

    // if we are the currently selected one, then draw a rect representing our
    // textentry cursor
    if (te.entryState == .Pressed and dlb.ctx.textEntry.cursorBlink) {
        if (dlb.ctx.textEntry.cursorResults) |hr| {
            const geo = hr.characterGeo;
            const width: f32 = 2.0;

            try drawlist.append(.{
                .node = dlb.node,
                .primitive = .{
                    .Rect = .{
                        .tl = geo.pos,
                        .size = .{ .x = width, .y = geo.size.y },
                        .backgroundColor = foregroundColor,
                        .borderColor = foregroundColor,
                        .borderWidth = 0.0,
                    },
                },
            });
        }
    }
}

pub fn tearDown(ctx: *papyrus.Context, node: papyrus.NodeHandle) void {
    var textEntry = ctx.getTextEntry(node);
    textEntry.editText.deinit();
}

// ======
pub fn onPressedEvent(
    node: papyrus.NodeHandle,
    eventType: papyrus.PressedType,
    _: ?*anyopaque,
) papyrus.HandlerError!void {
    if (eventType == .onPressed) {
        var ctx = papyrus.getContext();
        var te = ctx.getTextEntry(node);

        if (te.entryState == .Normal) {
            ctx.textEntry.selectTextForEdit(node);
        } else if (te.entryState == .Pressed) {
            ctx.textEntry.testHits() catch return papyrus.HandlerError.EventPanic;
        }
    }
}
