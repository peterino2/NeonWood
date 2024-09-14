var gEcsRegistry: *EcsRegistry = undefined;

// wew lad. this is definitely an exploratory implementation I think.
//
// todo: cruft
//  - componentregistration.zig should contain all the code having to do with lua registration
//  - entities should be under ecs/Entities.zig
//
// ECS: Entities, Containers, Systems
//
//  So this is going to be a bit different thatn flecs or other more mainstream systems. You should think of
//  this ecs system as more of a way to implement systems which can talk to each other on a level playing ground.
//
//  My world view of how game systems should talk to each other is more like small processes, and the game state
//  should be a collection of tiny databases that each contain discrete bits of information that piece together
//  to produce a coherent vision of the world.
//
//  Everything that should be tracked through ECS should be something that is gameplay significant.
//  To this end, ecs has a maximum entity count of 1 million unique entities.
//
//  This should be decent enough to pretty much implement 99% of features in th ecs features.
//
//  However features which require a large amount of entities is likely a bad idea and not something that
//  should be done in ecs.
//
//  Eg. you wouldn't do a particle system in ecs and have each transform be a unique entry in the transforms
//  sparse set.
//
//  But you could conceivably do projectiles.
//
//  Overall though you need to ask yourself. If something needs to be an entity or not. entities exist to
//  recieve messages. Not nessecarily even send messages.
//
// The base implementation ideas are mostly solid but the level of cruft involed in scripting and ecs is a bit
// nasty at this time bear with me.
//
// Ok one mental model I think I can with entities is that each entity can be thought of as an independent object
// that contains no state.
//
// When it needs to actually do something, it gets added to a container and one or more systems now have a way
// to address the entity.
//
// systems that would be present for a character in a first person shooter for example
//
//  --- game systems --- ones that the game would write and implement
//
//  ( one or none of these three )
//  player: recieves input messages from local input, forwards it to controller
//  netplayer: recieves input messages from the network driver, forwards it to controller
//  botplayer: generates control messages which drive bots and gameplay AI. forwards it to an controller
//      - could use a behaviour tree under the hood
//  arms: takes input actions and runs scripts to implement things that would be in front of the camera.
//      - arms, weapons, etc...
//  controller: converts raw player input to movement input for the character movement and other subsystems
//      - eg. converts input axis to a vector movement
//      - converts 'mouse_click_1' to a weapon fire call on the weapon component
//      - also converts actions from the botplayer component which may send special components
//  character: stores general gameplay relevant information about a given character.
//      - gameplay stuff, updates values on the character_movement etc.. controls states, such as ragdolling
//  character_movement: reconciles physics component data and movement coming in from controls
//
//  --- engine systems --- ones that would come with the engine
//  camera: Can be set as active. has a global state which tracks which camera is active
//  physics: integration with the physics engine.
//  animationGraph: animation graph drives skeletons inside the rendering_component
//  renderScene: contains a list of subobjects which describe the visual-only scene for this character
//      - renderScene will be the most complex one, lighter weight variants will include
//      - staticMesh
//  transform: final position of the character
//  netAddress: acts as an endpoint to recieve network messages to this specific entity
//
//  --- another thought experiment ----
//  systems present in a mazing tower defense that is networked.
//
//  game:
//      mobs:
//          mr/mazing:
//              I think just this one system can handle the whole damn thing for enemies
//              has a reference to the pathfinder entity. Which finds the best path for each enemy type to reach the
//              main tower.
//          mr/attributes:
//              lightweight attributes which includes a buff/debuff system internally
//          mr/pathfinder (singleton:):
//              system which calls the pathfinding system to generate path segments for each of the segments of the map.
//              can be queried based on position to tell the entity where to go next. includes an internal set of waypoints
//
//  engine: systems that come with the engine
//      p3/: peter's gameplay implementation toolbox.
//          p3/grid_pathfinding: A* based pathfinding system, can create multiple grids and stitch them together.
//
// this is the kind of workflows I want to enable with ecs.
//
// - creating entities and associating that entity with any arbitrary number of systems
// - entities
//
// entities are globally unique ID handles. when you create an entity. you do so by basically asking
// the core system what set handle is free. this also adds that entity to the central registry
// which tracks stuff like if the object is completely free'd or not
//
// components which are a part of an entity are nothing more than an entry in another data structure called a container
// Any data structure can be used but the main data structures that are available for this purpose are all in
// p2/sparse-set.zig
//
//      A few notes about this:
//      Any data structure can be used as container storage it just needs a wrapper and implement
//      the EcsContainerInterface found in sparse-set.zig
//
// current containers are:
//
//      SparseMap (general purpose default, good enough for pretty much everything)
//      SparseSet (only used for systsems where every entry gets iterated over every single frame)
//      SparseMultiSet (AOS version of sparseSet Really specialized, only used for core engine systems)

