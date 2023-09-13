const std = @import("std");

pub const Vector2i = struct {
    x: i32 = 0,
    y: i32 = 0,

    pub fn add(self: @This(), o: @This()) @This() {
        return .{ .x = self.x + o.x, .y = self.y + o.y };
    }

    pub fn sub(self: @This(), o: @This()) @This() {
        return .{ .x = self.x - o.x, .y = self.y - o.y };
    }

    pub fn fmul(self: @This(), o: anytype) @This() {
        return .{ .x = self.x * @as(i32, @intFromFloat(o)), .y = self.y * @as(i32, @intFromFloat(o)) };
    }

    pub fn fromVector2(o: Vector2) @This() {
        return .{ .x = @as(i32, @intFromFloat(o.x)), .y = @as(i32, @intFromFloat(o.y)) };
    }
};

pub const Vector2 = struct {
    x: f32 = 0,
    y: f32 = 0,

    pub const Ones = @This(){ .x = 1, .y = 1 };

    pub inline fn dot(self: @This(), o: @This()) f32 {
        return std.math.sqrt(self.x * o.x + self.y * o.y);
    }

    pub inline fn sub(self: @This(), o: @This()) @This() {
        return .{ .x = self.x - o.x, .y = self.y - o.y };
    }

    pub inline fn add(self: @This(), o: @This()) @This() {
        return .{ .x = self.x + o.x, .y = self.y + o.y };
    }

    pub inline fn mul(self: @This(), o: @This()) @This() {
        return .{ .x = self.x * o.x, .y = self.y * o.y };
    }

    pub inline fn fmul(self: @This(), o: anytype) @This() {
        return .{ .x = self.x * @as(f32, @floatCast(o)), .y = self.y * @as(f32, @floatCast(o)) };
    }

    pub inline fn fadd(self: @This(), o: anytype) @This() {
        return .{ .x = self.x + @as(f32, @floatCast(o)), .y = self.y + @as(f32, @floatCast(o)) };
    }

    pub inline fn fsub(self: @This(), o: anytype) @This() {
        return .{ .x = self.x - @as(f32, @floatCast(o)), .y = self.y - @as(f32, @floatCast(o)) };
    }

    pub fn fromVector2i(o: Vector2i) @This() {
        return .{ .x = @as(f32, @floatFromInt(o.x)), .y = @as(f32, @floatFromInt(o.y)) };
    }
};
