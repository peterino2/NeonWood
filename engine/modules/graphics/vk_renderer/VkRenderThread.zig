// Main renderthread implementation
//
//
//
// 1. take the draw function from vk_renderer implement it here
// 2. any values from vk_renderer that must be directly utilized, it must be moved here into this struct
// 3. call renderThread's request draw command instead of the original one
// 4. requestDraw directly calls this RenderThread.draw command (no threading)
// 5. move RenderThread.draw() into RenderThread.loop()

allocator: std.mem.Allocator,
gc: *NeonVkContext,

const std = @import("std");
const core = @import("../../core.zig");

const vk_renderer = @import("../vk_renderer.zig");

const NeonVkContext = vk_renderer.NeonVkContext;

pub fn create(gc: *NeonVkContext) !*@This() {
    var self = gc.allocator.create(@This());

    self.* = .{
        .allocator = gc.allocator,
        .gc = gc,
    };

    return self;
}

pub fn setup(self: *@This()) !void {
    _ = self;
    // setup whatever you need to
}

pub fn requestDraw(self: *@This()) !void {
    try self.drawFrame();
}

pub fn drawFrame(self: *@This()) !void {
    core.graphics_log("drawing frame", .{});
    try self.acquire_next_frame();
}

/// ======== internal functions ==========
fn acquire_next_frame() void {}
