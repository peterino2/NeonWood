name: []const u8 = "unnamed_entity",

pub const SampleSystem = struct {
    allocator: std.mem.Allocator,

    pub const EcsSystemVTable = EcsSystemInterface.Implement(@This());

    pub fn create(allocator: std.mem.Allocator) core.EngineDataEventError!*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .allocator = allocator,
        };

        return self;
    }

    pub fn tick(self: *@This(), dt: f64) void {
        _ = self;
        _ = dt;
        core.engine_log("SampleComponentBaseContainer @{x}", .{@intFromPtr(BaseContainer)});
        for (BaseContainer.list.items, 0..) |component, i| {
            core.engine_log("SampleSystem working on specific SystemComponent {s} index: {d} handle: {d}, {d}", .{
                component.name,
                i,
                BaseContainer.handles.items[i].generation,
                BaseContainer.handles.items[i].index,
            });
        }
    }

    pub fn destroy(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

pub var BaseContainer: *core.SparseMap(@This()) = undefined;
const std = @import("std");
const core = @import("NeonWood").core;
const ecs = core.ecs;
const EcsSystemInterface = core.EcsSystemInterface;
