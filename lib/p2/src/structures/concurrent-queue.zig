const std = @import("std");
const utils = @import("utils.zig");

const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const asserts = utils.asserts;

const Atomic = std.atomic.Value;

pub const ConcurrentQueueError = error{
    CorruptedState,
    QueueIsEmpty,
    QueueIsFull,
};

pub fn ConcurrentQueueU(comptime T: type) type {
    return ConcurrentQueueUnmanagedAdvanced(T, .{});
}

pub fn ConcurrentQueueNoAssert(comptime T: type) type {
    return ConcurrentQueueUnmanagedAdvanced(T, .{ .allowAsserts = false });
}

// lock-free concurrent queue, fixed capacity,
// will never resize.
pub fn ConcurrentQueueUnmanagedAdvanced(comptime T: type, comptime opts: struct {
    allowAsserts: bool = true,
}) type {
    return struct {
        data: []T,
        status: []Atomic(bool), // 1 = valid, 0 = invalid,
        head: Atomic(usize),
        tail: Atomic(usize),

        // tail points to next free slot
        // head points to the next one to pop
        pub fn initCapacity(allocator: std.mem.Allocator, cap: usize) !@This() {
            const new = .{
                .data = try allocator.alloc(T, cap + 1),
                .status = try allocator.alloc(Atomic(bool), cap + 1),
                .head = Atomic(usize).init(0),
                .tail = Atomic(usize).init(1),
            };

            for (new.status) |*s| {
                s.* = Atomic(bool).init(false);
            }

            return new;
        }

        pub fn push(self: *@This(), value: T) !void {
            // seek the next unread bit and reserve it
            const start: usize = self.tail.load(.acquire);
            var writeIndex: usize = start;
            while (self.status[writeIndex].cmpxchgStrong(false, true, .seq_cst, .acquire) != null) {
                writeIndex = (writeIndex + 1) % self.data.len;
                if (writeIndex == self.head.load(.seq_cst)) {
                    return ConcurrentQueueError.QueueIsFull;
                }
            }

            // writeIndex = index of newly acquired slot acquired;
            self.data[writeIndex] = value;

            writeIndex = (writeIndex + 1) % self.data.len;
            if (writeIndex == self.head.load(.seq_cst)) {
                return ConcurrentQueueError.QueueIsFull;
            }
            var expected: usize = start;

            // spin and resolve contention
            while (self.tail.cmpxchgStrong(expected, writeIndex, .seq_cst, .acquire)) |tail| {
                // this is ok, update our expected value an try to CAS again
                if ((expected > tail) or ((expected < tail) and expected < self.head.load(.acquire))) {
                    expected = tail;
                }

                // something else reserved a slot past ours, we can expect them to fixup the value
                if ((tail > expected) or ((tail < expected) and tail < self.head.load(.acquire))) {
                    break;
                }
            }
        }

        // pop the value from the queue, moves the head forward
        pub fn pop(self: *@This()) ?T { // things are empty
            var expected = self.head.load(.acquire);
            var popIndex = expected;
            var newHead = (popIndex + 1) % self.data.len;
            if (newHead == self.tail.load(.acquire)) {
                return null;
            }

            while (self.status[popIndex].cmpxchgStrong(true, false, .seq_cst, .acquire) != null) {
                newHead = (popIndex + 1) % self.data.len;
                popIndex = newHead;

                if (newHead == self.tail.load(.acquire)) {
                    return null;
                }
            }

            // spin and resolve
            while (self.head.cmpxchgStrong(expected, newHead, .seq_cst, .acquire)) |head| {
                // we failed to increment the head
                const tail = self.tail.load(.acquire);

                // something else has already incremented the head past our reservation
                if (head > newHead or (head < newHead and head < tail)) {
                    return self.data[popIndex];
                }

                // our new head is past what the current head is, fixup the value
                if (head < newHead or (newHead < head and newHead < tail)) {
                    expected = head;
                }
            }

            return self.data[popIndex];
        }

        pub fn count(self: @This()) usize {
            const head = self.head.load(.acquire);
            const tail = self.tail.load(.acquire);

            if (opts.allowAsserts) {
                asserts(tail != head, "tail == head in concurrent queue, this shouldnt ever happen", .{}, "concurrent queue assert");
            }

            if (tail > head) {
                return tail - head - 1;
            }

            if (tail < head) {
                return (self.data.len - head) + tail;
            }

            return 0;
        }

        pub fn capacity(self: @This()) usize {
            return self.data.len - 1;
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(self.data);
            allocator.free(self.status);
        }
    };
}