pub fn createEntity() !Entity {
    return .{ .handle = try gEcsRegistry.baseSet.createObject(.{}) };
}

pub fn CreateEntity_Lua(state: lua.LuaState) i32 {
    const ud = state.newZigUserdata(Entity) catch return 0;
    ud.* = createEntity() catch return 0;
    core.engine_log("Entity created: 0x{x}", .{ud.handle.index});
    return 1;
}

pub fn setup(allocator: std.mem.Allocator) !void {
    try ComponentRef.setupFormatBuffer(allocator);
    gEcsRegistry = try core.createObject(EcsRegistry, .{ .can_tick = true });
}

pub fn shutdown() void {
    ComponentRef.shutdownFormatBuffer();
}

pub fn getRegistry() *EcsRegistry {
    return gEcsRegistry;
}

pub fn registerEcsContainer(ref: EcsContainerRef, name: core.Name) !void {
    try gEcsRegistry.registerContainer(ref, name);
}

pub fn deregisterEcsContainer(ref: EcsContainerRef) void {
    _ = ref;
    @panic("not yet implemented");
}

pub fn createSystem(comptime System: type, allocator: std.mem.Allocator) !*System {
    const system = try System.create(allocator);
    const ref = p2.refFromPtr(EcsSystemInterface, system);
    core.engine_log("ptr = {any}", .{ref.vtable.tick});

    try gEcsRegistry.systems.append(gEcsRegistry.allocator, ref);
    if (ref.vtable.tick != null) {
        try gEcsRegistry.tickableSystems.append(gEcsRegistry.allocator, ref);
    }

    return system;
}

// only thing this is meant to do is to provide a central place to construct and destroy objects
pub const EcsRegistry = struct {
    allocator: std.mem.Allocator,
    baseSet: BaseSet,

    systems: std.ArrayListUnmanaged(EcsSystemRef) = .{},
    tickableSystems: std.ArrayListUnmanaged(EcsSystemRef) = .{},

    containers: std.ArrayListUnmanaged(EcsContainerRef) = .{},
    containerNames: std.ArrayListUnmanaged(core.Name) = .{},
    containersByName: std.AutoHashMapUnmanaged(u32, u32) = .{},

    pub const NeonObjectTable = core.EngineObjectVTable.from(@This());

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .allocator = allocator,
            .baseSet = BaseSet.init(allocator),
        };

        return self;
    }

    pub fn registerContainer(self: *@This(), ref: EcsContainerRef, containerName: core.Name) !void {
        const newid = self.containers.items.len;

        try self.containers.append(self.allocator, ref);
        try self.containerNames.append(self.allocator, containerName);
        try self.containersByName.put(self.allocator, containerName.handle(), @intCast(newid));

        ref.vtable.onRegister(ref.ptr, @intCast(newid), .{
            .ptr = @ptrCast(self),
            .onHandleRemoved = onHandleRemoved,
            .onHandleAdded = onHandleAdded,
        });
    }

    pub fn onHandleRemoved(p: *anyopaque, containerID: u32, handle: core.ObjectHandle) void {
        const self: *@This() = @ptrCast(@alignCast(p));
        core.engine_log("ECS:: object removed id={d} from container={s}({d}) 0x{x}", .{
            handle.index,
            self.containerNames.items[containerID].utf8(),
            containerID,
            @intFromPtr(self.containers.items[containerID].ptr),
        });

        self.baseSet.get(handle).?.containersCount -= 1;
    }

    pub fn onHandleAdded(p: *anyopaque, containerID: u32, handle: core.ObjectHandle) void {
        const self: *@This() = @ptrCast(@alignCast(p));
        core.engine_log("ECS:: object added id=0x{x} from container={s}({d}) 0x{x}", .{
            handle.index,
            self.containerNames.items[containerID].utf8(),
            containerID,
            @intFromPtr(self.containers.items[containerID].ptr),
        });

        if (self.baseSet.get(handle)) |obj| {
            obj.containersCount += 1;
        } else {
            _ = self.baseSet.createWithHandle(handle, .{ .containersCount = 1 }) catch unreachable;
        }
    }

    pub fn tick(self: *@This(), deltaTime: f64) void {
        if (core.getEngine().isShuttingDown())
            return;
        for (self.tickableSystems.items) |ref| {
            ref.vtable.tick.?(ref.ptr, deltaTime);
        }
    }

    pub fn deinit(self: *@This()) void {
        self.destroy();
    }

    pub fn destroy(self: *@This()) void {
        for (self.containers.items) |ref| {
            ref.vtable.evictFromRegistry(ref.ptr);
        }
        for (self.systems.items) |ref| {
            ref.vtable.destroy(ref.ptr);
        }
        self.systems.deinit(self.allocator);
        self.tickableSystems.deinit(self.allocator);
        self.baseSet.deinit();
        self.containers.deinit(self.allocator);
        self.containerNames.deinit(self.allocator);
        self.containersByName.deinit(self.allocator);
        self.allocator.destroy(self);
    }
};

