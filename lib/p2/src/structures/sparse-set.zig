const std = @import("std");

const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

// can be index by an 18 bit value, and 262144 of anything ought to be enough... right?
pub const DefaultSparseSize = 262144;

pub fn SparseSet(comptime T: type) type {
    return SparseSetAdvanced(T, DefaultSparseSize);
}

pub const IndexType = u24;
pub const GenerationType = u7;

pub const SetHandle = packed struct {
    index: IndexType = 0,
    generation: GenerationType = 0,
    alive: bool = false,

    pub fn hash(self: @This()) u32 {
        return @as(u32, @bitCast(self));
    }
};

pub fn SparseMultiSet(comptime T: type) type {
    return SparseMultiSetAdvanced(T, DefaultSparseSize);
}

pub const ContainerListener = struct {
    ptr: *anyopaque,
    onHandleRemoved: *const fn (*anyopaque, u32, SetHandle) void,
    onHandleAdded: *const fn (*anyopaque, u32, SetHandle) void,
};

// works by converting a datastructure into an AOS type.
pub fn SparseMultiSetAdvanced(comptime T: type, comptime SparseSize: u32) type {
    return struct {
        pub const SetType = std.MultiArrayList(T);

        allocator: std.mem.Allocator,
        denseIndices: ArrayListUnmanaged(SetHandle),
        dense: SetType,
        sparse: []SetHandle,
        containerID: u32 = 0,
        containerListener: ?ContainerListener = null,

        pub const Field = SetType.Field;
        pub const Slice = SetType.Slice;

        pub fn init(allocator: std.mem.Allocator) @This() {
            var self = @This(){
                .allocator = allocator,
                .denseIndices = .{},
                .dense = .{},
                .sparse = allocator.alloc(SetHandle, SparseSize) catch unreachable,
            };

            for (self.sparse, 0..) |_, i| {
                self.sparse[i] = .{ .generation = 0, .index = 0x0, .alive = false };
            }

            return self;
        }

        pub fn denseItems(self: *@This(), comptime field: Field) []FieldType(field) {
            return self.dense.items(field);
        }

        pub fn deinit(self: *@This()) void {
            self.dense.deinit(self.allocator);
            self.denseIndices.deinit(self.allocator);
            self.allocator.free(self.sparse);
        }

        pub fn readDense(self: @This(), offset: usize, comptime field: Field) *const FieldType(field) {
            return &self.dense.items(field)[offset];
        }

        pub fn getDense(self: *@This(), offset: usize, comptime field: Field) *FieldType(field) {
            return &self.dense.items(field)[offset];
        }

        // ----- sparse set features -----

        pub fn handleFromSparseIndex(self: @This(), sparseIndex: IndexType) SetHandle {
            var handle: SetHandle = self.sparse[@as(usize, @intCast(sparseIndex))];
            handle.index = sparseIndex;
            return handle;
        }

        pub fn sparseToDense(self: @This(), handle: SetHandle) ?usize {
            const denseHandle = self.sparse[@as(usize, @intCast(handle.index))];

            // todo: need to update generation
            if (denseHandle.generation != handle.generation) // tombstone value
            {
                // Generation mismatch, this handle is totally dead.
                return null;
            }

            if (denseHandle.alive == false) {
                return null;
            }

            const denseIndex = @as(usize, @intCast(denseHandle.index));

            if (denseIndex >= self.denseIndices.items.len) {
                return null;
            }

            return denseIndex;
        }

        pub fn FieldType(comptime field: Field) type {
            return std.meta.fieldInfo(T, field).type;
        }

        pub fn get(self: *@This(), handle: SetHandle, comptime field: Field) ?*FieldType(field) {
            const denseIndex = self.sparseToDense(handle) orelse return null;
            return &self.dense.items(field)[denseIndex];
        }

        // the idea behind a sparse array is that the sethandle is
        // highly stable.
        // if this container is registered as part of an ECS, this is unsafe to call directly
        pub fn createObject(self: *@This(), initValue: T) !SetHandle {
            var newSparseIndex = newRandomIndex();

            var denseHandle = self.sparse[@as(usize, @intCast(newSparseIndex))];

            while (denseHandle.alive == true) {
                newSparseIndex = newRandomIndex();
                denseHandle = self.sparse[@as(usize, @intCast(newSparseIndex))];
            }
            const generation = (denseHandle.generation + 1) % (std.math.maxInt(GenerationType));

            return self.createObjectInternal(initValue, newSparseIndex, generation);
        }

        pub fn createObjectInternal(self: *@This(), initValue: T, newSparseIndex: IndexType, generation: GenerationType) !SetHandle {
            const newDenseIndex = self.denseIndices.items.len;
            self.sparse[@as(usize, @intCast(newSparseIndex))] = SetHandle{
                .alive = true,
                .generation = @as(GenerationType, @intCast(generation)),
                .index = @as(IndexType, @intCast(newDenseIndex)),
            };

            const setHandle = SetHandle{
                .alive = true,
                .generation = generation,
                .index = newSparseIndex,
            };

            try self.denseIndices.append(self.allocator, setHandle);
            try self.dense.append(self.allocator, initValue);
            std.debug.assert(self.sparse[newSparseIndex].index < self.dense.len);

            if (self.containerListener) |l| {
                l.onHandleAdded(l.ptr, @intCast(self.containerID), setHandle);
            }

            return setHandle;
        }

        pub fn createWithHandle(self: *@This(), handle: SetHandle, initValue: T) !SetHandle {
            // std.debug.print("creating set with handle: {any}\n", .{handle});
            const currentDenseHandle = self.sparse[handle.index];
            if (currentDenseHandle.alive) {
                return error.ObjectAlreadyExists;
            }

            return self.createObjectInternal(initValue, handle.index, handle.generation);
        }

        pub fn destroyObject(self: *@This(), handle: SetHandle) bool {
            // to destroy an object
            // get handle and get the dense position, swap and remove.
            // Then insert the tombstone value into the sparse handle

            // if this fails it means the object is already destroyed
            const denseIndex = self.sparseToDense(handle) orelse return false;

            // get the indec of the last object in the dense set
            const tailDenseIndex = self.dense.len - 1;

            // get the sparse index of the last object
            const sparseIndexToSwap = self.denseIndices.items[tailDenseIndex];

            // redirect the sparse index to the new position of the swapped object.
            self.sparse[@as(usize, @intCast(sparseIndexToSwap.index))].index = @as(IndexType, @intCast(denseIndex));

            // perform the swap and remove, mark the tombstone as well.
            _ = self.dense.swapRemove(denseIndex);
            _ = self.denseIndices.swapRemove(denseIndex);
            self.sparse[@as(usize, @intCast(handle.index))].alive = false;

            if (self.containerListener) |l| {
                l.onHandleRemoved(l.ptr, self.containerID, handle);
            }

            return true;
        }

        var prng = std.rand.DefaultPrng.init(0x1234);
        var rand = prng.random();

        pub fn newRandomIndex() IndexType {
            if (SparseSize == std.math.maxInt(IndexType)) {
                return rand.int(IndexType);
            }

            return rand.int(IndexType) % @as(IndexType, @intCast(SparseSize));
        }

        // ecs interface

        pub const EcsContainerInterfaceVTable = EcsContainerInterface.Implement(@This());

        pub fn handleExists(self: @This(), handle: SetHandle) bool {
            return self.sparseToDense(handle) != null;
        }

        pub fn getContainerID(self: @This()) u32 {
            return self.containerID;
        }

        pub fn onRegister(self: *@This(), id: u32, listener: ContainerListener) void {
            self.containerID = id;
            self.containerListener = listener;
        }

        pub fn evictFromRegistry(self: *@This()) void {
            self.containerListener = null;
        }

        pub const ContainerTypeName = "SparseMultiSet";
    };
}

