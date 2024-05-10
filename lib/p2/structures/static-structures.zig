const std = @import("std");

fn makeSlice(comptime T: type, ptr: *T, len: usize) []T {
    var slice: []T = undefined;
    slice.len = len;
    slice.ptr = ptr;
    return slice;
}

// A completely static arraylist, returns out of capacity when it's full.
// does NOT do any kind of allocator backing.
pub fn StaticVector(comptime T: type, comptime size: usize) type {
    return struct {
        fn makeEmptySlice() []T {
            var slice: []T = undefined;
            slice.len = 0;
            slice.ptr = undefined;
            return slice;
        }

        _data: [size]T = undefined,
        items: []T = makeEmptySlice(),

        pub fn append(self: *@This(), value: T) !void {
            if (self.len >= size)
                return error.OutOfCapacity;

            self._data[self.len] = value;
            self.items.ptr = &self._data[0];
            self.items.len += 1;
        }

        pub fn pop(self: *@This()) ?T {
            if (self.len == 0) {
                return null;
            }

            self.items.len -= 1;
            return self._data[self.len];
        }
    };
}

test "static vector" {
    var al = StaticVector(struct { x: u32 = 0 }, 42).init();

    for (0..42) |i| {
        try al.append(.{ .x = i });
    }

    std.debug.assert(al.items[0].x == 0);
    std.debug.assert(al.items[1].x == 1);
} //

// TODO:
//
// this is a fixed size vector which
// exists on the stack until it exceeds the static capacity.
// in which case it gets bumped to the heap with an allocator.
pub fn SmallVectorUnmanaged(comptime T: type, comptime size: usize) type {
    return struct {
        data: [size]T = undefined,
        ptr: *T = undefined,
        len: usize = 0,

        pub fn append(self: *@This()) !void {
            _ = self;
        }
    };
}
