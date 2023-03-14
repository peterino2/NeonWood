const std = @import("std");
const nw = @import("modules/neonwood.zig");

const assets = nw.assets;
const c = nw.graphics.c;

pub const GameContext = struct {
    pub const NeonObjectTable = nw.core.RttiData.from(@This());
    pub const InterfaceUiTable = nw.core.InterfaceUiData.from(@This());

    allocator: std.mem.Allocator,
    debugOpen: bool = true,

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
    }

    pub fn uiTick(self: *@This(), deltaTime: f64) void {
        _ = deltaTime;

        nw.graphics.imguiUtils.setupDockspace("Dockspace");

        if (self.debugOpen) {
            if (c.igBegin("Debug Menu", &self.debugOpen, 0)) {
                c.igText("Sample Text");
                if (c.igButton("Press me!", .{ .x = 250.0, .y = 30.0 })) {
                    nw.core.engine_logs("I have been pressed!");
                    self.debugOpen = false;
                }
            }
            c.igEnd();
        }
    }

    pub fn prepare_game(self: *@This()) !void {
        try nw.graphics.getContext().add_ui_object(.{
            .ptr = self,
            .vtable = &InterfaceUiTable,
        });
    }
};

pub fn main() anyerror!void {
    nw.start_everything("NeonWood: imgui demo");
    defer nw.shutdown_everything();
    try nw.run_no_input(GameContext);
}
