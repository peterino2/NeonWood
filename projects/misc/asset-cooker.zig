allocator: std.mem.Allocator,
open: bool = false,

browser: *Browser = undefined,

pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

pub fn tick(self: *@This(), _: f64) void {
    _ = self;
}

// setup functions below
pub fn init(alloc: std.mem.Allocator) !*@This() {
    const self = try alloc.create(@This());
    self.* = .{ .allocator = alloc };
    return self;
}

pub fn prepare(self: *@This()) !void {
    self.browser = try Browser.create(self.allocator);
}

pub fn deinit(self: *@This()) void {
    self.browser.destroy();
    self.allocator.destroy(self);
}

pub fn main() !void {
    core.stacks.initStackCompactor();
    try neonwood.initializeAndRunStandardProgram(@This(), .{ .name = "cooking tool" });
}

const neonwood = @import("NeonWood");
const core = neonwood.core;
const ui = neonwood.ui;
const std = @import("std");
const Browser = @import("asset-cooker/Browser.zig");
