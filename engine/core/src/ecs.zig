var gEcsRegistry: *EcsRegistry = undefined;

pub fn createEntity() !core.ObjectHandle {
    return try gEcsRegistry.baseSet.createObject(.{});
}

pub fn setup(allocator: std.mem.Allocator) !void {
    gEcsRegistry = try EcsRegistry.create(allocator);
}

pub fn shutdown() void {
    gEcsRegistry.destroy();
}

pub fn getRegistry() *EcsRegistry {
    return gEcsRegistry;
}

pub fn registerEcsContainer(ref: EcsContainerRef, name: core.Name) !void {
    try gEcsRegistry.registerContainer(ref, name);
}

// only thing this is meant to do is to provide a central place to construct and destroy objects
pub const EcsRegistry = struct {
    //
    allocator: std.mem.Allocator,
    baseSet: BaseSet,

    containers: std.ArrayListUnmanaged(EcsContainerRef) = .{},
    containerNames: std.ArrayListUnmanaged(core.Name) = .{},
    containersByName: std.AutoHashMapUnmanaged(u32, u32) = .{},

    pub fn create(allocator: std.mem.Allocator) !*@This() {
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
        core.engine_log("ECS:: object removed id={d} from container={s}({d})", .{
            handle.index,
            self.containerNames.items[containerID].utf8(),
            containerID,
        });

        if (self.baseSet.get(handle).?.containersCount > 0) {
            self.baseSet.get(handle).?.containersCount -= 1;
        } else {
            self.baseSet.destroyObject(handle);
        }
    }

    pub fn onHandleAdded(p: *anyopaque, containerID: u32, handle: core.ObjectHandle) void {
        const self: *@This() = @ptrCast(@alignCast(p));
        core.engine_log("ECS:: object added id={d} from container={s}({d})", .{
            handle.index,
            self.containerNames.items[containerID].utf8(),
            containerID,
        });

        if (self.baseSet.get(handle)) |obj| {
            obj.containersCount += 1;
        } else {
            _ = self.baseSet.createWithHandle(handle, .{ .containersCount = 1 }) catch unreachable;
        }
    }

    pub fn destroy(self: *@This()) void {
        for (self.containers.items) |ref| {
            ref.vtable.evictFromRegistry(ref.ptr);
        }
        self.baseSet.deinit();
        self.containers.deinit(self.allocator);
        self.containerNames.deinit(self.allocator);
        self.containersByName.deinit(self.allocator);
        self.allocator.destroy(self);
    }
};

const std = @import("std");
const p2 = @import("p2");
const core = @import("core.zig");

pub const EcsContainerInterface = p2.EcsContainerInterface;
pub const EcsContainerRef = p2.Reference(EcsContainerInterface);
pub fn makeEcsContainerRef(ptr: anytype) EcsContainerRef {
    return p2.refFromPtr(EcsContainerInterface, ptr);
}

pub const EcsEntry = struct {
    containersCount: u32 = 0,
};

pub const BaseSet = p2.SparseSet(EcsEntry);
