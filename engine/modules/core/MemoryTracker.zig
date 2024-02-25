// memory tracker

const std = @import("std");

backingAllocator: std.mem.Allocator,

allocationsCount: u32 = 0,
totalAllocSize: usize = 0,

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
    self.allocationsCount += 1;
    self.totalAllocSize += len;
    return self.backingAllocator.vtable.alloc(self.backingAllocator.ptr, len, ptr_align, ret_addr);
}

pub fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
    var self: *@This() = @alignCast(@ptrCast(ctx));
    self.totalAllocSize -= buf.len + new_len;
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
    self.allocationsCount -= 1;
    self.totalAllocSize -= buf.len;
    self.backingAllocator.vtable.free(self.backingAllocator.ptr, buf, buf_align, ret_addr);
}

pub fn printStats(self: @This()) void {
    std.debug.print("allocations: {d}\n", .{self.allocationsCount});
    std.debug.print("memory committed: {d}\n", .{self.totalAllocSize});
}

pub fn deinit(self: *@This()) void {
    _ = self;
}

var gMemTracker: *@This() = undefined;

pub fn setupMemTracker(backingAllocator: std.mem.Allocator) void {
    gMemTracker = .create(@This());
    gMemTracker.* = @This(){ .backingAllocator = backingAllocator };
}

pub fn getMemTracker() *@This() {}
