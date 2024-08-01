const std = @import("std");
const core = @import("core");
const graphics = @import("graphics.zig");
const ecs = core.ecs;

const render_objects = @import("render_objects.zig");

const CameraContainer = core.SparseMap(render_objects.Camera);

// just a container for holding the graphics ecs systems
const GraphicsEcs = struct {
    allocator: std.mem.Allocator,
    cameras: *CameraContainer,
};

var gEcs: GraphicsEcs = undefined;

pub fn registerEcs(allocator: std.mem.Allocator) !void {
    _ = allocator;
    // const container = core.makeEcsContainerRef(&graphics.getContext().renderObjectSet);
    //
    // try core.registerEcsContainer(container, core.MakeName("RenderObjects"));

    // gEcs.allocator = allocator;
    // gEcs.cameras = try CameraContainer.create(allocator);

    // try core.registerEcsContainer(core.makeEcsContainerRef(gEcs.cameras), core.MakeName("Cameras"));
    // const setHandle = try core.createEntity();
    // _ = try gEcs.cameras.createWithHandle(setHandle, graphics.Camera.init());
    // gEcs.cameras.destroyObject(setHandle);
}

pub fn shutdownEcs() void {
    gEcs.cameras.destroy();
}

test "samplecode" {
    // primary key for components is the address of the ecs Vtable

    ecs.addComponent(graphics.Camera); // initializes the component container
    ecs.destroyComponent(graphics.Camera); // de-initializes the component container
    ecs.getContainer(graphics.Camera); // gets direct access to the underlying container

    const myObject = core.createEntity();
    const camera = try core.addComponent(myObject, graphics.Camera, .{});
    _ = camera;
}
