const std = @import("std");
const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const Renderer = @import("papyrus/vk_renderer.zig");
const papyrus = @import("papyrus/papyrus.zig");

gc: *graphics.NeonVkContext,
allocator: std.mem.Allocator,
renderer: Renderer,

pub const NeonObjectTable = core.RttiData.from(@This());

pub fn init(allocator: std.mem.Allocator) @This() {
    core.ui_log("papyrus subsystem initialized", .{});
    return .{
        .allocator = allocator,
        .renderer = undefined,
        .gc = undefined,
    };
}

pub fn setup(self: *@This(), gc: *graphics.NeonVkContext) !void {
    self.gc = gc;
    self.renderer = try Renderer.init(gc, self.allocator);
}

pub fn tick(self: *@This(), deltaTime: f64) void {
    _ = self;
    _ = deltaTime;
}

pub fn uiTick(self: *@This(), deltaTime: f64) void {
    _ = self;
    _ = deltaTime;
}

pub fn deinit(self: *@This()) void {
    _ = self;
}

pub fn processEvents(self: *@This(), frameNumber: u64) core.RttiDataEventError!void {
    _ = frameNumber;
    _ = self;
}
