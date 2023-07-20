const std = @import("std");
const nw = @import("root").neonwood;

const ui = nw.ui;
const platform = nw.platform;

const assets = nw.assets;
const c = nw.graphics.c;

pub const GameContext = struct {
    pub const NeonObjectTable = nw.core.RttiData.from(@This());
    pub const InterfaceUiTable = nw.core.InterfaceUiData.from(@This());

    allocator: std.mem.Allocator,
    debugOpen: bool = true,

    text: u32 = 0,
    fps: u32 = 0,
    mousePosition: u32 = 0,
    panel: u32 = 0,
    time: f64 = 0,

    fpsText: ?[]u8 = null,
    mousePositionText: ?[]u8 = null,

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        var self = try allocator.create(@This());
        self.* = .{ .allocator = allocator };
        return self;
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
    }

    pub fn tick(self: *@This(), dt: f64) void {
        self.time += dt;

        if (self.time > 5.0) {
            self.time = 0;
        }

        if (self.fpsText) |t| {
            self.allocator.free(t);
        }
        self.fpsText = std.fmt.allocPrint(self.allocator, "fps: {d:.2}", .{1.0 / dt}) catch unreachable;

        const inputState = nw.platform.getInstance().inputState;

        var mouse = inputState.mousePos;
        if (self.mousePositionText) |t| {
            self.allocator.free(t);
        }
        self.mousePositionText = std.fmt.allocPrint(self.allocator, "mousePosition: {d:.2} {d:.2}", .{ mouse.x, mouse.y }) catch unreachable;

        var ctx = ui.getContext();

        // holy crap that's bad i need a better way to automate this.
        ctx.get(self.fps).text = ui.papyrus.LocText.fromUtf8(self.fpsText.?);
        ctx.get(self.mousePosition).text = ui.papyrus.LocText.fromUtf8(self.mousePositionText.?);
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
        ctx.setFont(self.panel, "roboto");
        ctx.get(self.panel).text = ui.papyrus.Text("Ui demo program: Hello world.");
        ctx.get(self.panel).pos = .{ .x = 0, .y = 0 };
        ctx.get(self.panel).size = .{ .x = 1600, .y = 900 };
        ctx.get(self.panel).style.borderColor = BurnStyle.Diminished;
        ctx.get(self.panel).style.backgroundColor = BurnStyle.LightGrey;

        const text = try ctx.addText(self.panel, ipsum);
        ctx.setFont(text, "roboto");
        ctx.getText(text).textSize = 28;
        ctx.get(text).pos = .{ .x = 32, .y = 64 };
        ctx.get(text).size = .{ .x = 1400, .y = 500 };
        self.text = text;

        self.mousePosition = try ctx.addText(self.panel, "");
        {
            var widget = ctx.get(self.mousePosition);
            widget.style.foregroundColor = ui.papyrus.ModernStyle.Orange;
            widget.pos = .{ .x = -300, .y = 12 };
            widget.size = .{ .x = 1400, .y = 500 };
            widget.anchor = .TopRight;
            ctx.setFont(self.mousePosition, "roboto");
        }

        const fps = try ctx.addText(self.panel, "fps: {}");
        ctx.setFont(fps, "roboto");
        ctx.get(fps).style.foregroundColor = ui.papyrus.ModernStyle.Orange;
        ctx.get(fps).pos = .{ .x = 32, .y = 12 };
        ctx.get(fps).size = .{ .x = 1400, .y = 500 };
        self.fps = fps;
    }
};

