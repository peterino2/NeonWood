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
        ctx.getPanel(self.panel).titleSize = 18;
        ctx.getPanel(self.panel).titleColor = BurnStyle.SlateGrey;
        ctx.get(self.panel).text = ui.papyrus.Text("Ui demo program: Hello world.");
        ctx.get(self.panel).pos = .{ .x = 0, .y = 0 };
        ctx.get(self.panel).size = .{ .x = 1600, .y = 900 };
        ctx.get(self.panel).style.borderColor = BurnStyle.Bright1;
        ctx.get(self.panel).style.backgroundColor = BurnStyle.DarkSlateGrey;

        var panel2 = try ctx.addPanel(self.panel);
        ctx.get(panel2).style = ctx.get(self.panel).style;
        ctx.get(panel2).style.backgroundColor = BurnStyle.LightGrey;
        ctx.get(panel2).style.borderColor = BurnStyle.LightGrey;
        ctx.get(panel2).size = .{ .x = 1600 - 45 - 5, .y = 900 - 18 - 5 - 5 };
        ctx.get(panel2).pos = .{ .x = 45, .y = 5 };
    }
};

pub fn main() anyerror!void {
    try nw.start_everything("NeonWood: ui");
    defer nw.shutdown_everything();
    try nw.run_no_input(GameContext);
}
