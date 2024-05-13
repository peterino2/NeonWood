const std = @import("std");

// RGBA format for color
pub const Color32 = u32;

pub const ColorRGBA8 = extern struct {
    r: u8 = 0x0,
    g: u8 = 0x0,
    b: u8 = 0x0,
    a: u8 = 0xff,

    pub fn fromHex(hex: u32) @This() {
        return .{
            .r = @as(u8, @intCast((hex >> 24) & 0xFF)),
            .g = @as(u8, @intCast((hex >> 16) & 0xFF)),
            .b = @as(u8, @intCast((hex >> 8) & 0xFF)),
            .a = @as(u8, @intCast((hex) & 0xFF)),
        };
    }

    pub fn fromColor(o: Color) @This() {
        return .{
            .r = @as(u8, @intFromFloat(std.math.clamp(o.r, 0, 1.0) * 255)),
            .g = @as(u8, @intFromFloat(std.math.clamp(o.g, 0, 1.0) * 255)),
            .b = @as(u8, @intFromFloat(std.math.clamp(o.b, 0, 1.0) * 255)),
            .a = @as(u8, @intFromFloat(std.math.clamp(o.a, 0, 1.0) * 255)),
        };
    }
};

pub const Color = extern struct {
    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,
    a: f32 = 1.0,

    pub const White = fromRGB(0xFFFFFF);
    pub const Red = fromRGB(0xFF0000);
    pub const Yellow = fromRGB(0xFFFF00);
    pub const Orange = fromRGB(0xFF5500);
    pub const Green = fromRGB(0x00FF00);
    pub const Blue = fromRGB(0x0000FF);
    pub const Cyan = fromRGB(0x00FFFF);
    pub const Magenta = fromRGB(0xFF00FF);
    pub const Black = fromRGB(0x000000);

    pub fn intoRGBA(self: @This()) Color32 {
        return ((@as(u32, @intFromFloat(self.r)) * 0xFF) << 24) |
            ((@as(u32, @intFromFloat(self.g)) & 0xFF) << 16) |
            ((@as(u32, @intFromFloat(self.b)) & 0xFF) << 8) |
            ((@as(u32, @intFromFloat(self.a)) & 0xFF));
    }

    pub fn fromRGB2(r: anytype, g: anytype, b: anytype) @This() {
        return @This(){ .r = r, .g = g, .b = b, .a = 1.0 };
    }

    pub fn fromRGBA2(r: anytype, g: anytype, b: anytype, a: anytype) @This() {
        return @This(){ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn fromRGB(rgb: u32) @This() {
        return @This(){
            .r = @as(f32, @floatFromInt((rgb >> 16) & 0xFF)) / 255,
            .g = @as(f32, @floatFromInt((rgb >> 8) & 0xFF)) / 255,
            .b = @as(f32, @floatFromInt((rgb) & 0xFF)) / 255,
            .a = 1.0,
        };
    }

    pub fn fromRGBA(rgba: u32) @This() {
        return @This(){
            .r = @as(f32, @floatFromInt((rgba >> 24) & 0xFF)) / 255,
            .g = @as(f32, @floatFromInt((rgba >> 16) & 0xFF)) / 255,
            .b = @as(f32, @floatFromInt((rgba >> 8) & 0xFF)) / 255,
            .a = @as(f32, @floatFromInt((rgba) & 0xFF)) / 255,
        };
    }
};