// A quick little sparse set implementation, this feeds the core of the
// ECS. A sparse set provides Constant time random access to a range of objects through stable handles
// While providing dense memory locality for iterating.
//
// should probably never use this one outside of the base-set for checking entity existence.
pub fn SparseSetAdvanced(comptime T: type, comptime SparseSize: u32) type {
    return struct {
        allocator: std.mem.Allocator,
        dense: ArrayListUnmanaged(struct {
            value: T,
            sparseIndex: IndexType,
        }),
        sparse: []SetHandle,

        containerID: u32 = 0,
        containerListener: ?ContainerListener = null,

        pub fn handleFromSparseIndex(self: @This(), sparseIndex: IndexType) SetHandle {
            var handle: SetHandle = self.sparse[@as(usize, @intCast(sparseIndex))];
            handle.index = sparseIndex;
            return handle;
        }

        pub fn init(allocator: std.mem.Allocator) @This() {
            var self = @This(){
                .allocator = allocator,
                .dense = .{},
                .sparse = allocator.alloc(SetHandle, SparseSize) catch unreachable,
            };

            for (self.sparse, 0..) |_, i| {
                self.sparse[i] = .{ .generation = 0, .index = 0x0, .alive = false };
            }

            return self;
        }

        pub fn readDense(self: @This(), offset: usize) *const T {
            return &self.dense.items[offset].value;
        }

        pub fn getDense(self: *@This(), offset: usize) *T {
            return &self.dense.items[offset].value;
        }

        pub fn sparseToDense(self: @This(), handle: SetHandle) ?usize {
            const denseHandle = self.sparse[@as(usize, @intCast(handle.index))];

            // todo: need to update generation
            if (denseHandle.generation != handle.generation) // tombstone value
            {
                // Generation mismatch, this handle is totally dead.
                return null;
            }

            if (denseHandle.alive == false) {
                return null;
            }

            const denseIndex = @as(usize, @intCast(denseHandle.index));

            if (denseIndex >= self.dense.items.len) {
                return null;
            }

            return denseIndex;
        }

        pub fn get(self: *@This(), handle: SetHandle) ?*T {
            const denseIndex = self.sparseToDense(handle) orelse return null;
            return &self.dense.items[denseIndex].value;
        }

        pub fn destroyObject(self: *@This(), handle: SetHandle) void {
            // to destroy an object
            // get handle and get the dense position, swap and remove.
            // Then insert the tombstone value into the sparse handle
            const denseIndex = self.sparseToDense(handle) orelse return;
            const tailDenseIndex = self.dense.items.len - 1;
            const sparseIndexToSwap = self.dense.items[tailDenseIndex].sparseIndex;

            self.sparse[@as(usize, @intCast(sparseIndexToSwap))].index = @as(IndexType, @intCast(denseIndex));

            _ = self.dense.swapRemove(denseIndex);
            self.sparse[@as(usize, @intCast(handle.index))].alive = false;

            if (self.containerListener) |l| {
                l.onHandleRemoved(l.ptr, self.containerID, handle);
            }
        }

        var prng = std.rand.DefaultPrng.init(0x1234);
        var rand = prng.random();

        fn newRandomIndex() IndexType {
            if (SparseSize == std.math.maxInt(IndexType)) {
                return rand.int(IndexType);
            }

            return rand.int(IndexType) % @as(IndexType, @intCast(SparseSize));
        }

        // the idea behind a sparse array is that the sethandle is
        // highly stable.
        pub fn createObject(self: *@This(), initValue: T) !SetHandle {
            var newSparseIndex = newRandomIndex();

            var denseHandle = self.sparse[@as(usize, @intCast(newSparseIndex))];

            while (denseHandle.alive == true) {
                newSparseIndex = newRandomIndex();
                denseHandle = self.sparse[@as(usize, @intCast(newSparseIndex))];
            }

            const newDenseIndex = self.dense.items.len;
            try self.dense.append(self.allocator, .{
                .value = initValue,
                .sparseIndex = newSparseIndex,
            });

            const generation = (denseHandle.generation + 1) % (std.math.maxInt(GenerationType));

            self.sparse[@as(usize, @intCast(newSparseIndex))] = SetHandle{
                .alive = true,
                .generation = @as(GenerationType, @intCast(generation)),
                .index = @as(IndexType, @intCast(newDenseIndex)),
            };

            const setHandle = SetHandle{
                .alive = true,
                .generation = generation,
                .index = newSparseIndex,
            };

            return setHandle;
        }

        pub const ConstructResult = struct {
            ptr: *T,
            handle: SetHandle,
        };

        // Will fail if the handle already exists.
        pub fn createWithHandle(self: *@This(), handle: SetHandle, initValue: T) !ConstructResult {
            var currentDenseHandle = self.sparse[handle.index];
            if (currentDenseHandle.alive) {
                return error.ObjectAlreadyExists;
            }
            currentDenseHandle.generation = handle.generation;
            currentDenseHandle.alive = true;

            return try self.createAndGetInternal(currentDenseHandle, handle.index, initValue, false);
        }

        fn createAndGetInternal(self: *@This(), denseHandle: SetHandle, sparseIndex: IndexType, initValue: T, comptime bumpGeneration: bool) !ConstructResult {
            const newDenseIndex = self.dense.items.len;
            try self.dense.append(self.allocator, .{
                .value = initValue,
                .sparseIndex = sparseIndex,
            });

            var generation = denseHandle.generation;

            if (bumpGeneration) {
                generation = (generation + 1) % (std.math.maxInt(GenerationType));
            }

            self.sparse[@as(usize, @intCast(sparseIndex))] = SetHandle{
                .alive = true,
                .generation = @as(GenerationType, @intCast(generation)),
                .index = @as(IndexType, @intCast(newDenseIndex)),
            };

            const setHandle = SetHandle{
                .alive = true,
                .generation = generation,
                .index = sparseIndex,
            };

            const rv = ConstructResult{
                .ptr = &self.dense.items[@as(usize, @intCast(newDenseIndex))].value,
                .handle = setHandle,
            };

            if (self.containerListener) |l| {
                l.onHandleAdded(l.ptr, self.containerID, setHandle);
            }

            return rv;
        }

        pub fn createAndGet(self: *@This(), initValue: T) !ConstructResult {
            var newSparseIndex = newRandomIndex();

            var denseHandle = self.sparse[@as(usize, @intCast(newSparseIndex))];

            while (denseHandle.alive == true) {
                newSparseIndex = newRandomIndex();
                denseHandle = self.sparse[@as(usize, @intCast(newSparseIndex))];
            }

            return try self.createAndGetInteral(denseHandle, newSparseIndex, initValue, true);
        }

        pub fn deinit(self: *@This()) void {
            self.allocator.free(self.sparse);
            self.dense.deinit(self.allocator);
        }

        pub const EcsContainerInterfaceVTable = EcsContainerInterface.Implement(@This());

        pub fn handleExists(self: @This(), handle: SetHandle) bool {
            return self.sparseToDense(handle) != null;
        }

        pub fn getContainerID(self: @This()) u32 {
            return self.containerID;
        }

        pub fn onRegister(self: *@This(), id: u32, listener: ContainerListener) void {
            self.containerID = id;
            self.containerListener = listener;
        }

        // might never need to call this one...
        pub fn evictFromRegistry(self: *@This()) void {
            self.containerListener = null;
        }

        pub const ContainerTypeName = "SparseSet";
    };
}

