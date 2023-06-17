const std = @import("std");
const nw = @import("root").neonwood;

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
        _ = self;
        _ = deltaTime;
    }

    pub fn prepare_game(self: *@This()) !void {
        try nw.graphics.getContext().add_ui_object(.{
            .ptr = self,
            .vtable = &InterfaceUiTable,
        });
    }
};

pub fn main() anyerror!void {
    try nw.start_everything("NeonWood: ui");
    defer nw.shutdown_everything();
    try nw.run_no_input(GameContext);
}
