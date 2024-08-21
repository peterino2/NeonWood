const std = @import("std");
const BumpAllocator = @import("../allocators/bump-allocator.zig");
const BitBlockAllocator = @import("../allocators/bitblock-allocator.zig");

// register a global backing allocator

var gStringContext: *StringContext = undefined;

// testing functions for stringAllocation
pub fn destroyStringAllocation(self: StringAllocation, allocator: std.mem.Allocator) void {
    allocator.free(self.deallocBytes());
}

pub fn newStringAllocation(allocator: std.mem.Allocator, stringLength: usize) !StringAllocation {
    const slice = try allocator.alignedAlloc(u8, 2, stringLength + 2);
    const slenPtr = @as(*u16, @ptrCast(@alignCast(slice.ptr)));
    slenPtr.* = @intCast(stringLength);

    return .{ .ptr = slice.ptr };
}
// testing functions for string allocation

const StringAllocation = struct {
    ptr: *align(2) anyopaque,

    pub const MetaLen = 2;
    // offsets:
    // 0x0 - 0x1        : length (u16)
    // 0x2 - length + 2 : string

    pub fn len(self: @This()) usize {
        return @intCast(@as(*u16, @ptrCast(self.ptr)).*);
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
        rv.len = self.len() + 2;
        return rv;
    }

    pub fn fromPtr(ptr: *anyopaque) @This() {
        return .{ .ptr = ptr };
    }
};

pub const StringHandle = packed struct {
    handle: u24,
    _rsvd: u4 = undefined,
    instance: u4,
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
    freeEntries: std.ArrayListUnmanaged(u24) = .{},

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

    pub fn assignOrRecycleSlot(self: *@This(), allocator: std.mem.Allocator) !BucketAllocation {
        if (self.freeEntries.items.len < 1) {
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
            const index = self.freeEntries.pop();

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
            Bucket.init( 0x0, 16,   4096),
            Bucket.init( 0x1, 32,   4096),
            Bucket.init( 0x2, 64,   4096),
            Bucket.init( 0x3, 128,  4096),
            Bucket.init( 0x4, 512,  4096 * 16),
            Bucket.init( 0x5, 4096, 4096 * 16),
        });
        // zig fmt: on

        return self;
    }

    pub fn getAllocator(self: *@This()) std.mem.Allocator {
        return self.arena.allocator();
    }

    pub fn strNew(self: *@This(), length: usize) !struct {
        handle: StringHandle,
        bytes: []u8,
    } {

        // 1. select which bucket to allocate from
        const bucket = self.getBucket(@intCast(length));

        // 2. grab or recycle an allocation from that bucket
        const allocation = try bucket.assignOrRecycleSlot(self.getAllocator());

        // 3. write in the string length.
        @as(*u16, @ptrCast(@alignCast(allocation.bytes.ptr))).* = @intCast(length);

        return .{
            .handle = .{ .instance = @intCast(bucket.id), .handle = allocation.index },
            .bytes = allocation.bytes,
        };
    }

    inline fn getBucket(self: *@This(), stringLength: u32) *Bucket {
        const actualLength = stringLength + StringAllocation.MetaLen;

        // theres probably a few bitwise operations that can do this lookup really
        // quickly.. too tired to think of them right now
        for (self.buckets.items) |*bucket| {
            if (bucket.allocSize > actualLength) {
                return bucket;
            }
        }

        @panic("Unable to find a bucket to allocate string of length.");
    }

    pub fn strDestroy(self: *@This(), handle: StringHandle) void {
        _ = self;
        _ = handle;
    }

    pub fn strEql(self: *@This(), left: StringHandle, right: StringHandle) bool {
        _ = self;
        _ = left;
        _ = right;
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
    const newString = try ctx.strNew(14);
    _ = newString;

    const s = try newStringAllocation(std.testing.allocator, 32);
    defer destroyStringAllocation(s, std.testing.allocator);
}
