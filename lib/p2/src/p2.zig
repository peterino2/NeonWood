// ---- ----
const std = @import("std");
const utils = @import("structures/utils.zig");

const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
pub const assertf = utils.assertf;
pub const asserts = utils.asserts;

pub const static_structures = @import("structures/static-structures.zig");
pub const StaticVector = static_structures.StaticVector;

pub const ring_queue = @import("structures/ring-queue.zig");

pub const RingQueueU = ring_queue.RingQueueU;
pub const RingQueue = ring_queue.RingQueue;

pub const sparse_set = @import("structures/sparse-set.zig");

pub const SparseSet = sparse_set.SparseSet;
pub const SparseMultiSet = sparse_set.SparseMultiSet;
pub const SparseSetAdvanced = sparse_set.SparseSetAdvanced;
pub const SparseMultiSetAdvanced = sparse_set.SparseMultiSetAdvanced;
pub const SetHandle = sparse_set.SetHandle;

pub const stack_structures = @import("structures/stack-structures.zig");

pub const index_pool = @import("structures/index-pool.zig");
pub const IndexPoolHandle = index_pool.Handle;
pub const IndexPool = index_pool.IndexPool;

pub const concurrent_queue = @import("structures/concurrent-queue.zig");
pub const ConcurrentQueueU = concurrent_queue.ConcurrentQueueU;
pub const ConcurrentQueueUnmanagedAdvanced = concurrent_queue.ConcurrentQueueUnmanagedAdvanced;

pub const names = @import("structures/names.zig");

pub const NameInvalid = names.NameInvalid;
pub const Name = names.Name;
pub const MakeName = names.MakeName;
pub const createNameRegistry = names.createNameRegistry;
pub const destroyNameRegistry = names.destroyNameRegistry;

comptime {
    std.testing.refAllDecls(utils);
    std.testing.refAllDecls(static_structures);
    std.testing.refAllDecls(ring_queue);
    std.testing.refAllDecls(sparse_set);
    std.testing.refAllDecls(stack_structures);
    std.testing.refAllDecls(index_pool);
    std.testing.refAllDecls(concurrent_queue);
}

// ---- aliases ----
pub const ObjectHandle = SetHandle;

// ---- tests ----
test "multi-sparse-basic" {
    const allocator = std.testing.allocator;
    const TestStructField = struct {
        x: u32,
    };

    const TestStruct = struct {
        field1: usize,
        structField: TestStructField,
    };

    var testSet = SparseMultiSet(TestStruct).init(allocator);
    defer testSet.deinit();
    const sparseHandle = try testSet.createObject(.{ .field1 = 1, .structField = .{ .x = 12 } });
    const sparseHandle1 = try testSet.createObject(.{ .field1 = 2, .structField = .{ .x = 34 } });
    const sparseHandle2 = try testSet.createObject(.{ .field1 = 3, .structField = .{ .x = 56 } });
    std.debug.print("handle: {any}\n", .{testSet.get(sparseHandle, .field1).?.*});
    std.debug.print("handle1: {any}\n", .{testSet.get(sparseHandle1, .field1).?.*});
    std.debug.print("handle2: {any}\n", .{testSet.get(sparseHandle2, .field1).?.*});
    _ = testSet.destroyObject(sparseHandle);
    std.debug.print("handle1: {any}\n", .{testSet.get(sparseHandle1, .field1).?.*});
    std.debug.print("handle2: {any}\n", .{testSet.get(sparseHandle2, .field1).?.*});
}

// As neonwood is primarily a playground for me to learn and practice programming,
// There will be some implementations of basic data structures. For fun ofc
pub fn AppendToArrayListUnique(list: anytype, value: anytype) !void {
    for (list.items) |v| {
        if (v == value)
            return;
    }

    try list.append(value);
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

    var set = PayloadSet.init(std.testing.allocator);
    defer set.deinit();

    var set2 = PayloadSet.init(std.testing.allocator);
    defer set2.deinit();

    const setHandle = (try set.createAndGet(.{ .name = "object1", .v = 0 })).handle;
    printSetHandle(setHandle);
    const setHandle1 = (try set.createObject(.{ .name = "object2", .v = 1 }));
    printSetHandle(setHandle1);
    const setHandle2 = (try set.createObject(.{ .name = "object3", .v = 2 }));
    printSetHandle(setHandle2);
    const setHandle3 = (try set.createObject(.{ .name = "object4", .v = 3 }));
    printSetHandle(setHandle3);

    const set2Handle1 = (try set2.createWithHandle(setHandle3, set.get(setHandle2).?.*)).handle;
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
