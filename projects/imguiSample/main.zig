const std = @import("std");

const neonwood = @import("NeonWood");
const core = neonwood.core;
const graphics = neonwood.graphics;
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
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .stack_trace_frames = 20,
    }){};

    defer {
        const cleanupStatus = gpa.deinit();
        if (cleanupStatus == .leak) {
            std.debug.print("gpa cleanup leaked memory\n", .{});
        }
    }
    const memory = core.MemoryTracker;

    memory.MTSetup(gpa.allocator());
    defer memory.MTShutdown();

    var tracker = memory.MTGet().?;
    var allocator = tracker.allocator();

    const args = try neonwood.getArgs();

    if (args.useGPA) {
        allocator = gpa.allocator();
    }

    if (args.vulkanValidation) {
        core.engine_logs("Using vulkan validation");
    }

    graphics.setStartupSettings("vulkanValidation", args.vulkanValidation);

    try neonwood.start_everything_imgui(allocator, .{ .windowName = "NeonWood: ui" }, args);
    defer neonwood.shutdown_everything_imgui(allocator);

    try neonwood.run_everything(GameContext);
}
