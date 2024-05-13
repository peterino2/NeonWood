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

// a replacement for SparseSet, that's more cache efficent. ( and in many cases results in
// memory savings as well)

pub fn SparseMultiSet(comptime T: type) type {
    return SparseMultiSetAdvanced(T, DefaultSparseSize);
}

// works by converting a datastructure into an AOS type.
pub fn SparseMultiSetAdvanced(comptime T: type, comptime SparseSize: u32) type {
    return struct {
        pub const SetType = std.MultiArrayList(T);

        allocator: std.mem.Allocator,
        denseIndices: ArrayListUnmanaged(SetHandle),
        dense: SetType, // this is an unmanaged collection
        sparse: []SetHandle,

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
    };
}

// A quick little sparse set implementation, this feeds the core of the
// ECS. A sparse set provides Constant time random access to a range of objects through stable handles
// While providing dense memory locality for iterating.
pub fn SparseSetAdvanced(comptime T: type, comptime SparseSize: u32) type {
    return struct {
        allocator: std.mem.Allocator,
        dense: ArrayListUnmanaged(struct {
            value: T,
            sparseIndex: IndexType,
        }),
        sparse: []SetHandle,

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
            std.debug.print("sparseLen: {d}\n", .{self.sparse.len});

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
            std.debug.print("creating set with handle: {any}\n", .{handle});
            var currentDenseHandle = self.sparse[handle.index];
            if (currentDenseHandle.alive) {
                return error.ObjectAlreadyExists;
            }
            currentDenseHandle.generation = handle.generation;
            currentDenseHandle.alive = true;

            return try self.createAndGetInteral(currentDenseHandle, handle.index, initValue, false);
        }

        fn createAndGetInteral(self: *@This(), denseHandle: SetHandle, sparseIndex: IndexType, initValue: T, comptime bumpGeneration: bool) !ConstructResult {
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
    };
}