// slowih look-up, fast-ish iteration time,
// very little memory overhead, stable pointers
// good all-around choice if you have a small
// number of these objects around, and the object itself is quite big.
pub fn SparseMap(comptime T: type) type {
    return struct {
        backingAllocator: std.mem.Allocator,
        arena: std.heap.ArenaAllocator,

        map: std.AutoHashMapUnmanaged(SetHandle, *T) = .{},
        listEntriesByHandle: std.AutoHashMapUnmanaged(SetHandle, u32) = .{},
        list: std.ArrayListUnmanaged(*T) = .{},
        containerID: u32 = 0,
        containerListener: ?ContainerListener = null,

        pub fn create(backingAllocator: std.mem.Allocator) !*@This() {
            const self = try backingAllocator.create(@This());

            self.* = .{
                .arena = std.heap.ArenaAllocator.init(backingAllocator),
                .backingAllocator = backingAllocator,
            };

            return self;
        }

        pub fn destroyObject(self: *@This(), handle: SetHandle) void {
            std.debug.assert(!self.map.contains(handle));
            const alloc = self.allocator();
            const index = self.listEntriesByHandle.get(handle).?;
            self.map.get(handle).?.destroy(alloc);

            _ = self.map.remove(alloc, handle);
            _ = self.listEntriesByHandle.remove(alloc, handle);
            _ = self.list.swapRemove(index);
        }

        pub fn createWithHandle(self: *@This(), handle: SetHandle, initValue: T) !*T {
            std.debug.assert(!self.map.contains(handle));
            const alloc = self.allocator();

            const new = try alloc.create(T);
            new.* = initValue;

            try self.map.put(alloc, handle, new);
            try self.list.append(alloc, new);
            try self.listEntriesByHandle.put(alloc, handle, @intCast(self.list.items.len));

            if (self.containerListener) |l| {
                l.onHandleAdded(l.ptr, self.containerID, handle);
            }

            return new;
        }

        pub fn allocator(self: *@This()) std.mem.Allocator {
            return self.arena.allocator();
        }

        pub fn destroy(self: *@This()) void {
            self.arena.deinit();
            self.backingAllocator.destroy(self);
        }

        // == interface below ==

        pub const EcsContainerInterfaceVTable = EcsContainerInterface.Implement(@This());

        pub fn handleExists(self: @This(), handle: SetHandle) bool {
            return self.map.contains(handle);
        }

        pub fn getContainerID(self: @This()) u32 {
            return self.containerID;
        }

        pub fn onRegister(self: *@This(), id: u32, listener: ContainerListener) void {
            self.containerID = id;
            self.containerListener = listener;
        }

        // might never need to call this one...
        pub fn evictFromRegistry(self: *@This()) void {
            self.containerListener = null;
        }

        pub const ContainerTypeName = "SparseMap";
    };
}

