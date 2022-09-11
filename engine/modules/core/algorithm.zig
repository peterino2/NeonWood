const std = @import("std");

const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

pub fn AppendToArrayListUnique(list: anytype, value: anytype) !void {
    for (list.items) |v| {
        if (v == value)
            return;
    }

    try list.append(value);
}
// tail points to next free
// head points to next one to read

const RingQueueError = error{
    QueueIsFull,
    QueueIsEmpty,
    AllocSizeTooSmall,
};

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
            _ = self;

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
