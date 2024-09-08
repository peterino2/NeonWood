// memory tracker
//
// todo.. rename this to memory.zig

const std = @import("std");
const core = @import("core.zig");

lock: std.Thread.Mutex = .{},
backingAllocator: std.mem.Allocator,

allocationsCount: u32 = 0,
totalAllocSize: usize = 0,
eventsCount: usize = 0,

peakAllocations: u32 = 0,
peakAllocSize: usize = 0,

pub var vtable: std.mem.Allocator.VTable = .{
    .alloc = alloc,
    .free = free,
    .resize = resize,
};

pub fn init(backingAllocator: std.mem.Allocator) @This() {
    return .{
        .backingAllocator = backingAllocator,
    };
}

pub fn allocator(self: *@This()) std.mem.Allocator {
    return .{
        .ptr = self,
        .vtable = &vtable,
    };
}

pub fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
    var self: *@This() = @alignCast(@ptrCast(ctx));
    {
        self.lock.lock();
        defer self.lock.unlock();
        self.allocationsCount += 1;
        self.totalAllocSize += len;
        self.eventsCount += 1;

        if (self.totalAllocSize > self.peakAllocSize) {
            self.peakAllocSize = self.totalAllocSize;
        }

        if (self.allocationsCount > self.peakAllocations) {
            self.peakAllocations = self.allocationsCount;
        }
    }
    return self.backingAllocator.vtable.alloc(self.backingAllocator.ptr, len, ptr_align, ret_addr);
}

pub fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
    var self: *@This() = @alignCast(@ptrCast(ctx));
    {
        self.lock.lock();
        defer self.lock.unlock();
        self.totalAllocSize = self.totalAllocSize - buf.len + new_len;
        self.eventsCount += 1;
    }

    return self.backingAllocator.vtable.resize(
        self.backingAllocator.ptr,
        buf,
        buf_align,
        new_len,
        ret_addr,
    );
}

pub fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
    var self: *@This() = @alignCast(@ptrCast(ctx));
    {
        self.lock.lock();
        defer self.lock.unlock();
        // std.debug.print("freeing memory: 0x{x}\n", .{@intFromPtr(buf.ptr)});
        self.allocationsCount -= 1;
        self.totalAllocSize -= buf.len;
        self.eventsCount += 1;
    }
    self.backingAllocator.vtable.free(self.backingAllocator.ptr, buf, buf_align, ret_addr);
}

pub fn printStats(self: @This()) void {
    std.debug.print("allocations: {d}\n", .{self.allocationsCount});
    std.debug.print("memory committed: {d}\n", .{self.totalAllocSize});
}

pub fn deinit(self: *@This()) void {
    _ = self;
}

pub fn addUntrackedAllocation(self: *@This(), allocatedSize: usize) void {
    self.totalAllocSize += allocatedSize;
}

pub fn removeUntrackedAllocation(self: *@This(), allocatedSize: usize) void {
    self.totalAllocSize -= allocatedSize;
}

var gMemTracker: ?*@This() = null;

pub fn setupMemTracker(backingAllocator: std.mem.Allocator) void {
    gMemTracker = .create(@This());
    gMemTracker.* = @This(){ .backingAllocator = backingAllocator };
}

pub fn getMemTracker() *@This() {}

pub fn MTSetup(backingAllocator: std.mem.Allocator) void {
    gMemTracker = backingAllocator.create(@This()) catch unreachable;
    gMemTracker.?.* = .{ .backingAllocator = backingAllocator };
}

pub fn MTShutdown() void {
    var backingAllocator = gMemTracker.?.backingAllocator;
    gMemTracker.?.deinit();
    backingAllocator.destroy(gMemTracker.?);
    gMemTracker = null;
}

pub fn MTGet() ?*@This() {
    return gMemTracker;
}

// todo replace all these functions with a virtual table
pub fn MTAddUntrackedAllocation(allocatedSize: usize) void {
    if (gMemTracker) |mt|
        mt.addUntrackedAllocation(allocatedSize);
}

pub fn MTRemoveAllocation(allocatedSize: usize) void {
    if (gMemTracker) |mt|
        mt.removeUntrackedAllocation(allocatedSize);
}

pub fn MTPrintStatsDelta() void {
    if (gMemTracker) |mt| {
        core.engine_log("allocated size: {d} ({d:.3} MiB)", .{
            mt.totalAllocSize,
            @as(f64, @floatFromInt(mt.totalAllocSize)) / 1024 / 1024,
        });
        core.engine_log("peak allocated size size: {d} ({d:.3} MiB) ({d} peak allocations)", .{
            mt.peakAllocSize,
            @as(f64, @floatFromInt(mt.peakAllocSize)) / 1024 / 1024,
            mt.peakAllocations,
        });
    }
}

pub fn PrintStatsWithTag(comptime tag: []const u8) void {
    core.engine_logs(tag);
    MTPrintStatsDelta();
}
