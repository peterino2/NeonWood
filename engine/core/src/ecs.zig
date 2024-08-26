var gEcsRegistry: *EcsRegistry = undefined;

pub fn createEntity() !Entity {
    return .{ .handle = try gEcsRegistry.baseSet.createObject(.{}) };
}

pub fn CreateEntity_Lua(state: lua.LuaState) i32 {
    const ud = state.newUserdata(Entity) catch return 0;
    ud.* = createEntity() catch return 0;
    core.engine_log("Entity created: {d}", .{ud.handle.index});
    return 1;
}

pub fn setup(allocator: std.mem.Allocator) !void {
    _ = allocator;
    gEcsRegistry = try core.createObject(EcsRegistry, .{ .can_tick = true });
}

pub fn shutdown() void {}

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
        core.engine_log("ECS:: object added id={d} from container={s}({d}) 0x{x}", .{
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

    try script.addComponentRegistration(@ptrCast(Component.ComponentName), container);

    const ReferenceType = ComponentRef.ComponentReferenceType(Component);
    try ReferenceType.registerType(script.getState());
}

pub fn undefineComponent(comptime Component: type) void {
    Component.BaseContainer.destroy();
}

pub const Entity = struct {
    handle: core.ObjectHandle,

    pub const PodDataTable: pod.DataTable = .{
        .name = "Entity",
        .luaFuncs = &.{"luaCAddComponent"},
        .newFuncOverride = lua.CWrap(CreateEntity_Lua),
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

    pub const luaCAddComponent = lua.CWrap(luaAddComponent);
    pub fn luaAddComponent(state: lua.LuaState) i32 {
        const argc = state.getTop();

        if (argc != 2) {
            core.engine_logs("Add Component Error");
            return 0;
        }

        if (state.toUserdata(@This(), 1)) |self| {
            _ = self;
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

const ComponentRef = @import("script/ComponentRef.zig");
const script = @import("script.zig");
const std = @import("std");
const p2 = @import("p2");
const core = @import("core.zig");
const lua = @import("lua");
const pod = lua.pod;
