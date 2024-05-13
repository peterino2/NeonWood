const std = @import("std");

// it's like an normal vector/ arraylist except it never invalidates old pointers.
// and never causes re-allocations. (excepting in the control block, which is just a vector of things)
//
// It is implemented with a control block which which contains a list of pages.
// these pages contain the actual memory of the vector.
//
// it has a growth factor, which can be configured.
//
// use cases:
//
// - this is highly performant for cases where
// - YOU WANT generally fast insertion time
// - YOU WANT fast random access time
// - YOU WANT cache-coherent and efficient linear iteration
// - YOU WANT to retain pointers across operations
// - YOU WANT to avoid reallocations (eg. if the data set is remarkably big)
// - YOU KNOW that you have linear growth factors and exponential growth is overkill.
//
// great for:
// - event logging.
// - output buffering.
// - recording timelines.

pub fn PagedVectorAdvanced(comptime T: type, comptime growth: usize) type {
    return struct {
        const Page = struct {
            data: [growth]T = undefined,
            len: u32 = 0,
        };

        pages: std.ArrayListUnmanaged(*Page) = .{},
        currentPageId: usize = 0,
        head: *T,

        pub fn init(allocator: std.mem.Allocator) !@This() {
            var rv = @This(){
                .head = undefined,
            };

            const page = try allocator.create(Page);
            page.* = .{};
            try rv.pages.append(allocator, page);
            rv.head = &rv.pages.items[0].data[0];
            return rv;
        }

        pub fn capacity(self: @This()) usize {
            return self.pages.items.len * growth;
        }

        pub fn len(self: @This()) usize {
            return (self.currentPageId) * growth + self.currentPage().len;
        }

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            for (self.pages.items) |page| {
                allocator.destroy(page);
            }

            self.pages.deinit(allocator);
        }

        fn maybeExpand(self: *@This(), allocator: std.mem.Allocator) !void {
            if (self.currentPageId == self.pages.items.len - 1) {
                const page = try allocator.create(Page);
                page.* = .{};
                try self.pages.append(allocator, page);
                self.currentPageId = self.pages.items.len - 1;
            } else {
                self.currentPageId += 1;
            }
        }

        pub fn append(self: *@This(), allocator: std.mem.Allocator, value: T) !void {
            var page = self.currentPage();
            page.len += 1;
            if (page.len >= growth) {
                try self.maybeExpand(allocator);
                var appendedPage = self.pages.items[self.pages.items.len - 1];
                self.head = &appendedPage.data[appendedPage.len];
            } else {
                self.head = &page.data[page.len - 1];
            }
            self.head.* = value;
        }

        pub fn appendSlice(self: *@This(), allocator: std.mem.Allocator, slice: []const T) !void {
            for (slice) |value| {
                try self.append(allocator, value);
            }
        }

        pub fn getMutable(self: *@This(), index: usize) *T {
            const pageIndex = std.math.divFloor(usize, index, growth) catch unreachable;
            return &self.pages.items[pageIndex].data[index % growth];
        }

        pub fn get(self: @This(), index: usize) *const T {
            const pageIndex = std.math.divFloor(usize, index, growth) catch unreachable;
            return &self.pages.items[pageIndex].data[index % growth];
        }

        // swaps the element at the index with the element currently pointed to by head
        // then pops back the head, shrinking length by 1
        //
        // Efficient removal of an element at an index but does not preserve order.
        pub fn swapRemove(self: *@This(), index: usize) void {
            const ptr = self.getMutable(index);
            ptr.* = self.head.*;
            _ = try self.pop();
        }

        fn currentPage(self: @This()) *Page {
            return self.pages.items[self.currentPageId];
        }

        // // retrieves a value, shrinking length by 1
        pub fn pop(self: *@This()) !T {
            const rv = self.head.*;
            var page = self.currentPage();
            page.len -= 1;
            if (page.len < 1) {
                page.len = 0;
                self.currentPageId -= 1;
            }

            self.head = &self.currentPage().data[self.currentPage().len - 1];
            return rv;
        }
    };
}

