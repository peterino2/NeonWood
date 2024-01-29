textSize: f32 = 24,
font: papyrus.PapyrusFont,
disabled: bool = false,
entryState: TextEntryState = .Normal,
entryStubPosition: u32 = 0,

pub const TextEntryStyle = struct {
    normal: papyrus.PapyrusNodeStyle = .{
        .borderColor = BurnStyle.Diminished,
    },
    typing: papyrus.PapyrusNodeStyle = .{
        .borderColor = BurnStyle.LightGrey,
    },
};

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
    const button = dlb.n.nodeType.Button;

    // 0. select colors
    // 1. draw the rect
    // 2.

    _ = drawlist;
    _ = button;
}
