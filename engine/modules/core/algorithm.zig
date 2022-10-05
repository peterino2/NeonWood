// ---- ----
const std = @import("std");

const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

// As neonwood is primarily a playground for me to learn and practice programming,
// There will be some implementations of basic data structures. For fun ofc
pub fn AppendToArrayListUnique(list: anytype, value: anytype) !void {
    for (list.items) |v| {
        if (v == value)
            return;
    }

    try list.append(value);
}

// can be index by an 18 bit value, and 262144 of anything ought to be enough... right?
pub const DefaultSparseSize = 262144;

pub fn SparseSet(comptime T: type) type {
    return SparseSetAdvanced(T, DefaultSparseSize);
}

pub const ObjectHandle = SetHandle;

pub const SetHandle = packed struct {
    alive: bool,
    generation: u11,
    padding: u2 = 0,
    index: u18,

    pub fn hash(self: @This()) u32
    {
        return @bitCast(u32, self);
    }
};

// A quick little sparse set implementation, this feeds the core of the 
// ECS. A sparse set provides Constant time random access to a range of objects through stable handles
// While providing dense memory locality for iterating.
pub fn SparseSetAdvanced(comptime T: type, comptime SparseSize: u32) type {
    return struct {
        allocator: std.mem.Allocator,
        dense: ArrayListUnmanaged(struct {
            value: T,
            sparseIndex: u18,
        }),
        sparse: []SetHandle,

        pub fn init(allocator: std.mem.Allocator) @This() {
            var self = @This(){
                .allocator = allocator,
                .dense = .{},
                .sparse = allocator.alloc(SetHandle, SparseSize) catch unreachable,
            };
            std.debug.print("sparseLen: {d}\n", .{self.sparse.len});

            for (self.sparse) |_, i| {
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

        fn sparseToDense(self: @This(), handle: SetHandle) ?usize {
            const denseHandle = self.sparse[@intCast(usize, handle.index)];

            if (denseHandle.generation != handle.generation) // tombstone value
            {
                std.debug.print("ECS issue: generation mismatch, sparse: {any} dense: {any}\n", .{ handle, denseHandle });
                // Generation mismatch, this handle is totally dead.
                return null;
            }

            if (denseHandle.alive == false) {
                std.debug.print("ECS issue: dense handle is dead, sparse: {any} dense: {any}\n", .{ handle, denseHandle });
                return null;
            }

            const denseIndex = @intCast(usize, denseHandle.index);

            if (denseIndex >= self.dense.items.len) {
                std.debug.print("ECS issue: dense index is invalid, sparse: {any} dense: {any}\n", .{ handle, denseHandle });
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

            self.sparse[@intCast(usize, sparseIndexToSwap)].index = @intCast(u18, denseIndex);

            _ = self.dense.swapRemove(denseIndex);
            self.sparse[@intCast(usize, handle.index)].alive = false;
        }

        var prng = std.rand.DefaultPrng.init(0x1234);
        var rand = prng.random();

        fn newRandomIndex() u18 {
            if (SparseSize == DefaultSparseSize) {
                return rand.int(u18);
            }

            return rand.int(u18) % @intCast(u18, SparseSize);
        }

        // the idea behind a sparse array is that the sethandle is
        // highly stable.
        pub fn createObject(self: *@This(), initValue: T) !SetHandle {
            var newSparseIndex = newRandomIndex();

            var denseHandle = self.sparse[@intCast(usize, newSparseIndex)];

            while (denseHandle.alive == true) {
                newSparseIndex = newRandomIndex();
                denseHandle = self.sparse[@intCast(usize, newSparseIndex)];
            }

            var newDenseIndex = self.dense.items.len;
            try self.dense.append(self.allocator, .{
                .value = initValue,
                .sparseIndex = newSparseIndex,
            });

            const generation = (denseHandle.generation + 1) % (0xff);

            self.sparse[@intCast(usize, newSparseIndex)] = SetHandle{
                .alive = true,
                .generation = @intCast(u11, generation),
                .index = @intCast(u18, newDenseIndex),
            };

            var setHandle = SetHandle{
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
        pub fn createWithHandle(self: *@This(), handle:SetHandle, initValue: T) !ConstructResult
        {
            var currentDenseHandle = self.sparse[handle.index];
            if(currentDenseHandle.alive)
            {
                return error.ObjectAlreadyExists;
            }
            
            return try self.createAndGetInteral(currentDenseHandle, handle.index, initValue, false);
        }

        fn createAndGetInteral(self: *@This(), denseHandle: SetHandle, sparseIndex: u18, initValue: T, comptime bumpGeneration: bool) !ConstructResult
        {
            var newDenseIndex = self.dense.items.len;
            try self.dense.append(self.allocator, .{
                .value = initValue,
                .sparseIndex = sparseIndex,
            });


            var generation = denseHandle.generation;

            if(bumpGeneration)
            {
                generation = (generation + 1) % (0xff);
            }

            self.sparse[@intCast(usize, sparseIndex)] = SetHandle{
                .alive = true,
                .generation = @intCast(u11, generation),
                .index = @intCast(u18, newDenseIndex),
            };

            var setHandle = SetHandle{
                .alive = true,
                .generation = generation,
                .index = sparseIndex,
            };

            const rv = ConstructResult{
                .ptr = &self.dense.items[@intCast(usize, newDenseIndex)].value,
                .handle = setHandle,
            };

            return rv;
        }

        pub fn createAndGet(self: *@This(), initValue: T) !ConstructResult {
            var newSparseIndex = newRandomIndex();

            var denseHandle = self.sparse[@intCast(usize, newSparseIndex)];

            while (denseHandle.alive == true) {
                newSparseIndex = newRandomIndex();
                denseHandle = self.sparse[@intCast(usize, newSparseIndex)];
            }

            return try self.createAndGetInteral(denseHandle, newSparseIndex, initValue, true);
        }

        pub fn deinit(self: *@This()) void {
            self.allocator.free(self.sparse);
            self.dense.deinit(self.allocator);
        }
    };
}

fn printSetHandle(s: SetHandle) void {
    std.debug.print("{any}\n", .{s});
}

test "sparse-set" {
    std.debug.print("\n", .{});
    const Payload = struct {
        name: []const u8,
        v: u32,
    };

    const PayloadSet = SparseSet(Payload);
    const expect = std.testing.expect;
    _ = expect;

    var set = PayloadSet.init(std.testing.allocator);
    defer set.deinit();

    var set2 = PayloadSet.init(std.testing.allocator);
    defer set2.deinit();

    var setHandle = (try set.createAndGet(.{ .name = "object1", .v = 0 })).handle;
    printSetHandle(setHandle);
    var setHandle1 = (try set.createObject(.{ .name = "object2", .v = 1 }));
    printSetHandle(setHandle1);
    var setHandle2 = (try set.createObject(.{ .name = "object3", .v = 2 }));
    printSetHandle(setHandle2);
    var setHandle3 = (try set.createObject(.{ .name = "object4", .v = 3 }));
    printSetHandle(setHandle3);

    var set2Handle1 = (try set2.createWithHandle(setHandle3, set.get(setHandle2).?.*)).handle;
    std.debug.print("set2 handle: \n", .{});
    printSetHandle(set2Handle1);

    for (set.dense.items) |entry| {
        std.debug.print("{any}: {s}\n", .{ entry.value, entry.value.name });
    }

    std.debug.print("\ndestroying handle\n", .{});
    set.destroyObject(setHandle);
    for (set.dense.items) |entry| {
        std.debug.print("{any}: {s}\n", .{ entry.value, entry.value.name });
    }
    try expect(set.get(setHandle) == null);
    try expect(set.get(setHandle1).?.v == 1);
    try expect(set.get(setHandle2).?.v == 2);
    try expect(set.get(setHandle3).?.v == 3);

    std.debug.print("\ndestroying handle\n", .{});
    set.destroyObject(setHandle1);
    for (set.dense.items) |entry| {
        std.debug.print("{any}: {s}\n", .{ entry.value, entry.value.name });
    }
    try expect(set.get(setHandle) == null);
    try expect(set.get(setHandle1) == null);
    try expect(set.get(setHandle2).?.v == 2);
    try expect(set.get(setHandle3).?.v == 3);

    std.debug.print("\ndestroying handle\n", .{});
    set.destroyObject(setHandle2);
    for (set.dense.items) |entry| {
        std.debug.print("{any}: {s}\n", .{ entry.value, entry.value.name });
    }

    try expect(set.get(setHandle) == null);
    try expect(set.get(setHandle1) == null);
    try expect(set.get(setHandle3).?.v == 3);
    try expect(set.get(setHandle2) == null);

    std.debug.print("\ndestroying handle\n", .{});
    set.destroyObject(setHandle3);
    for (set.dense.items) |entry| {
        std.debug.print("{any}: {s}\n", .{ entry.value, entry.value.name });
    }

    try expect(set.get(setHandle) == null);
    try expect(set.get(setHandle1) == null);
    try expect(set.get(setHandle2) == null);
    try expect(set.get(setHandle3) == null);

    try expect(set.dense.items.len == 0);
}

const RingQueueError = error{
    QueueIsFull,
    QueueIsEmpty,
    AllocSizeTooSmall,
};

// tail points to next free
// head points to next one to read
pub fn RingQueueU(comptime T: type) type {
    return struct {
        buffer: []T = undefined,
        head: usize = 0, // not stable across resizes
        tail: usize = 0, // not stable across resizes

        pub fn init(allocator: std.mem.Allocator, size: usize) !@This() {
            var self = @This(){
                .buffer = try allocator.alloc(T, size + 1),
            };

            return self;
        }

        pub fn push(self: *@This(), value: T) RingQueueError!void {
            _ = self;
            _ = value;

            const next = (self.tail + 1) % self.buffer.len;

            if (next == self.head) {
                return error.QueueIsFull;
            }
            self.buffer[self.tail] = value;
            self.tail = next;
        }

        pub fn pushFront(self: *@This(), value: T) !void {
            var iHead = @intCast(isize, self.head) - 1;

            if (iHead < 0) {
                iHead = @intCast(isize, self.buffer.len) + iHead;
            }

            if (iHead == @intCast(isize, self.tail)) {
                return error.QueueIsFull;
            }

            self.head = @intCast(usize, iHead);
            self.buffer[self.head] = value;
        }

        pub fn count(self: @This()) usize {
            if (self.head == self.tail)
                return 0;

            if (self.head < self.tail)
                return self.tail - self.head;

            // head > tail means we looped around.
            return (self.buffer.len - self.head) + self.tail;
        }

        pub fn pop(self: *@This()) ?T {
            if (self.head == self.tail)
                return null;

            var r = self.buffer[self.head];
            self.head = ((self.head + 1) % self.buffer.len);

            return r;
        }

        pub fn peek(self: *@This()) ?*T {
            return self.at(0);
        }

        pub fn peekBack(self: @This()) ?*T {
            return self.atBack(1);
        }

        // reference an element at an offset from the back of the queue
        // similar to python's negative number syntax.
        // gets you an element at an offset from the tail.
        // given the way the tail works, this will return null on zero
        pub fn atBack(self: @This(), offset: usize) ?*T {
            const c = self.count();

            if (offset > c or offset == 0) {
                return null;
            }

            var x: isize = @intCast(isize, self.tail) - @intCast(isize, offset);

            if (x < 0) {
                x = @intCast(isize, self.buffer.len) + x;
            }

            return &self.buffer[@intCast(usize, x)];
        }

        pub fn at(self: *@This(), offset: usize) ?*T {
            _ = self;
            _ = offset;

            const c = self.count();

            if (c == 0) {
                return null;
            }

            if (offset >= c) {
                return null;
            }

            var index = (self.head + offset) % self.buffer.len;

            return &self.buffer[index];
        }

        // returns the number of elements this buffer can hold.
        // you should rarely ever need to use this.
        pub fn capacity(self: *@This()) usize {
            return self.buffer.len - 1;
        }

        pub fn resize(self: *@This(), allocator: std.mem.Allocator, size: usize) !void {
            _ = self;
            _ = allocator;
            _ = size;

            const c = self.count();

            // size needs to be greater by 1, tail always points to an empty
            if (c >= size) {
                return error.AllocSizeTooSmall;
            }

            var buffer: []T = try allocator.alloc(T, size + 1);
            var index: usize = 0;

            while (self.pop()) |v| {
                buffer[index] = v;
                index += 1;
            }

            allocator.free(self.buffer);

            self.buffer = buffer;
            self.head = 0;
            self.tail = index;
        }

        pub fn isEmpty(self: @This()) bool {
            return self.head == self.tail;
        }

        pub fn empty(self: *@This()) void {
            self.head = 0;
            self.tail = 0;
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.buffer);
        }
    };
}

test "ringBuffer" {
    std.debug.print("\nbuffer test: filling a ring buffer\n", .{});

    const allocator = std.testing.allocator;
    var b = try RingQueueU(u32).init(allocator, 4);
    defer b.deinit(allocator);

    const expect = std.testing.expect;

    try b.push(1);
    std.debug.print("head={d} tail={d}\n", .{ b.head, b.tail });
    try b.push(2);
    std.debug.print("head={d} tail={d}\n", .{ b.head, b.tail });
    try b.push(3);
    std.debug.print("head={d} tail={d}\n", .{ b.head, b.tail });
    try expect(b.count() == 3);

    std.debug.print("popping: {d}\n", .{b.pop().?});
    std.debug.print("head={d} tail={d}\n", .{ b.head, b.tail });
    try expect(b.count() == 2);
    std.debug.print("popping: {d}\n", .{b.pop().?});
    try expect(b.count() == 1);
    std.debug.print("head={d} tail={d}\n", .{ b.head, b.tail });
    std.debug.print("popping: {d}\n", .{b.pop().?});
    try expect(b.count() == 0);
    try expect(b.pop() == null);
    std.debug.print("head={d} tail={d}\n", .{ b.head, b.tail });
    try std.testing.expect(b.head == b.tail);
    try std.testing.expect(b.isEmpty());

    try b.push(11);
    std.debug.print("head={d} tail={d} count={d} len={d}\n", .{ b.head, b.tail, b.count(), b.buffer.len });
    try expect(b.count() == 1);
    try b.push(12);
    std.debug.print("head={d} tail={d} count={d} len={d}\n", .{ b.head, b.tail, b.count(), b.buffer.len });
    try expect(b.count() == 2);
    try b.push(13);
    std.debug.print("head={d} tail={d} count={d} len={d}\n", .{ b.head, b.tail, b.count(), b.buffer.len });
    try expect(b.count() == 3);
    try b.push(14);
    std.debug.print("head={d} tail={d} count={d} len={d}\n", .{ b.head, b.tail, b.count(), b.buffer.len });

    try expect(b.head == 3);
    try expect(b.count() == 4);
    try expect(b.tail == ((b.head + 4) % b.buffer.len));

    try expect(b.at(0).? == b.peek().?);

    const newSize = b.buffer.len * 4;
    try b.resize(allocator, newSize); // grow that shit, expect the new size to be size + 1
    try expect(b.capacity() == newSize);
    try expect(b.buffer.len == newSize + 1);

    var errorHit: bool = false;
    b.resize(allocator, 2) catch |e| {
        errorHit = true;
        try expect(e == error.AllocSizeTooSmall);
        std.debug.print("{any}\n", .{e});
    };

    try expect(errorHit);
    try expect(b.peekBack().?.* == 14);
    try expect(b.atBack(1).?.* == 14);
    try expect(b.atBack(2).?.* == 13);
    try expect(b.atBack(3).?.* == 12);
    try expect(b.atBack(4).?.* == 11);

    try b.pushFront(44);

    try expect(b.count() == 5);
    try expect(b.peek().?.* == 44);
}
