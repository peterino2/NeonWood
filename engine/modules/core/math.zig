const std = @import("std");
const misc = @import("misc.zig");
const logging = @import("logging.zig");
const algorithm = @import("lib/p2/algorithm.zig");
const zm = @import("lib/zmath/zmath.zig");
const math = std.math;

// super ghetto math library

pub const Rayf = RayType(f32);

pub fn matToScalef(mat: anytype) Vectorf {
    const x = Vectorf.new(mat[0][0], mat[0][1], mat[0][2]).length();
    const y = Vectorf.new(mat[1][0], mat[1][1], mat[1][2]).length();
    const z = Vectorf.new(mat[2][0], mat[2][1], mat[2][2]).length();

    return Vectorf.new(x, y, z);
}

pub fn RayType(comptime T: type) type {
    return struct {
        start: Vector3Type(T),
        dir: Vector3Type(T),
    };
}

pub fn clamp(x: anytype, min: anytype, max: anytype) @TypeOf(x) {
    if (x < min)
        return min;
    if (x > max)
        return max;
    return x;
}

pub fn matFromEulerAngles(x: f32, y: f32, z: f32) Mat {
    return zm.matFromRollPitchYaw(y, z, x);
}

pub fn Radians(comptime T: type) type {
    return struct {
        value: T,

        pub fn fromDegrees(f: anytype) @This() {
            return .{ .value = f };
        }
    };
}

pub fn radians(f: anytype) @TypeOf(f) {
    return f * math.pi / 180.0;
}

pub fn fabs(x: anytype) @TypeOf(x) {
    if (x < 0)
        return -x;
    return x;
}

pub fn Vector2Type(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        pub inline fn new(x: T, y: T) @This() {
            return .{
                .x = x,
                .y = y,
            };
        }

        pub inline fn zero() @This() {
            return .{
                .x = 0.0,
                .y = 0.0,
            };
        }

        pub inline fn add(self: @This(), other: anytype) @This() {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub inline fn sub(self: @This(), other: anytype) @This() {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }

        pub inline fn fmul(self: @This(), other: anytype) @This() {
            return .{
                .x = self.x * other.x,
                .y = self.y * other.y,
            };
        }

        pub inline fn normalize(self: @This()) @This() {
            if (fabs(self.x) <= 0.0001 and fabs(self.y) <= 0.0001) {
                return .{ .x = 0, .y = 0 };
            }
            var len = std.math.sqrt(self.x * self.x + self.y * self.y);

            if (len < 0.00001)
                return .{ .x = 0, .y = 0 };

            return .{
                .x = self.x / len,
                .y = self.y / len,
            };
        }

        pub inline fn dot(self: @This(), other: @This()) T {
            return self.x * other.x + self.y * other.y;
        }

        pub inline fn length(self: @This()) T {
            return std.math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
        }

        pub inline fn swizzleYX(self: @This()) @This() {
            return .{ .x = self.y, .y = self.x };
        }
    };
}

pub fn Vector3Type(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        pub inline fn new(x: T, y: T, z: T) @This() {
            return .{
                .x = x,
                .y = y,
                .z = z,
            };
        }

        pub inline fn toZm(self: @This()) zm.Vec {
            return .{ self.x, self.y, self.z, 1.0 };
        }

        pub inline fn fromZm(vec: zm.Vec) @This() {
            return @This().new(vec[0], vec[1], vec[2]);
        }

        pub inline fn add(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
                .z = self.z + other.z,
            };
        }

        pub inline fn sub(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
                .z = self.z - other.z,
            };
        }

        pub inline fn vmul(self: @This(), other: anytype) @This() {
            return .{
                .x = self.x * other.x,
                .y = self.y * other.y,
                .z = self.z * other.z,
            };
        }

        pub inline fn fmul(self: @This(), other: anytype) @This() {
            return .{
                .x = self.x * other,
                .y = self.y * other,
                .z = self.z * other,
            };
        }

        pub inline fn equals(self: @This(), other: anytype) bool {
            return self.x == other.x and self.y == self.y and self.z == self.z;
        }

        pub inline fn zero() @This() {
            return .{ .x = 0, .y = 0, .z = 0 };
        }

        pub inline fn length(self: @This()) T {
            return std.math.sqrt(self.x * self.x + self.z * self.z + self.y * self.y);
        }

        pub inline fn lengthXZ(self: @This()) T {
            return std.math.sqrt(self.x * self.x + self.z * self.z);
        }

        pub inline fn normalize(self: @This()) @This() {
            if (fabs(self.x) <= 0.0001 and fabs(self.y) <= 0.0001 and fabs(self.z) <= 0.0001) {
                return .{ .x = 0, .y = 0, .z = 0 };
            }
            var len = std.math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);

            if (len < 0.00001)
                return .{ .x = 0, .y = 0, .z = 0 };

            return .{
                .x = self.x / len,
                .y = self.y / len,
                .z = self.z / len,
            };
        }
    };
}

pub fn Vector4Type(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,
        w: T,

        pub inline fn new(x: T, y: T, z: T, w: T) @This() {
            return .{
                .x = x,
                .y = y,
                .z = z,
                .w = w,
            };
        }

        pub inline fn add(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
                .z = self.z + other.z,
                .w = self.w + other.w,
            };
        }

        pub inline fn sub(self: @This(), other: @This()) @This() {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
                .z = self.z - other.z,
                .w = self.w - other.w,
            };
        }

        pub inline fn normalize(self: @This()) @This() {
            var len = std.math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w);

            return .{
                .x = self.x / len,
                .y = self.y / len,
                .z = self.z / len,
                .w = self.w / len,
            };
        }
    };
}

pub const Vector = Vector3Type(f64);
pub const Vector4 = Vector4Type(f64);
pub const Vectorf = Vector3Type(f32);
pub const Vector2f = Vector2Type(f32);
pub const Vector2 = Vector2Type(f64);

pub const Vector2i = Vector2Type(i32);
pub const Vector2c = Vector2Type(c_int);
pub const Vector2u = Vector2Type(u32);
pub const Vector2l = Vector2Type(i64);

pub const EulerAngles = Vector3Type(f32);
pub const Vector4f = Vector4Type(f32);
pub const Quat = zm.Quat;
pub const Mat = zm.Mat;
pub const Transform = zm.Mat;

pub const Rotation = struct {
    quat: Quat = zm.qidentity(),

    pub fn init() @This() {
        return .{
            .quat = .{ 0, 0, 0, 0 },
        };
    }

    pub fn rotateVector(self: @This(), other: anytype) @TypeOf(other) {
        return zm.mul(zm.quatToMat(self.quat), other.toZm());
    }
};

pub fn simdVec4ToVec(vec: zm.Vec) Vector4f {
    return .{
        .x = vec[0],
        .y = vec[1],
        .z = vec[2],
        .w = vec[3],
    };
}

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
