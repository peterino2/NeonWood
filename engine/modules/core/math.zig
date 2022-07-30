const std = @import("std");
const misc = @import("misc.zig");
const logging = @import("logging.zig");
const algorithm = @import("algorithm.zig");
const zm = @import("lib/zmath/zmath.zig");

pub fn Vector3Type(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        pub fn new(x: T, y: T, z: T) @This() {
            return .{
                .x = x,
                .y = y,
                .z = z,
            };
        }

        pub fn add(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
                .z = self.z + other.z,
            };
        }

        pub fn div(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
                .z = self.z - other.z,
            };
        }
    };
}

pub const Vector = Vector3Type(f64);
pub const Vectorf = Vector3Type(f32);
pub const Quat = zm.Quat;

pub const LinearColor = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};
pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

// idk why, i just wanted to try this.
pub const Vector32NetQuantized = extern union {
    payload: u64,
    components: packed struct {
        x: u21,
        y: u21,
        z: u21,
    },
};