test "concurrent queue basic correctness test" {
    const Info = struct {
        x: u32 = 0,
    };

    const allocator = std.testing.allocator;

    var y = try ConcurrentQueueU(Info).initCapacity(allocator, 420);
    defer y.deinit(allocator);

    try y.push(.{});
    try y.push(.{ .x = 1 });
    try y.push(.{ .x = 2 });
    try y.push(.{ .x = 1 });

    try utils.assertf(y.count() == 4, "expected there to be {d} elements in queue, we saw {d}", .{ 4, y.count() });
    _ = y.pop();
    _ = y.pop();
    _ = y.pop();
    _ = y.pop();

    try utils.assertf(y.count() == 0, "expected there to be {d} elements in queue, we saw {d}", .{ 0, y.count() });

    var x = try ConcurrentQueueU(Info).initCapacity(allocator, 12);
    defer x.deinit(allocator);

    try x.push(.{ .x = 0 });
    try x.push(.{ .x = 1 });
    try x.push(.{ .x = 2 });
    try x.push(.{ .x = 3 });

    try x.push(.{ .x = 4 });
    try x.push(.{ .x = 5 });
    try x.push(.{ .x = 6 });
    try x.push(.{ .x = 7 });

    try x.push(.{ .x = 8 });
    try x.push(.{ .x = 9 });
    try x.push(.{ .x = 10 });

    const maybeError = x.push(.{ .x = 11 });

    try utils.assertf(maybeError == ConcurrentQueueError.QueueIsFull, "Expected queue to have an error", .{});
}

test "concurrent queue multiple producer single consumer" {
    // 1. create multiple threads
    const threadCount = 12;

    const Payload = struct {
        x: i64 = 0,
    };

    const Wrap = struct {
        pub fn threadFunc(queueRef: *ConcurrentQueueU(Payload), id: i64, exitSignal: *Atomic(bool), pushedCountResults: *Atomic(i64)) void {
            var pushedCount: i64 = 0;
            while (!exitSignal.load(.acquire)) {
                queueRef.push(.{
                    .x = id + pushedCount,
                }) catch unreachable;
                pushedCount += 1;

                std.time.sleep(1000 * 1000 * 100);
            }

            _ = pushedCountResults.fetchAdd(pushedCount, .acq_rel);
        }
    };

    var threads: [threadCount]std.Thread = undefined;

    var testQueue = try ConcurrentQueueU(Payload).initCapacity(std.testing.allocator, 4096);
    defer testQueue.deinit(std.testing.allocator);

    var exitSignalAtomic = Atomic(bool).init(false);
    var pushedCountResults = Atomic(i64).init(0);
    std.debug.print("\n\n", .{});

    for (0..threadCount) |i| {
        threads[i] = try std.Thread.spawn(.{}, Wrap.threadFunc, .{ &testQueue, @as(i64, @intCast(i * 10000)), &exitSignalAtomic, &pushedCountResults });
    }

    // 5 second message pump test
    var oldTime: f64 = test_getTime();

    // 10 second test, 5 seconds of input, 5 seconds of drain
    var timeLeft: f64 = 10.0;

    var poppedCount: i64 = 0;

    while (timeLeft > 0 or testQueue.count() > 0) {
        const newTime = test_getTime();
        const deltaTime = newTime - oldTime;
        if (timeLeft - deltaTime < 5.0) {
            exitSignalAtomic.store(true, .release);
        }
        timeLeft -= deltaTime;
        oldTime = newTime;

        //while (testQueue.pop()) |x| {
        {
            if (testQueue.pop()) |x| {
                _ = x;
                // std.debug.print("{d:5}   head={d} ", .{ x.x, testQueue.head.load(.acquire) });
                poppedCount += 1;
                std.debug.print("popped: {d}\t time left = {d:2.3}\t queueCount = {d}           \r", .{ poppedCount, timeLeft, testQueue.count() });
            }
        }
        std.time.sleep(1000 * 1000);
    }

    for (0..threadCount) |i| {
        threads[i].join();
    }

    try utils.assertf(poppedCount == pushedCountResults.load(.acquire), "mismatched, we popped {d} records while the workers pushed {d}", .{ poppedCount, pushedCountResults.load(.acquire) });
}

fn test_getTime() f64 {
    return @as(f64, @floatFromInt(std.time.milliTimestamp())) / 1000;
}
