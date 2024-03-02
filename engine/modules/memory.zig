// memory tracker

const std = @import("std");
pub const MemoryTracker = @import("memory/MemoryTracker.zig");
pub const core = @import("core.zig");

var gMemTracker: ?*MemoryTracker = null;

pub fn MTSetup(backingAllocator: std.mem.Allocator) void {
    gMemTracker = backingAllocator.create(MemoryTracker) catch unreachable;
    gMemTracker.?.* = .{ .backingAllocator = backingAllocator };
}

pub fn MTShutdown() void {
    var backingAllocator = gMemTracker.?.backingAllocator;
    gMemTracker.?.deinit();
    backingAllocator.destroy(gMemTracker.?);
    gMemTracker = null;
}

pub fn MTGet() ?*MemoryTracker {
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
        core.engine_log("allocated size: {d}", .{mt.totalAllocSize});
    }
}
