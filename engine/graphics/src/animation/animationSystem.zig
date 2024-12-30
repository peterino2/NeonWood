// big main system for animation

const ozz = @import("ozz");
const core = @import("core");
const std = @import("std");

pub const AnimationComponent = struct {
    pub var BaseContainer: *core.SparseMap(@This()) = undefined;
    pub const ComponentName = "AnimationComponent";
    pub const ScriptExports: []const []const u8 = &.{"getAnimationName"};
};

pub const AnimationSystem = struct {
    allocator: std.mem.Allocator,

    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    pub fn tick(self: *@This(), dt: f64) void {
        _ = self;
        _ = dt;
    }

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

var gAnimation: *AnimationSystem = undefined;
