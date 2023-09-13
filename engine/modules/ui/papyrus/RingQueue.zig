pub const std = @import("std");

// ========================================== Ring Queue =========================
pub const RingQueueError = error{
    QueueIsFull,
    QueueIsEmpty,
    AllocSizeTooSmall,
};

// managed version of the ringqueue, includes a mutex
pub fn RingQueue(comptime T: type) type {
    return struct {
        const _InnerType = RingQueueU(T);

        queue: _InnerType,
        allocator: std.mem.Allocator,
        mutex: std.Thread.Mutex = .{},

        pub fn init(allocator: std.mem.Allocator, size: usize) !@This() {
            var newSelf = @This(){
                .queue = try _InnerType.init(allocator, size),
                .allocator = allocator,
                .mutex = .{},
            };

            return newSelf;
        }

        pub fn pushLocked(self: *@This(), newValue: T) RingQueueError!void {
            self.mutex.lock();
            try self.queue.push(newValue);
            defer self.mutex.unlock();
        }

        // only call this if you have locked already
        pub fn popFromUnlocked(self: *@This()) ?T {
            return self.queue.pop();
        }

        pub fn lock(self: *@This()) void {
            self.mutex.lock();
        }

        pub fn unlock(self: *@This()) void {
            self.mutex.unlock();
        }

        pub fn popFromLocked(self: *@This()) ?T {
            try self.mutex.lock();
            defer self.mutex.unlock();
            const val = self.queue.pop();
            return val;
        }

        pub fn count(self: @This()) usize {
            return self.queue.count();
        }

        pub fn deinit(self: *@This()) void {
            self.queue.deinit();
        }
    };
}

// tail points to next free
// head points to next one to read
// unmanaged ring queue
pub fn RingQueueU(comptime T: type) type {
    return struct {
        buffer: []T = undefined,
        head: usize = 0, // resets upon resizes
        tail: usize = 0, // resets upon resizes

        pub fn init(allocator: std.mem.Allocator, size: usize) !@This() {
            var self = @This(){
                .buffer = try allocator.alloc(T, size + 1),
            };

            return self;
        }

        pub fn push(self: *@This(), value: T) RingQueueError!void {
            const next = (self.tail + 1) % self.buffer.len;

            if (next == self.head) {
                return error.QueueIsFull;
            }
            self.buffer[self.tail] = value;
            self.tail = next;
        }

        pub fn pushFront(self: *@This(), value: T) !void {
            var iHead = @as(isize, @intCast(self.head)) - 1;

            if (iHead < 0) {
                iHead = @as(isize, @intCast(self.buffer.len)) + iHead;
            }

            if (iHead == @as(isize, @intCast(self.tail))) {
                return error.QueueIsFull;
            }

            self.head = @as(usize, @intCast(iHead));
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
            const cnt = self.count();

            if (offset > cnt or offset == 0) {
                return null;
            }

            var x: isize = @as(isize, @intCast(self.tail)) - @as(isize, @intCast(offset));

            if (x < 0) {
                x = @as(isize, @intCast(self.buffer.len)) + x;
            }

            return &self.buffer[@as(usize, @intCast(x))];
        }

        pub fn at(self: *@This(), offset: usize) ?*T {
            const cnt = self.count();

            if (cnt == 0) {
                return null;
            }

            if (offset >= cnt) {
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
            const cnt = self.count();

            // new size needs to be greater than current size by 1, tail always points to an empty
            if (cnt >= size) {
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

// ========================================== End Of RingQueue ==================================
