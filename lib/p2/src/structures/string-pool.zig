const std = @import("std");

// register a global backing allocator

var gStringContext: *StringContext = undefined;

pub const StringHandle = packed struct {
    index: u24,
    bucketId: u8,

    pub fn utf8(self: @This()) []u8 {
        return gStringContext.getUtf8(self);
    }
};

// testing functions for stringAllocation
pub fn destroyStringAllocation(self: StringAllocation, allocator: std.mem.Allocator) void {
    allocator.free(self.deallocBytes());
}

pub fn newStringAllocation(allocator: std.mem.Allocator, stringLength: usize) !StringAllocation {
    const slice = try allocator.alignedAlloc(u8, 2, stringLength + StringAllocation.MetaLen);
    const slenPtr = @as(*u24, @ptrCast(@alignCast(slice.ptr)));
    slenPtr.* = @intCast(stringLength);

    return .{ .ptr = slice.ptr };
}
// testing functions for string allocation

const StringAllocation = struct {
    ptr: *align(2) anyopaque,

    pub const MetaLen = 4;
    // offsets:
    // 0x0 -] 0x2         : length (u24)
    // 0x3 -] 0x4         : reference count (u8)
    // 0x4 -  length + 4  : string

    pub fn len(self: @This()) usize {
        return @intCast(@as(*u24, @ptrCast(@alignCast(self.ptr))).*);
    }

    pub fn initRc(self: @This()) void {
        const x: [*]u8 = @ptrCast(self.ptr);
        x[3] = 1;
    }

    pub fn rcAdd(self: @This()) void {
        const x: [*]u8 = @ptrCast(self.ptr); //+= 1;
        x[3] += 1;
    }

    // returns true if the reference count hits 0
    pub fn rcSub(self: @This()) bool {
        const rc: [*]u8 = @ptrCast(self.ptr); //+= 1;
        rc[3] -= 1;

        if (rc[3] == 0) {
            return true;
        }
        return false;
    }

    pub fn bytes(self: @This()) []u8 {
        var rv: []u8 = undefined;
        rv.ptr = @ptrCast(self.ptr + 0x2);
        rv.len = self.len();
        return rv;
    }

    // returns a bytes list for use with a memory allocator
    pub fn deallocBytes(self: @This()) []align(2) u8 {
        var rv: []align(2) u8 = undefined;
        rv.ptr = @ptrCast(self.ptr);
        rv.len = self.len() + StringAllocation.MetaLen;
        return rv;
    }

    pub fn fromPtr(ptr: *anyopaque) @This() {
        return .{ .ptr = @ptrCast(@alignCast(ptr)) };
    }
};

const Page = struct {
    bytes: []align(8) u8,
};

const Bucket = struct {
    id: u32,
    allocSize: u32,

    pageSize: u32,
    slotsPerPage: u32,
    next: u32 = 0,
    pages: std.ArrayListUnmanaged(Page) = .{},
    freeSlots: std.ArrayListUnmanaged(u32) = .{},

    pub const BucketAllocation = struct {
        bytes: []u8,
        index: u24,
    };

    pub fn init(id: u32, allocSize: u32, pageSize: u32) @This() {
        return .{
            .id = id,
            .allocSize = allocSize,
            .pageSize = pageSize,
            .slotsPerPage = pageSize / allocSize,
        };
    }

    // index to page
    inline fn i2p(self: @This(), index: u32) u32 {
        return @divFloor(index, self.slotsPerPage);
    }

    // index based off of a page
    inline fn ibp(self: @This(), index: u32) u32 {
        return index % self.slotsPerPage;
    }

    fn getBytesFromIndex(self: @This(), index: u32) []u8 {
        return self.indexToSlot(self.i2p(index), self.ibp(index));
    }

    fn addPage(self: *@This(), allocator: std.mem.Allocator) !void {
        const page: Page = .{
            .bytes = try allocator.alignedAlloc(u8, 8, self.pageSize),
        };
        try self.pages.append(allocator, page);
    }

    fn indexToSlot(self: @This(), pageIndex: u32, pageBase: u32) []u8 {
        const left = pageBase * self.allocSize;
        const right = left + self.allocSize;
        const slice = self.pages.items[pageIndex].bytes[left..right];
        return slice;
    }

    pub fn destroySlot(self: *@This(), allocator: std.mem.Allocator, index: u32) void {
        self.freeSlots.append(allocator, index) catch unreachable;
    }

    pub fn assignOrRecycleSlot(self: *@This(), allocator: std.mem.Allocator) !BucketAllocation {
        if (self.freeSlots.items.len < 1) {
            const pageIndex = self.i2p(self.next);

            if (pageIndex >= self.pages.items.len) {
                try self.addPage(allocator);
            }

            const rv: BucketAllocation = .{
                .bytes = self.indexToSlot(pageIndex, self.ibp(self.next)),
                .index = @intCast(self.next),
            };

            std.debug.print("next is getting bumped : {d}", .{self.next});

            self.next += 1;

            return rv;
        } else {
            const index = self.freeSlots.pop();

            const rv: BucketAllocation = .{
                .bytes = self.indexToSlot(self.i2p(index), self.ibp(index)),
                .index = @intCast(index),
            };

            return rv;
        }
    }
};

