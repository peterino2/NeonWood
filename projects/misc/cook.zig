// asset management/cooking tool.
//

allocator: std.mem.Allocator,
open: bool = false,

browser: *Browser = undefined,

pub const CookerArgs = struct {
    root: ?[]const u8, // --root=<path_to_content> defaults to $project/content
    target: ?[]const u8, // --target=* cooks the given target. defaults to everything.
};

pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

pub fn tick(self: *@This(), _: f64) void {
    _ = self;
    core.exitNow();
}

// setup functions below
pub fn init(alloc: std.mem.Allocator) !*@This() {
    const self = try alloc.create(@This());
    self.* = .{ .allocator = alloc };
    return self;
}

pub fn prepare(self: *@This()) !void {
    _ = self;
    //
}

pub fn deinit(self: *@This()) void {
    self.allocator.destroy(self);
}

pub fn main() !void {
    core.stacks.initStackCompactor();
    try neonwood.initializeAndRunStandardProgram(@This(), .{
        .name = "Cooking Tool",
        .utility = true, // do not initialize vk_renderer, or platform.windowing
        .cooking = true,
    });
}

const neonwood = @import("NeonWood");
const core = neonwood.core;
const ui = neonwood.ui;
const std = @import("std");
const Browser = @import("asset-cooker/Browser.zig");
