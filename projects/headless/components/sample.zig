pub const SampleComponent = struct {
    name: []const u8 = "unnamed_entity",

    pub fn setName(self: *@This(), name: []const u8) void {
        self.name = name;
    }

    pub var BaseContainer: *core.SparseMap(@This()) = undefined;
    pub const ComponentName = "SampleComponent";
    pub const ScriptExports: []const []const u8 = &.{"setName"};
};

pub const SampleSystem = struct {
    allocator: std.mem.Allocator,

    // systems are singleton objects which are part of the ecs tickgroup
    // they should be the main way we implement modular functionality for ecs components
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
        core.engine_log("SampleComponentBaseContainer @{x}", .{@intFromPtr(SampleComponent.BaseContainer)});
        for (SampleComponent.BaseContainer.list.items, 0..) |component, i| {
            core.engine_log("SampleSystem working on specific SystemComponent {s} index: {d} handle: {d}, {d}", .{
                component.name,
                i,
                SampleComponent.BaseContainer.handles.items[i].generation,
                SampleComponent.BaseContainer.handles.items[i].index,
            });
        }
    }

    pub fn destroy(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

// dependencies
const std = @import("std");
const core = @import("NeonWood").core;
const ecs = core.ecs;
const EcsSystemInterface = core.EcsSystemInterface;
