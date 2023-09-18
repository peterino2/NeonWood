const std = @import("std");
const papyrus = @import("papyrus.zig");

const PapyrusContext = papyrus.PapyrusContext;

allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{
        .allocator = allocator,
    };
}

pub fn tick(self: *@This(), papyrusCtx: *PapyrusContext, deltaTime: f64) !void {
    _ = self;
    _ = papyrusCtx;
    _ = deltaTime;
}

pub fn deinit(self: *@This()) void {
    _ = self;
}
