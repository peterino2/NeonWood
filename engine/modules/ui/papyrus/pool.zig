pub const std = @import("std");

const utils = @import("utils.zig");
const assertf = utils.assertf;

// ========================================== Dynamic pool ===============================
pub fn DynamicPool(comptime T: type) type {
    return struct {
        pub const Handle = u32;

        allocator: std.mem.Allocator,
        active: std.ArrayListUnmanaged(?T),
        dead: std.ArrayListUnmanaged(Handle),

        pub fn init(allocator: std.mem.Allocator) @This() {
            return .{
                .allocator = allocator,
                .active = .{},
                .dead = .{},
            };
        }

        pub fn new(self: *@This(), initVal: T) !Handle {
            if (self.dead.items.len > 0) {
                const revivedIndex = @as(Handle, @intCast(self.dead.items[self.dead.items.len - 1]));

                try assertf(
                    revivedIndex < self.active.items.len,
                    "tried to revive index {d} which does not exist in pool of size {d}\n",
                    .{ revivedIndex, self.active.items.len },
                );

                self.active.items[revivedIndex] = initVal;
                self.dead.shrinkRetainingCapacity(self.dead.items.len - 1);
                return revivedIndex;
            }

            try self.active.append(self.allocator, initVal);
            return @as(Handle, @intCast(self.active.items.len - 1));
        }

        pub fn isValid(self: @This(), handle: Handle) bool {
            if (handle >= self.active.items.len) {}
        }

        pub fn get(self: *@This(), handle: Handle) ?*T {
            if (handle >= self.active.items.len) {
                return null;
            }

            if (self.active.items[handle] == null) {
                return null;
            }

            return &(self.active.items[handle].?);
        }

        pub fn getRead(self: @This(), handle: Handle) ?*const T {
            if (handle >= self.active.items.len) {
                return null;
            }

            return &(self.active.items[handle].?);
        }

        pub fn destroy(self: *@This(), destroyHandle: Handle) void {
            self.active.items[destroyHandle] = null;
            self.dead.append(self.allocator, destroyHandle) catch unreachable;
        }

        pub fn deinit(self: *@This()) void {
            self.active.deinit(self.allocator);
            self.dead.deinit(self.allocator);
        }
    };
}

// ===================================  End of Dynamic pool =========================
