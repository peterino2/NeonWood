textSize: f32 = 24,
font: papyrus.PapyrusFont,
disabled: bool = false,
entryState: TextEntryState = .Normal,
entryStubPosition: u32 = 0,

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

pub fn addToDrawList(dlb: DrawListBuilder) !void {
    _ = dlb;
}
