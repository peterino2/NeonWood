const std = @import("std");
const core = @import("core");
const colors = core.colors;

// ========================= Color =========================

pub const ColorRGBA8 = colors.ColorRGBA8;
pub const Color = colors.Color;
pub const Color32 = colors.Color32;

// Color style used for my text editor
pub const BurnStyle = struct {
    pub const Comment = Color.fromRGB(0x90c480);
    pub const DarkComment = Color.fromRGB(0x243120);
    pub const Normal = Color.fromRGB(0xe2e2e5);
    pub const Diminished = Color.fromRGB(0x828285);
    pub const Highlight1 = Color.fromRGB(0x90c480);
    pub const Highlight2 = Color.fromRGB(0x75e1eb);
    pub const Highlight3 = Color.fromRGB(0xff9900);
    pub const Bright1 = Color.fromRGB(0xfaf4c6);
    pub const Bright2 = Color.fromRGB(0xffff00);
    pub const Statement = Color.fromRGB(0xff00f2);
    pub const LineTerminal = Color.fromRGB(0x87aefa);
    pub const SlateGrey = Color.fromRGB(0x141414);
    pub const BrightGrey = Color.fromRGB(0x444444);
    pub const LightGrey = Color.fromRGB(0x242424);
    pub const DarkSlateGrey = Color.fromRGB(0x101010);
};

// Color Style generated from some website
pub const ModernStyle = struct {
    pub const Grey = Color.fromRGB(0x333348);
    pub const GreyLight = Color.fromRGB(0x44445F);
    pub const GreyDark = Color.fromRGB(0x222230);
    pub const Yellow = Color.fromRGB(0xf0cc56);
    pub const Orange = Color.fromRGB(0xcf5c36);
    pub const BrightGrey = Color.fromRGB(0x90a9b7);
    pub const Blue = Color.fromRGB(0x3c91e6);
};

// ========================= Localization ======================
