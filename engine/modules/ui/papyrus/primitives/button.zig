textSize: f32 = 16,
font: papyrus.Font,
style: ButtonStyle = .{},
disabled: bool = false,
buttonState: ButtonState = .Normal,

// documentation:
// Each PapyrusNode has a common set of fields, these are defined in PapyrusNode
//

const std = @import("std");
const papyrus = @import("../../papyrus.zig");
const LocText = papyrus.LocText;
const MakeText = papyrus.MakeText;

const DrawListBuilder = @import("../DrawListBuilder.zig");
const core = @import("root").neonwood.core;
const Vector2f = core.Vector2f;
const colors = @import("../colors.zig");
const BurnStyle = colors.BurnStyle;

pub const ButtonStyle = struct {
    normal: papyrus.NodeStyle = .{
        .borderColor = BurnStyle.Diminished,
    },
    pressed: papyrus.NodeStyle = .{
        .backgroundColor = BurnStyle.BrightGrey,
    },
    hovered: papyrus.NodeStyle = .{
        .backgroundColor = BurnStyle.LightGrey,
    },
    disabled: papyrus.NodeStyle = .{
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
    var borderWidth = button.style.normal.borderWidth;

    if (button.buttonState == .Hovered) {
        borderColor = button.style.hovered.borderColor;
        backgroundColor = button.style.hovered.backgroundColor;
        foregroundColor = button.style.hovered.foregroundColor;
        borderWidth = button.style.hovered.borderWidth;
    }

    if (button.buttonState == .Pressed) {
        borderColor = button.style.pressed.borderColor;
        backgroundColor = button.style.pressed.backgroundColor;
        foregroundColor = button.style.pressed.foregroundColor;
        borderWidth = button.style.pressed.borderWidth;
    }

    if (button.disabled) {
        borderColor = button.style.disabled.borderColor;
        backgroundColor = button.style.disabled.backgroundColor;
        foregroundColor = button.style.disabled.foregroundColor;
        borderWidth = button.style.disabled.borderWidth;
    }

    try drawlist.append(
        .{ .node = dlb.node, .primitive = .{ .Rect = .{
            .tl = dlb.resolvedPos,
            .size = dlb.resolvedSize,
            .borderColor = borderColor,
            .backgroundColor = backgroundColor,
            .borderWidth = borderWidth,
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

pub fn buttonMouseOverListener(node: papyrus.NodeHandle, _: ?*anyopaque) papyrus.HandlerError!void {
    var ctx = papyrus.getContext();
    var btn = ctx.getButton(node);
    if (btn.disabled == false) {
        btn.buttonState = .Hovered;
    }
}

pub fn buttonMouseOffListener(node: papyrus.NodeHandle, _: ?*anyopaque) papyrus.HandlerError!void {
    var ctx = papyrus.getContext();
    var btn = ctx.getButton(node);
    if (btn.disabled == false) {
        btn.buttonState = .Normal;
    }
}

pub fn buttonOnPressedEvent(node: papyrus.NodeHandle, eventType: papyrus.PressedType, _: ?*anyopaque) papyrus.HandlerError!void {
    var ctx = papyrus.getContext();
    var btn = ctx.getButton(node);

    if (eventType == .onPressed) {
        btn.buttonState = .Pressed;
    } else if (eventType == .onReleased) {
        btn.buttonState = .Hovered;
    }
}
