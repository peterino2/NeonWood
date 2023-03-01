const std = @import("std");
const core = @import("../core.zig");

const Name = core.Name;
const SparseSet = core.SparseSet;
const ObjectHandle = core.ObjectHandle;

pub const PapyrusAnchorMode = enum {
    Absolute,
    TopLeft,
    MidLeft,
    BotLeft,
    TopMiddle,
    MidMiddle,
    BotMiddle,
    TopRight,
    MidRight,
    BotRight,
};

pub const PapyrusWidgetVisibility = enum {
    Visible,
    Hidden,
};

pub const PapyrusWidget = struct {
    parent: ObjectHandle = .{},
    anchor: PapyrusAnchorMode = .TopLeft,
    visibility: PapyrusWidgetVisibility = .Visible,
    position: core.Vector2f = .{},
    size: core.Vector2f = .{ 100, 100 },
    scale: core.Vector2f = .{ 1.0, 1.0 },
    rotation: f32 = 0,
};

const PapyrusWidgetSet = core.SparseMultiSet(struct { widget: PapyrusWidget, });

pub const PapyrusSubystem = struct {
    pub const NeonObjectTable = core.RttiData.from(@This());

    allocator: std.mem.Allocator,
    widgets: PapyrusWidgetSet,

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .allocator = allocator,
            .widget = PapyrusWidgetSet.init(allocator),
        };
    }

    pub fn createWidget(self: *@This()) ObjectHandle {
        var rv = try self.widgets.createObject(.{ .widget = .{} });
        return rv;
    }

    pub fn uiTick(self: *@This(), deltaTime: f64) void {
        for (self.widgets.dense.items(.widget)) |*widget, i|
        {
        }
    }

    pub fn deinit(self: *@This()) void {
        _ = self;
    }

    pub fn processEvents(self: *@This(), frameNumber: u64) core.RtttiEventData!void {
        _ = frameNumber;
        _ = self;
    }
};
