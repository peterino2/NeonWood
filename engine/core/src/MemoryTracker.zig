// memory tracker
//
// todo.. rename this to memory.zig

const std = @import("std");
const core = @import("core.zig");
const builtin = @import("builtin");

lock: std.Thread.Mutex = .{},
backingAllocator: std.mem.Allocator,

allocationsCount: u32 = 0,
totalAllocSize: usize = 0,
eventsCount: usize = 0,

peakAllocations: u32 = 0,
peakAllocSize: usize = 0,

stackCompactor: ?*core.StackCompactor = undefined,

timeline: ?EventTimeline,

//const EventTimeline = core.algorithm.PagedVector(AllocEvent);
const EventTimeline = struct {
    timelineAllocator: std.mem.Allocator,
    events: core.algorithm.PagedVector(AllocEvent),
    timestamps: core.algorithm.PagedVector(f64), // timestamp in milliseconds

    pub fn init(timelineAllocator: std.mem.Allocator) !@This() {
        return .{
            .timelineAllocator = timelineAllocator,
            .events = try core.algorithm.PagedVector(AllocEvent).init(timelineAllocator),
            .timestamps = try core.algorithm.PagedVector(f64).init(timelineAllocator),
        };
    }

    pub inline fn pushAlloc(self: *@This(), compactor: *core.StackCompactor, ptr: usize, size: usize) void {
        const callstackId = compactor.getCallStack();
        self.timestamps.append(core.getEngineTime()) catch unreachable;
        self.events.append(.{
            .callstackId = callstackId,
            .address = ptr,
            .event = .{ .alloc = .{ .size = size } },
        }) catch unreachable;
    }

    pub inline fn pushResize(self: *@This(), compactor: *core.StackCompactor, ptr: usize, old_len: usize, new_len: usize) void {
        const callstackId = compactor.getCallStack();
        self.timestamps.append(core.getEngineTime()) catch unreachable;
        self.events.append(.{
            .callstackId = callstackId,
            .address = ptr,
            .event = .{ .resize = .{ .oldSize = old_len, .newSize = new_len } },
        }) catch unreachable;
    }

    pub inline fn pushFree(self: *@This(), compactor: *core.StackCompactor, ptr: usize, size: usize) void {
        const callstackId = compactor.getCallStack();
        self.timestamps.append(core.getEngineTime()) catch unreachable;
        self.events.append(.{
            .callstackId = callstackId,
            .address = ptr,
            .event = .{ .free = .{ .size = size } },
        }) catch unreachable;
    }
};

// warning, due to laziness this uses timelineAllocator, which will leak
pub fn dumpTimeline(filename: []const u8) !void {
    if (MTGet()) |tracker| {
        tracker.lock.lock();
        defer tracker.lock.unlock();
        if (tracker.stackCompactor) |compactor| {
            if (tracker.timeline) |timeline| {
                const cwd = std.fs.cwd();
                const ofile = try std.fmt.allocPrint(timeline.timelineAllocator, core.DefaultSavePath ++ "/{s}", .{filename});
                defer timeline.timelineAllocator.free(ofile);

                var obuf = std.ArrayList(u8).init(timeline.timelineAllocator);
                defer obuf.deinit();
                var writer = obuf.writer();

                var i: usize = 0;

                while (i < timeline.events.len()) : (i += 1) {
                    const event = timeline.events.get(i);
                    const timestamp = timeline.timestamps.get(i);

                    try writer.print("{d}: callstack: {x} @0x{x} ", .{
                        timestamp.*,
                        event.callstackId,
                        event.address,
                    });
                    switch (event.event) {
                        .alloc => |x| {
                            try writer.print("alloc {d} bytes\n", .{x.size});
                        },
                        .free => |x| {
                            try writer.print("free {d} bytes\n", .{x.size});
                        },
                        .resize => |x| {
                            try writer.print("resize {d} -> {d} bytes\n", .{ x.oldSize, x.newSize });
                        },
                    }
                }
                var iter = compactor.stackMap.iterator();
                while (iter.next()) |x| {
                    const callstackId = x.key_ptr.*;
                    const stack = x.value_ptr.*;
                    try writer.print("{x}:\n", .{callstackId});
                    for (stack.debugStr) |frame| {
                        if (frame) |f| {
                            try writer.print("{s}\n", .{f});
                        } else {
                            try writer.print("no file\n", .{});
                        }
                    }
                }

                try cwd.makePath(core.DefaultSavePath);
                try cwd.writeFile(.{
                    .sub_path = ofile,
                    .data = obuf.items,
                });
            }
        } else {
            core.engine_logs("skipping writing memory timeline as timeline is not enabled");
        }
    }
}

const AllocEventType = enum { alloc, free, resize };

const AllocEvent = struct {
    callstackId: u32,
    address: usize,
    event: union(AllocEventType) {
        alloc: struct { size: usize },
        free: struct { size: usize },
        resize: struct { oldSize: usize, newSize: usize },
    },
};

pub var vtable: std.mem.Allocator.VTable = .{
    .alloc = alloc,
    .free = free,
    .resize = resize,
};

pub fn init(backingAllocator: std.mem.Allocator, settings: SetupSettings) @This() {
    // use the ansi allocator

    const EnableMemoryTimeline = settings.timeline and builtin.os.tag == .windows;

    if (EnableMemoryTimeline) {
        core.engine_logs("[dmt] Enabling Detailed Memory Tracking");
    }

    const stackCompactor = if (EnableMemoryTimeline) core.StackCompactor.create(std.heap.c_allocator) catch null else null;

    return .{
        .backingAllocator = backingAllocator,
        .stackCompactor = stackCompactor,
        .timeline = if (EnableMemoryTimeline) EventTimeline.init(std.heap.c_allocator) catch null else null,
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
    const rv = self.backingAllocator.vtable.alloc(self.backingAllocator.ptr, len, ptr_align, ret_addr);

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

        if (self.timeline) |*timeline| {
            timeline.pushAlloc(self.stackCompactor.?, @intFromPtr(rv), len);
        }
    }
    return rv;
}

pub fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
    var self: *@This() = @alignCast(@ptrCast(ctx));
    {
        self.lock.lock();
        defer self.lock.unlock();
        self.totalAllocSize = self.totalAllocSize - buf.len + new_len;
        self.eventsCount += 1;

        if (self.timeline) |*timeline| {
            timeline.pushResize(self.stackCompactor.?, @intFromPtr(buf.ptr), buf.len, new_len);
        }
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

        self.allocationsCount -= 1;
        self.totalAllocSize -= buf.len;
        self.eventsCount += 1;

        if (self.timeline) |*timeline| {
            timeline.pushFree(self.stackCompactor.?, @intFromPtr(buf.ptr), buf.len);
        }
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

pub const SetupSettings = struct {
    timeline: bool = false,
};

pub fn MTSetup(backingAllocator: std.mem.Allocator, settings: SetupSettings) void {
    gMemTracker = backingAllocator.create(@This()) catch unreachable;
    gMemTracker.?.* = @This().init(backingAllocator, settings);
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
