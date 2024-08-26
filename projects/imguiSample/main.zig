const std = @import("std");

const neonwood = @import("NeonWood");
const core = neonwood.core;
const vkImgui = neonwood.vkImgui;
const c = vkImgui.c;

pub const GameContext = struct {
    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    allocator: std.mem.Allocator,
    showDemoWindow: bool = true,

    implot: [*c]c.ImPlotContext = null,

    first: bool = true,

    pub fn tick(self: *@This(), deltaTime: f64) void {
        _ = deltaTime;
        c.igShowDemoWindow(&self.showDemoWindow);
        c.ImPlot_ShowDemoWindow(&self.showDemoWindow);
        if (self.first) {
            self.first = false;
            core.MemoryTracker.MTPrintStatsDelta();
        }
    }

    pub fn prepare_game(self: *@This()) !void {
        self.implot = c.ImPlot_CreateContext();

        core.MemoryTracker.MTPrintStatsDelta();
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
    try neonwood.initializeAndRunStandardProgram(GameContext, .{
        .name = "imguiSample",
        .enabledModules = .{
            .ui = false,
            .papyrus = false,
        },
    });
}