pub const StringContext = struct {
    backingAllocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator, // for now, just do an arenaAllocator
    buckets: std.ArrayListUnmanaged(Bucket) = .{},

    // todo,
    // if I REALLY want to juice the living frick out of this perf.
    // I would use the following allocation strategies
    // - temporal allocation hints, (short lived allocations go into a fast frame bump allocator)
    // - granular bit-bucket allocations, (lots of strings are very short)

    pub fn create(backingAllocator: std.mem.Allocator) !*@This() {
        const self = try backingAllocator.create(@This());

        self.* = .{
            .backingAllocator = backingAllocator,
            .arena = std.heap.ArenaAllocator.init(backingAllocator),
        };

        // default bucket setup
        // zig fmt: off
        try self.buckets.appendSlice(backingAllocator, &.{
            Bucket.init( 0x0, 16, 4096 * 1),
            Bucket.init( 0x1, 32, 4096 * 1),
            Bucket.init( 0x2, 64, 4096 * 1),
            Bucket.init( 0x3, 128, 4096 * 1),
            Bucket.init( 0x4, 512, 4096 * 16),
            Bucket.init( 0x5, 4096, 4096 * 16),
        });
        // zig fmt: on

        return self;
    }

    pub fn getAllocator(self: *@This()) std.mem.Allocator {
        return self.arena.allocator();
    }

    // inner function
    pub fn strNew(self: *@This(), length: usize) !struct {
        handle: StringHandle,
        bytes: []u8,
    } {

        // 1. select which bucket to allocate from
        const bucket = self.getBucketByLen(@intCast(length));

        // 2. grab or recycle an allocation from that bucket
        const allocation = try bucket.assignOrRecycleSlot(self.getAllocator());

        // 3. write in the string length.
        @as(*u24, @ptrCast(@alignCast(allocation.bytes.ptr))).* = @intCast(length);
        StringAllocation.fromPtr(allocation.bytes.ptr).initRc();

        return .{
            .handle = .{ .bucketId = @intCast(bucket.id), .index = allocation.index },
            .bytes = allocation.bytes,
        };
    }

    inline fn getBucketByLen(self: *@This(), stringLength: u32) *Bucket {
        const actualLength = stringLength + StringAllocation.MetaLen;

        // theres probably a few bitwise operations that can do this lookup really
        // quickly.. too tired to think of them right now
        for (self.buckets.items) |*bucket| {
            if (bucket.allocSize >= actualLength) {
                return bucket;
            }
        }

        @panic("Unable to find a bucket to allocate string of length.");
    }

    inline fn getBucketFromHandle(self: @This(), handle: StringHandle) *Bucket {
        return &self.buckets.items[@intCast(handle.bucketId)];
    }

    pub fn getUtf8(self: @This(), handle: StringHandle) []u8 {
        return self.handleToAllocation(handle).bytes();
    }

    pub fn handleToAllocation(self: *@This(), handle: StringHandle) StringAllocation {
        const bucket = self.getBucketFromHandle(handle);
        const allocation = StringAllocation.fromPtr(bucket.getBytesFromIndex(handle.index).ptr);

        return allocation;
    }

    pub fn strDestroy(self: *@This(), handle: StringHandle) void {
        const allocation = self.handleToAllocation(handle);
        if (allocation.rcSub()) {
            const bucket = self.getBucketFromHandle(handle);
            bucket.destroySlot(self.getAllocator(), @intCast(handle.index));
        }
    }

    pub fn destroy(self: *@This()) void {
        self.arena.deinit();
        self.buckets.deinit(self.backingAllocator);
        self.backingAllocator.destroy(self);
    }
};

pub fn setup(allocator: std.mem.Allocator) !void {
    gStringContext = try StringContext.create(allocator);
}

pub fn shutdown() void {
    gStringContext.destroy();
}

test "string context" {
    try setup(std.testing.allocator);
    defer shutdown();

    const ctx = gStringContext;
    const testSizes: []const u32 = &.{ 14, 15, 16, 12, 32, 10, 1, 2, 3, 4, 440, 450, 3200 };
    for (testSizes) |testSize| {
        const results = try ctx.strNew(testSize);
        std.debug.print("test {d} = {d}, {d}\n", .{ testSize, results.handle.bucketId, results.handle.index });
    }

    const s = try newStringAllocation(std.testing.allocator, 32);
    defer destroyStringAllocation(s, std.testing.allocator);
}