const ipsum =
    \\ Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque gravida nec urna at porta. Interdum et malesuada fames ac ante ipsum primis in faucibus. Morbi non felis nisi. Aliquam lectus enim, cursus a mollis sed, aliquam ut risus. Nam dolor urna, fermentum consectetur enim vitae, tempus scelerisque urna. Vestibulum quam sem, faucibus ac volutpat ut, semper in ipsum. Maecenas ornare lectus massa, in lacinia nulla feugiat et. Vestibulum blandit justo at ipsum aliquet, consectetur ultrices libero finibus. Vestibulum ut risus ac metus gravida aliquet. Quisque vel neque eu nisl consectetur iaculis id tincidunt odio. Maecenas rhoncus tristique ullamcorper. Vivamus egestas massa in nulla malesuada ullamcorper. Nullam sed nibh id lacus rutrum interdum a ut ex. Mauris nec odio tempor, pretium arcu et, auctor purus.
    \\ Morbi imperdiet sapien eros, at mollis velit efficitur ac. Ut dictum sapien erat, nec pulvinar justo congue at. Integer ac fringilla mauris. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla lacinia arcu et dignissim bibendum. Cras feugiat consequat ante ac fermentum. Ut luctus ante quis est efficitur laoreet. Donec consequat, nisl vel fringilla condimentum, purus leo finibus dolor, imperdiet rutrum risus orci non sapien. Phasellus in maximus augue. Praesent rhoncus sagittis mi vitae elementum. Integer id blandit diam. Sed ut augue id orci venenatis suscipit nec at velit. Vestibulum luctus pretium nisl, quis pretium neque tristique a. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Interdum et malesuada fames ac ante ipsum primis in faucibus. Suspendisse in pretium sapien.
    \\ Sed non interdum tellus. Quisque id ipsum ut arcu fringilla auctor non et nulla. Maecenas convallis, eros sit amet dapibus consectetur, ante risus placerat diam, vel porta felis nisi eget nisi. Sed justo turpis, accumsan eget nunc non, condimentum consequat quam. Vivamus varius nibh ex, eu luctus tellus tempor sed. In egestas ultricies massa, in pulvinar nulla. Phasellus sit amet erat sit amet massa ultrices finibus. Nullam elementum odio non auctor finibus. Phasellus ultrices, purus nec semper finibus, nunc libero fermentum odio, non aliquam risus risus eget ipsum. Nam urna ligula, vestibulum et arcu et, egestas sollicitudin justo.
    \\ Donec cursus placerat massa et vulputate. Duis egestas malesuada erat, quis finibus tellus finibus vitae. Ut malesuada blandit ultrices. Maecenas faucibus volutpat risus, in fringilla libero. Etiam pharetra interdum mi, malesuada sagittis neque feugiat at. Nullam pellentesque ultricies consequat. Ut consectetur, orci id gravida pellentesque, tortor ante fringilla dui, at condimentum neque ligula sed eros. Cras vulputate velit urna, vitae volutpat enim varius quis. Curabitur lorem mi, viverra vel tellus vehicula, eleifend viverra mauris. Proin fringilla eleifend elit, sed dapibus purus porttitor non.
    \\ Maecenas vitae nibh id leo laoreet luctus. In hac habitasse platea dictumst. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Donec vitae lorem mollis nisl hendrerit rhoncus. Nullam convallis tincidunt massa, ut interdum arcu elementum elementum. Nulla facilisi. Praesent molestie lacinia elit. Pellentesque consequat tincidunt ipsum, vel auctor dui mattis non. Donec vel sem vel dolor viverra feugiat eget ac sem. Vestibulum eget magna massa. Aliquam eget malesuada neque. Integer sodales pulvinar elit id luctus. Phasellus ultricies magna sed pellentesque pretium. Phasellus et nibh ac dui tempor porttitor nec id libero.
    \\ Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Integer tristique turpis et bibendum interdum. Sed ut viverra sem. Phasellus et sapien quis odio euismod hendrerit sit amet id purus. Ut convallis ac elit nec convallis. Nunc interdum sed elit id mollis. Nullam molestie pretium pretium. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Vestibulum congue orci ut metus lacinia, non gravida odio tristique. Aliquam.
;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const cleanupStatus = gpa.deinit();
        if (cleanupStatus == .leak) {
            std.debug.print("gpa cleanup leaked memory\n", .{});
        }
    }
    const allocator = std.heap.c_allocator;

    nw.graphics.setStartupSettings("maxObjectCount", 100);
    try nw.start_everything(allocator, "NeonWood: ui");
    defer nw.shutdown_everything(allocator);
    try nw.run_no_input_tickable(GameContext);
}
