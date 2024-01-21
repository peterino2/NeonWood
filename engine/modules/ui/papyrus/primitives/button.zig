textSize: f32 = 16,
font: papyrus.PapyrusFont,
style: ButtonStyle = .{},
disabled: bool = false,
buttonState: ButtonState = .Normal,

const std = @import("std");
const papyrus = @import("../papyrus.zig");
const LocText = papyrus.LocText;
const MakeText = papyrus.MakeText;

const PapyrusNode = papyrus.PapyrusNode;
const DrawListBuilder = @import("../DrawListBuilder.zig");
const core = @import("root").neonwood.core;
const Vector2f = core.Vector2f;
const colors = @import("../colors.zig");
const BurnStyle = colors.BurnStyle;

pub const ButtonStyle = struct {
    normal: papyrus.PapyrusNodeStyle = .{
        .borderColor = BurnStyle.Diminished,
    },
    pressed: papyrus.PapyrusNodeStyle = .{
        .backgroundColor = BurnStyle.DarkSlateGrey,
    },
    hovered: papyrus.PapyrusNodeStyle = .{
        .backgroundColor = BurnStyle.SlateGrey,
    },
    disabled: papyrus.PapyrusNodeStyle = .{
        .foregroundColor = BurnStyle.DarkSlateGrey,
    },
};

pub const ButtonState = enum {
    Normal,
    Hovered,
    Pressed,
};

// add button
pub fn addToDrawList(dlb: DrawListBuilder) !void {
    var drawlist = dlb.drawList;

    const button = dlb.n.nodeType.Button;

    var borderColor = button.style.normal.borderColor;
    var backgroundColor = button.style.normal.backgroundColor;
    var foregroundColor = button.style.normal.foregroundColor;

    if (button.buttonState == .Hovered) {
        borderColor = button.style.hovered.borderColor;
        backgroundColor = button.style.hovered.backgroundColor;
        foregroundColor = button.style.hovered.foregroundColor;
    }

    if (button.buttonState == .Pressed) {
        borderColor = button.style.pressed.borderColor;
        backgroundColor = button.style.pressed.backgroundColor;
        foregroundColor = button.style.pressed.foregroundColor;
    }

    if (button.disabled) {
        borderColor = button.style.disabled.borderColor;
        backgroundColor = button.style.disabled.backgroundColor;
        foregroundColor = button.style.disabled.foregroundColor;
    }

    try drawlist.append(
        .{ .node = dlb.node, .primitive = .{ .Rect = .{
            .tl = dlb.resolvedPos,
            .size = dlb.resolvedSize,
            .borderColor = borderColor,
            .backgroundColor = backgroundColor,
        } } },
    );

    try drawlist.append(.{
        .node = dlb.node,
        .primitive = .{
            .Text = .{
                .color = foregroundColor,
                .tl = dlb.resolvedPos.add(.{ .x = 5, .y = 2 }),
                .size = dlb.resolvedSize,
                .text = dlb.n.text,
                .renderMode = dlb.n.textMode,
                .textSize = button.textSize,
                .rendererHash = button.font.atlas.rendererHash,
                // TODO: figure out centering.
            },
        },
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
        .size = dlb.resolvedSize.sub(Vector2f.Ones.fmul(2)),
        .childLayoutOffsets = .{},
    };
}

pub fn buttonMouseOverListener(node: papyrus.NodeHandle, _: ?*anyopaque) papyrus.EventHandlerError!void {
    var ctx = papyrus.getContext();
    var btn = ctx.getButton(node);
    if (btn.disabled == false) {
        btn.buttonState = .Hovered;
    }
}

pub fn buttonMouseOffListener(node: papyrus.NodeHandle, _: ?*anyopaque) papyrus.EventHandlerError!void {
    var ctx = papyrus.getContext();
    var btn = ctx.getButton(node);
    if (btn.disabled == false) {
        btn.buttonState = .Normal;
    }
}

pub fn buttonOnPressedEvent(node: papyrus.NodeHandle, eventType: papyrus.PressedEventType, _: ?*anyopaque) papyrus.EventHandlerError!void {
    var ctx = papyrus.getContext();
    var btn = ctx.getButton(node);

    if (eventType == .onPressed) {
        btn.buttonState = .Pressed;
    } else if (eventType == .onReleased) {
        btn.buttonState = .Hovered;
    }
}
