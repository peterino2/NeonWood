// Draw command

node: papyrus.NodeHandle,
primitive: union(enum(u8)) {
    Rect: PrimitiveRect,
    Text: PrimitiveText,
},

pub const papyrus = @import("papyrus.zig");
pub const core = @import("core");

pub const PrimitiveRect = struct {
    tl: core.Vector2f,
    size: core.Vector2f,
    borderColor: papyrus.Color,
    backgroundColor: papyrus.Color,
    rounding: struct {
        tl: f32 = 0,
        tr: f32 = 0,
        bl: f32 = 0,
        br: f32 = 0,
    } = .{},
    borderWidth: f32 = 1.1,
    imageRef: ?core.Name = null,
};

pub const PrimitiveText = struct {
    tl: core.Vector2f,
    size: core.Vector2f,
    renderMode: papyrus.TextRenderMode,
    text: papyrus.LocText,
    color: papyrus.Color,
    textSize: f32,
    rendererHash: u32,
    flags: packed struct {
        setSourceGeometry: bool,
    },
};
