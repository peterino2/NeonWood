pub const std = @import("std");

const utils = @import("utils.zig");
const assertf = utils.assertf;

pub const Handle = struct {
    index: u24 = 0,
    generation: u8 = 0,

    pub fn eql(self: @This(), oth: @This()) bool {
        return self.index == oth.index and self.generation == oth.generation;
    }
};

// Index pool
//
// This a data structure where a list of objects are stored contiguous in memory.
// They can be accessed/manipulated via a handle which can safely tell if it's been
// invalidated or not.
//
// Objects which are destroyed get it's generation tag bumped (thus invalidating existing handles)
// destroyed indicies are put into a 'dead' stack which is used for the next allocation of an object
// in lieu of extending the 'active' list.
//
// This is highly performant for usecases where:
// - You WANT a pool of same sized objects
// - You WANT to efficiently iterate through them later
// - You WANT weak external handles to objects with constant time, non-hashing lookup.
// - You DONT CARE about retaining pointers across operations.
// - You DONT CARE about preserving order of insertion within the data structure.
//
// great for:
// - nodes in a ui library (this was what it was originally created for)
// - scripting objects in a video game,
//
// tags: handle-based, contiguous-physical-storage, weak-references,

pub fn IndexPool(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        active: std.ArrayListUnmanaged(?T),
        generations: std.ArrayListUnmanaged(u8),
        dead: std.ArrayListUnmanaged(u24),

        pub fn init(allocator: std.mem.Allocator) @This() {
            return .{
                .allocator = allocator,
                .active = .{},
                .dead = .{},
                .generations = .{},
            };
        }

        pub fn indexToHandle(self: @This(), index: usize) ?Handle {
            if (index < self.active.items.len) {
                if (self.active.items[index] == null) {
                    return null;
                }

                return .{
                    .index = @intCast(index),
                    .generation = self.generations.items[index],
                };
            }
            return null;
        }

        // this is NOT the actual number of elements active, its just the size of the active list
        pub fn count(self: @This()) usize {
            return self.active.items.len;
        }

        pub fn new(self: *@This(), initVal: T) !Handle {
            if (self.dead.items.len > 0) {
                const revivedIndex = self.dead.items[self.dead.items.len - 1];

                try assertf(
                    revivedIndex < self.active.items.len,
                    "tried to revive index {d} which does not exist in pool of size {d}\n",
                    .{ revivedIndex, self.active.items.len },
                );

                self.active.items[revivedIndex] = initVal;
                self.dead.shrinkRetainingCapacity(self.dead.items.len - 1);
                return .{
                    .index = revivedIndex,
                    .generation = self.generations.items[revivedIndex],
                };
            }

            try self.active.append(self.allocator, initVal);
            try self.generations.append(self.allocator, 0);

            return .{
                .index = @as(u24, @intCast(self.active.items.len - 1)),
                .generation = 0,
            };
        }

        pub fn isValid(self: @This(), handle: Handle) bool {
            if (handle.index >= self.active.items.len) {
                return false;
            }

            if (self.active.items[handle.index] == null) {
                return false;
            }

            if (self.generations.items[handle.index] != handle.generation) {
                return false;
            }
            return true;
        }

        pub fn get(self: *@This(), handle: Handle) ?*T {
            if (!self.isValid(handle)) {
                return null;
            }

            return &(self.active.items[handle.index].?);
        }

        pub fn getRead(self: @This(), handle: Handle) ?*const T {
            if (!self.isValid(handle)) {
                return null;
            }

            return &(self.active.items[handle.index].?);
        }

        pub fn destroy(self: *@This(), destroyHandle: Handle) void {
            self.active.items[destroyHandle.index] = null;
            self.dead.append(self.allocator, destroyHandle.index) catch unreachable;
            self.generations.items[destroyHandle.index] +%= 1;
        }

        pub fn deinit(self: *@This()) void {
            self.active.deinit(self.allocator);
            self.dead.deinit(self.allocator);
            self.generations.deinit(self.allocator);
        }
    };
}

test "index pool test" {
    const TestStruct = struct {
        value1: u32 = 0,
        value4: u32 = 0,
        value2: u32 = 0,
        value3: u32 = 0,
    };

    var dynPool = IndexPool(TestStruct).init(std.testing.allocator);
    defer dynPool.deinit();

    {
        // insert some objects objects
        var count: u32 = 1000000;
        while (count > 0) : (count -= 1) {
            _ = try dynPool.new(.{});
        }

        // Insert 1 randomly add and delete objects another million objects in groups
        var prng = std.rand.DefaultPrng.init(0x1234);
        var rand = prng.random();

        var workBuffer: [5]Handle = .{ .{}, .{}, .{}, .{}, .{} };

        count = 1000000;
        while (count > 0) : (count -= 1) {
            const index = rand.int(u32) % 5;
            var i: u32 = 0;
            while (i < index) : (i += 1) {
                workBuffer[i] = try dynPool.new(.{});
            }

            i = 0;
            while (i < index) : (i += 1) {
                dynPool.get(workBuffer[i]).?.*.value1 = 2;
                dynPool.destroy(workBuffer[i]);
            }
        }
    }
}
