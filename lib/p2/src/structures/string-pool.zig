const std = @import("std");

// todo:
//
// - take() - done
// - clone() - done
// - resize()
//
// actually useful functions
// - append()
// - add()
// - trim()
// - substring()
// - split()
// - fmt()

var gStringContext: *StringContext = undefined;

pub const String = struct {
    index: u24,
    bucketId: u8,
    bytes: ?[]u8 = null,

    // potentially slower, use utf8() whenever possible to cache the results
    pub fn getUtf8(self: @This()) []u8 {
        if (self.bytes) |bytes| {
            return bytes;
        } else {
            return gStringContext.getUtf8(self);
        }
    }

    // gets the utf8 value from this handle and caches the result if possible
    pub fn utf8(self: *@This()) []u8 {
        if (self.bytes) |bytes| {
            return bytes;
        } else {
            self.bytes = gStringContext.getUtf8(self.*);
            return self.bytes.?;
        }
    }

    // creates a new string from []const u8
    pub fn new(str: []const u8) !@This() {
        return try gStringContext.newFromUtf8(str);
    }

    // deep copy of a string
    pub fn clone(self: @This()) !@This() {
        return try gStringContext.newFromUtf8(self.utf8());
    }

    // increases the reference count for this string by one and makes a copy of the handle
    pub fn pin(self: @This()) @This() {
        gStringContext.rcAdd(self);
        return self;
    }

    pub fn drop(self: @This()) void {
        gStringContext.strDestroy(self);
    }
};

// testing functions for string allocation
const StringAllocation = struct {
    ptr: *align(2) anyopaque,

    pub const HeaderLen = 4;

    // offsets:
    // 0x0 -> 0x3         : length (u24)
    // 0x3 -> 0x4         : reference count (u8)
    // 0x4 -> length + 4  : string

    pub fn len(self: @This()) usize {
        const read = @as(*u24, @ptrCast(@alignCast(self.ptr))).*;
        return @intCast(read);
    }

    pub fn initRc(self: @This()) void {
        const x: [*]std.atomic.Value(u8) = @ptrCast(self.ptr);
        x[3] = std.atomic.Value(u8).init(1);
    }

    pub fn rcAdd(self: @This()) void {
        const x: [*]std.atomic.Value(u8) = @ptrCast(self.ptr); //+= 1;
        _ = x[3].fetchAdd(1, .monotonic);
    }

    // returns true if the reference count hits 0
    pub fn rcSub(self: @This()) bool {
        const rc: [*]std.atomic.Value(u8) = @ptrCast(self.ptr); //+= 1;

        if (rc[3].fetchSub(1, .release) == 1) {
            rc[3].fence(.acquire);
            return true;
        }

        return false;
    }

    pub fn setLen(self: @This(), length: usize) void {
        @as(*u24, @ptrCast(@alignCast(self.ptr))).* = @intCast(length);
    }

    pub fn bytes(self: @This()) []u8 {
        return @as([*]u8, @ptrCast(self.ptr))[HeaderLen .. HeaderLen + self.len()];
    }

    // returns a bytes list for use with a memory allocator
    pub fn deallocBytes(self: @This()) []align(2) u8 {
        var rv: []align(2) u8 = undefined;
        rv.ptr = @ptrCast(self.ptr);
        rv.len = self.len() + StringAllocation.HeaderLen;
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

    lock: std.Thread.Mutex = .{},

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
        self.lock.lock();
        defer self.lock.unlock();
        self.freeSlots.append(allocator, index) catch unreachable;
    }

    pub fn assignOrRecycleSlot(self: *@This(), allocator: std.mem.Allocator) !BucketAllocation {
        self.lock.lock();
        defer self.lock.unlock();
        if (self.freeSlots.items.len < 1) {
            const pageIndex = self.i2p(self.next);

            if (pageIndex >= self.pages.items.len) {
                try self.addPage(allocator);
            }

            const rv: BucketAllocation = .{
                .bytes = self.indexToSlot(pageIndex, self.ibp(self.next)),
                .index = @intCast(self.next),
            };

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

    pub fn newFromUtf8(self: *@This(), str: []const u8) !String {
        const results = try self.strNew(str.len);

        std.mem.copyForwards(u8, results.bytes, str);
        return results.handle;
    }

    // inner function
    pub fn strNew(self: *@This(), length: usize) !struct {
        handle: String,
        bytes: []u8,
    } {

        // 1. select which bucket to allocate from
        const bucket = self.getBucketByLen(@intCast(length));

        // 2. grab or recycle an allocation from that bucket
        const allocation = try bucket.assignOrRecycleSlot(self.getAllocator());

        // 3. write in the string length.
        const strAllocation = StringAllocation.fromPtr(allocation.bytes.ptr);
        strAllocation.initRc();
        strAllocation.setLen(length);

        return .{
            .handle = .{ .bucketId = @intCast(bucket.id), .index = allocation.index },
            .bytes = strAllocation.bytes(),
        };
    }

    inline fn getBucketByLen(self: *@This(), stringLength: u32) *Bucket {
        const actualLength = stringLength + StringAllocation.HeaderLen;

        // theres probably a few bitwise operations that can do this lookup really
        // quickly.. too tired to think of them right now
        for (self.buckets.items) |*bucket| {
            if (bucket.allocSize >= actualLength) {
                return bucket;
            }
        }

        @panic("Unable to find a bucket to allocate string of length.");
    }

    inline fn getBucketFromHandle(self: @This(), handle: String) *Bucket {
        return &self.buckets.items[@intCast(handle.bucketId)];
    }

    pub fn getUtf8(self: @This(), handle: String) []u8 {
        const x = self.handleToAllocation(handle);
        return x.bytes();
    }

    pub fn rcAdd(self: *@This(), handle: String) void {
        const allocation = self.handleToAllocation(handle);
        allocation.rcAdd();
    }

    pub fn handleToAllocation(self: @This(), handle: String) StringAllocation {
        const bucket = self.getBucketFromHandle(handle);
        const allocation = StringAllocation.fromPtr(bucket.getBytesFromIndex(handle.index).ptr);

        return allocation;
    }

    pub fn strDestroy(self: *@This(), handle: String) void {
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

    const L = struct {
        pub fn wrap(x: String) void {
            std.debug.print("{d},{d}\n", .{ x.bucketId, x.index });
        }
    };

    var s = try String.new("lmao2nova");
    L.wrap(s);

    const x = s.utf8();
    std.debug.print("{x}\n", .{x.len});

    // doing 1Billion accesses

    {
        const now = std.time.nanoTimestamp();
        for (0..1_000_000_000) |i| {
            _ = i;
            _ = s.utf8();
        }
        const end = std.time.nanoTimestamp();
        const duration = end - now;
        std.debug.print("time spent {d}ms\n", .{@as(f64, @floatFromInt(duration)) / 1000_000});
    }

    {
        const now = std.time.nanoTimestamp();
        // 1 million string creations/destructions
        for (0..1_000_000) |i| {
            _ = i;
            const y = try String.new("wutang forever\n");
            defer y.drop();
        }
        const end = std.time.nanoTimestamp();
        const duration = end - now;
        std.debug.print("time spent {d}ms\n", .{@as(f64, @floatFromInt(duration)) / 1000_000});
    }

    // allocate 1 million strings
    const s2 = s.pin();
    defer s2.drop();
}
