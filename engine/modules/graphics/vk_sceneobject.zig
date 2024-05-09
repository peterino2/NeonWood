const std = @import("std");
const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const vk_renderer = @import("vk_renderer.zig");

const NeonVkContext = vk_renderer.NeonVkContext;

// Sceneobject is a subsystem owned by the renderer

// all runs in the predraw phase.

// if a given renderobject has a corresnponding representation in gScene

// the renderobject's final transform will be updated based on the gScene representation

pub const NeonVkSceneManager = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) @This() {
        const self = .{
            .allocator = allocator,
        };

        return self;
    }

    pub fn update(self: *@This(), gc: *NeonVkContext) !void {
        _ = self;
        for (core.gScene.objects.dense.items(._repr), 0..) |_repr, i| {
            const handle = core.gScene.objects.denseIndices.items[i];
            const renderObject = gc.renderObjectSet.get(handle, .renderObject).?;
            renderObject.*.transform = _repr.transform;
        }
    }
};
