// Main text entry engine rooted in papyrus

backingAllocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
ctx: *papyrus.Context,

const std = @import("std");
const papyrus = @import("../papyrus.zig");
const NodeHandle = papyrus.NodeHandle;
const Context = papyrus.Context;
const core = @import("../../core.zig");

pub fn create(ctx: *papyrus.Context, backingAllocator: std.mem.Allocator) !*@This() {
    var self = try backingAllocator.create(@This());

    self.* = .{
        .ctx = ctx,
        .backingAllocator = backingAllocator,
        .arena = std.heap.ArenaAllocator.init(backingAllocator),
    };

    return self;
}

pub fn sendCodePoint(self: *@This(), codepoint: u32) !void {
    _ = self;
    core.ui_log("codepoint recieved (4): {s}", .{@as([4]u8, @bitCast(codepoint))});
}

pub fn tickUpdates(self: *@This()) !void {
    _ = self;
}

pub fn selectTextForEdit(self: *@This(), node: NodeHandle) void {
    self.ctx.getTextEntry(node).entryState = .Pressed;
}

pub fn destroy(self: *@This()) void {
    self.arena.deinit();
    self.backingAllocator.destroy(self);
}

// ===== key events =====
pub fn sendEscape(self: *@This()) !void {
    _ = self;
    core.ui_logs("escape recieved");
}

pub fn sendEnter(self: *@This()) !void {
    _ = self;
    core.ui_logs("enter recieved");
}

pub fn sendTab(self: *@This()) !void {
    _ = self;
    core.ui_logs("tab recieved");
}

pub fn sendBackspace(self: *@This()) !void {
    _ = self;
    core.ui_logs("backspace recieved");
}

pub fn sendDelete(self: *@This()) !void {
    _ = self;
    core.ui_logs("delete recieved");
}

pub fn sendRight(self: *@This()) !void {
    _ = self;
    core.ui_logs("right recieved");
}

pub fn sendLeft(self: *@This()) !void {
    _ = self;
    core.ui_logs("left recieved");
}

pub fn sendUp(self: *@This()) !void {
    _ = self;
    core.ui_logs("up recieved");
}

pub fn sendDown(self: *@This()) !void {
    _ = self;
    core.ui_logs("down recieved");
}

pub fn sendPageup(self: *@This()) !void {
    _ = self;
    core.ui_logs("pageup recieved");
}

pub fn sendPagedown(self: *@This()) !void {
    _ = self;
    core.ui_logs("pagedown recieved");
}

pub fn sendHome(self: *@This()) !void {
    _ = self;
    core.ui_logs("home recieved");
}

pub fn sendEnd(self: *@This()) !void {
    _ = self;
    core.ui_logs("end recieved");
}