pub fn defineComponent(comptime Component: type, allocator: std.mem.Allocator) !void {
    const ContainerType = @TypeOf(Component.BaseContainer.*);
    Component.BaseContainer = try ContainerType.create(allocator);

    core.engine_log("Component container created " ++ @typeName(Component) ++ "  @{x}", .{@intFromPtr(Component.BaseContainer)});
    const container = makeEcsContainerRef(Component.BaseContainer);
    try registerEcsContainer(container, core.MakeName(@typeName(Component)));

    try script.registerComponent(Component, container);
}

pub fn undefineComponent(comptime Component: type) void {
    Component.BaseContainer.destroy();
}

pub const Entity = struct {
    handle: core.ObjectHandle,

    pub const PodDataTable: pod.DataTable = .{
        .name = "Entity",
        .newFuncOverride = lua.CWrap(CreateEntity_Lua),
        .luaDirectFuncs = &.{
            .{ .name = "addComponent", .func = "luaAddComponent" },
        },
    };

    pub fn addComponent(self: @This(), comptime Component: type) ?*Component {
        return Component.BaseContainer.createWithHandle(self.handle, .{}) catch return null;
    }

    pub fn get(self: @This(), comptime Component: type) ?*Component {
        return Component.BaseContainer.get(self.handle);
    }

    pub fn removeComponent(self: @This(), comptime Component: type) void {
        Component.BaseContainer.remove(self.handle);
    }

    pub fn luaAddComponent(state: lua.LuaState) i32 {
        const argc = state.getTop();

        if (argc != 2) {
            core.engine_log("Add Component Error, expected 2 arguments got {d}", .{argc});
            return 0;
        }

        if (state.toUserdata(@This(), 1)) |self| {
            if (state.toUserdata(ComponentRegistration, 2)) |componentRegistration| {
                // core.engine_log("component Registration: name: {s}", .{componentRegistration.name});

                // create the zig version of the component
                const comp = componentRegistration.createComponent(self.handle);

                // call luaNew on ComponentReferenceType
                // create the lua binding for the component
                // this pushes one onto the stack
                componentRegistration.luaNew(state, self.handle, comp);
            }
        }

        return 1;
    }
};

pub const EcsComponentInterface = p2.MakeInterface("EcsComponentInterfaceVTable", struct {
    container: ?EcsContainerRef = null,

    pub fn Implement(comptime T: type) @This() {
        _ = T;
        const Impl = struct {};
        _ = Impl;

        return .{};
    }
});

pub const EcsContainerInterface = p2.EcsContainerInterface;
pub const EcsContainerRef = p2.Reference(EcsContainerInterface);
pub fn makeEcsContainerRef(ptr: anytype) EcsContainerRef {
    return p2.refFromPtr(EcsContainerInterface, ptr);
}

pub fn getTypeContainer(comptime T: type) EcsContainerRef {
    return makeEcsContainerRef(T.BaseContainer);
}

pub const EcsEntry = struct {
    containersCount: u32 = 0,
};

pub const BaseSet = p2.SparseSet(EcsEntry);

pub const EcsSystemRef = p2.Reference(EcsSystemInterface);
pub const EcsSystemInterface = p2.MakeInterface("EcsSystemVTable", struct {
    create: *const fn (std.mem.Allocator) core.EngineDataEventError!*anyopaque,
    destroy: *const fn (*anyopaque) void,
    tick: ?*const fn (*anyopaque, f64) void = null,

    pub fn Implement(comptime TargetType: type) @This() {
        const Wrap = struct {
            pub fn create(allocator: std.mem.Allocator) core.EngineDataEventError!*anyopaque {
                const new = try TargetType.create(allocator);
                return new;
            }

            pub fn destroy(p: *anyopaque) void {
                const ptr: *TargetType = @ptrCast(@alignCast(p));
                ptr.destroy();
            }

            pub fn tick(p: *anyopaque, dt: f64) void {
                const ptr: *TargetType = @ptrCast(@alignCast(p));
                ptr.tick(dt);
            }
        };
        return .{
            .destroy = Wrap.destroy,
            .create = Wrap.create,
            .tick = if (@hasDecl(TargetType, "tick")) Wrap.tick else null,
        };
    }
});

const ComponentRegistration = @import("script/ComponentRegistration.zig");
const ComponentRef = @import("script/ComponentRef.zig");
const script = @import("script.zig");
const std = @import("std");
const p2 = @import("p2");
const core = @import("core.zig");
const lua = @import("lua");
const pod = lua.pod;
const scene = @import("scene.zig");
