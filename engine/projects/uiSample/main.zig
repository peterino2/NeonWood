const std = @import("std");
const nw = @import("root").neonwood;

const ui = nw.ui;

const assets = nw.assets;
const c = nw.graphics.c;

pub const GameContext = struct {
    pub const NeonObjectTable = nw.core.RttiData.from(@This());
    pub const InterfaceUiTable = nw.core.InterfaceUiData.from(@This());

    allocator: std.mem.Allocator,
    debugOpen: bool = true,

    panel: u32 = 0,
    time: f64 = 0,

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
    }

    pub fn tick(self: *@This(), dt: f64) void {
        self.time += dt;

        if (self.time > 5.0) {
            self.time = 0;
        }

        var ctx = ui.getContext();
        ctx.getPanel(self.panel).titleSize = @floatCast(f32, self.time) * 20.0 + 20.0;
    }

    pub fn uiTick(self: *@This(), deltaTime: f64) void {
        _ = deltaTime;
        _ = self;
    }

    pub fn prepare_game(self: *@This()) !void {
        try nw.graphics.getContext().add_ui_object(.{
            .ptr = self,
            .vtable = &InterfaceUiTable,
        });

        var ctx = ui.getContext();
        const BurnStyle = ui.papyrus.BurnStyle;

        self.panel = try ctx.addPanel(0);
        ctx.getPanel(self.panel).hasTitle = true;
        ctx.getPanel(self.panel).titleSize = 20;
        ctx.getPanel(self.panel).titleColor = BurnStyle.Bright1;
        ctx.get(self.panel).text = ui.papyrus.Text("Ui demo program: Hello world.");
        ctx.get(self.panel).pos = .{ .x = 0, .y = 0 };
        ctx.get(self.panel).size = .{ .x = 1600, .y = 900 };
        ctx.get(self.panel).style.borderColor = BurnStyle.Diminished;
        ctx.get(self.panel).style.backgroundColor = BurnStyle.LightGrey;

        const text = try ctx.addText(self.panel, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.");
        ctx.get(text).style.foregroundColor = ui.papyrus.ModernStyle.Orange;
        ctx.get(text).pos = .{ .x = 32, .y = 32 };
        ctx.get(text).size = .{ .x = 300, .y = 400 };
    }
};

pub fn main() anyerror!void {
    nw.graphics.setStartupSettings("maxObjectCount", 10);
    try nw.start_everything("NeonWood: ui");
    defer nw.shutdown_everything();
    try nw.run_no_input_tickable(GameContext);
}