// this is quickly becoming the ecs containers file
const interface = @import("interface.zig");

pub const EcsContainerInterface = interface.MakeInterface("EcsContainerInterfaceVTable", struct {
    containerTypeName: []const u8,
    handleExists: *const fn (*const anyopaque, SetHandle) bool,
    getContainerID: *const fn (*const anyopaque) u32,
    onRegister: *const fn (*anyopaque, u32, ContainerListener) void,
    evictFromRegistry: *const fn (*anyopaque) void,

    pub const Reference = struct {
        vtable: *const @This(),
        ptr: *anyopaque,
    };

    pub fn Implement(comptime TargetType: type) @This() {
        const Wrap = struct {
            pub fn handleExists(p: *const anyopaque, handle: SetHandle) bool {
                var ptr = @as(*const TargetType, @ptrCast(@alignCast(p)));
                return ptr.handleExists(handle);
            }

            pub fn getContainerID(p: *const anyopaque) u32 {
                var ptr = @as(*const TargetType, @ptrCast(@alignCast(p)));
                return ptr.getContainerID();
            }

            pub fn onRegister(p: *anyopaque, id: u32, listener: ContainerListener) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(p)));
                return ptr.onRegister(id, listener);
            }

            pub fn evictFromRegistry(p: *anyopaque) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(p)));
                return ptr.evictFromRegistry();
            }
        };

        return .{
            .containerTypeName = TargetType.ContainerTypeName,
            .handleExists = Wrap.handleExists,
            .getContainerID = Wrap.getContainerID,
            .onRegister = Wrap.onRegister,
            .evictFromRegistry = Wrap.evictFromRegistry,
        };
    }
});