pub fn PagedVectorUnmanaged(comptime T: type) type {
    return PagedVectorAdvanced(T, 1024);
}

pub fn PagedVector(comptime T: type) type {
    return struct {
        const VectorType = PagedVectorAdvanced(T, 1024);

        vector: VectorType,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !@This() {
            return .{
                .vector = try VectorType.init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.vector.deinit(self.allocator);
        }

        pub fn appendSlice(self: *@This(), slice: []const T) !void {
            try self.vector.appendSlice(self.allocator, slice);
        }

        pub fn append(self: *@This(), value: T) !void {
            try self.vector.append(self.allocator, value);
        }

        pub fn get(self: *const @This(), index: usize) *const T {
            self.vector.get(index);
        }

        pub fn getMutable(self: *@This(), index: usize) *T {
            self.vector.getMutable(index);
        }

        pub fn len(self: @This()) usize {
            return self.vector.len();
        }

        pub fn capacity(self: @This()) usize {
            return self.vector.capacity();
        }

        pub fn swapRemove(self: *@This(), index: usize) void {
            self.vector.swapRemove(index);
        }

        // // retrieves a value, shrinking length by 1
        pub fn pop(self: *@This()) !T {
            return try self.vector.pop();
        }
    };
}

test "simple loading multiple pages." {
    const TestStruct = struct {
        lmao: usize,
    };

    const allocator = std.testing.allocator;
    var vector = try PagedVectorAdvanced(TestStruct, 1024).init(std.testing.allocator);
    defer vector.deinit(allocator);

    for (0..128) |j| {
        try vector.append(allocator, .{ .lmao = j });
    }

    const ptr = vector.get(0);
    const mutable = vector.getMutable(127);

    for (0..4096) |i| {
        try vector.append(allocator, .{ .lmao = i });
    }

    // testing that pointers are not invalidated
    std.debug.assert(ptr == vector.get(0));
    std.debug.assert(mutable == vector.getMutable(127));

    std.debug.assert(vector.getMutable(4092) == vector.getMutable(4092));

    // 4096 + 128 = 4224 = 4 pages + 128 extra entries
    std.debug.assert(vector.pages.items.len == 5);
    std.debug.assert(vector.capacity() == 1024 * 5);
    std.debug.assert(vector.len() == 128 + 1024 * 4);

    // 4092 - 3072 =  offset of 1020 in the third page.
    const ptr4092 = vector.getMutable(4092);
    std.debug.assert(vector.getMutable(4092) == &vector.pages.items[3].data[1020]);

    // lets try adding 1024 elements and see if pointers are still preserved.
    for (0..1024) |_| {
        try vector.append(allocator, .{ .lmao = 0 });
    }

    std.debug.assert(vector.getMutable(4092) == ptr4092);
    std.debug.assert(vector.get(0).lmao == 0);
    std.debug.assert(vector.get(1).lmao == 1);
    std.debug.assert(vector.get(2).lmao == 2);

    // testing the pop() function
    std.debug.assert(vector.len() == 128 + 1024 * 5);
    _ = try vector.pop();
    _ = try vector.pop();
    _ = try vector.pop();

    // testing the swapRemove Functionality
    std.debug.assert(vector.len() == 128 + 1024 * 5 - 3);
    vector.swapRemove(1);
    std.debug.assert(vector.len() == 128 + 1024 * 5 - 4);

    for (0..1024) |_| {
        vector.swapRemove(0);
    }
    std.debug.assert(vector.len() == 128 + 1024 * 5 - 4 - 1024);
}

test "managed version" {
    const allocator = std.testing.allocator;

    var vec = try PagedVector(struct { lmao: u64 }).init(allocator);
    defer vec.deinit();

    for (0..8192) |i| {
        try vec.append(.{ .lmao = i });
    }

    std.debug.assert(vec.vector.pages.items.len == 9);
}
