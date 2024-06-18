const std = @import("std");

const neonwood = @import("NeonWood");
const core = neonwood.core;
const vkImgui = neonwood.vkImgui;
const c = vkImgui.c;

pub const GameContext = struct {
    pub var NeonObjectTable: core.RttiData = core.RttiData.from(@This());

    allocator: std.mem.Allocator,
    showDemoWindow: bool = true,

    implot: [*c]c.ImPlotContext = null,

    pub fn tick(self: *@This(), deltaTime: f64) void {
        _ = deltaTime;
        c.igShowDemoWindow(&self.showDemoWindow);
        c.ImPlot_ShowDemoWindow(&self.showDemoWindow);
    }

    pub fn prepare_game(self: *@This()) !void {
        self.implot = c.ImPlot_CreateContext();
    }

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
        };
        return self;
    }

    pub fn deinit(self: *@This()) void {
        c.ImPlot_DestroyContext(self.implot);
        self.allocator.destroy(self);
    }
};

pub fn main() anyerror!void {
    try neonwood.initializeAndRunStandardProgram(GameContext, .{});
}
