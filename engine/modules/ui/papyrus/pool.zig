pub const std = @import("std");

const utils = @import("utils.zig");
const assertf = utils.assertf;
pub const Handle = struct {
    index: u24 = 0,
    generation: u8 = 0,
};

// ========================================== Dynamic pool ===============================
pub fn DynamicPool(comptime T: type) type {
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
            self.generations.items[destroyHandle.index] += 1;
        }

        pub fn deinit(self: *@This()) void {
            self.active.deinit(self.allocator);
            self.dead.deinit(self.allocator);
        }
    };
}

// ===================================  End of Dynamic pool =========================
