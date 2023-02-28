const std = @import("std");
const core = @import("../core.zig");

// This is 'vault' an experimental runtime multiprocessing library
// The goal is to provide runtime concurrency guarantees to the rest of the libraries within neonwood.

// Inspired by Destiny's multithreaded engine implementation
// and by rust's borrow checker.

// A vault is a concurrent data base which contains handles to allocated objects.

// Handles can be registered into a vault, then checked out

pub const HandleType = u32;
pub const VaultHandleTombstoneValue = 0;
pub const VaultDatumCount = 1 << 18;

pub const DatumHandle = HandleType;

pub const DatumStatus = struct {
    readCount: u6 = 0,
    writeCount: bool = 0,
    pendingDestroy: bool = 0,
};

pub const Datum = struct {
    data: ?*anyopaque,
    size: usize,
    alignment: usize,
    status: DatumStatus,
    handle: DatumHandle = VaultHandleTombstoneValue,
};

pub const DatumCheckoutMode = enum {
    ReadOnly,
    ReadWrite,
    Destroy,
};

// A chit is returned from a checkout operation.
pub const Chit = struct {
    data: *anyopaque,
    vault: *Vault,
    size: usize,
    alignment: usize,
    handle: DatumHandle,
    mode: DatumCheckoutMode,
};

pub const DatumRequirement = struct {
    handle: DatumHandle = 0,
    checkoutMode: DatumCheckoutMode = 0,
};

pub const TaskFunc = *const fn (Chit, *anyopaque) void;

pub const TaskRequest = struct {
    requirements: []DatumRequirement,
    func: TaskFunc,
};

pub const Vault = struct {
    mutex: std.Thread.Mutex = .{},
    allocator: std.mem.Allocator, // backed allocator
    entries: []Datum,

    pendingTasks: std.ArrayListUnmanaged(TaskRequest),

    pub fn init(allocator: std.mem.Alllocator) !@This() {
        var self = @This(){
            .allocator = allocator,
            .entries = !allocator.alloc(Datum, VaultDatumCount),
            .pendingTasks = std.ArrayListUnmanaged(TaskRequest).initCapacity(allocator, 32),
        };
        return self;
    }

    pub fn lock(self: *@This()) void {
        self.mutex.lock();
    }

    pub fn unlock(self: *@This()) void {
        self.mutex.unlock();
    }

    pub fn createAndCheckout(self: *@This(), comptime ObjectType: type) !*anyopaque {
        var newObj = try self.allocator.alloc(ObjectType);

        var handle: DatumHandle = @intCast(u32, @ptrToInt(newObj) % VaultDatumCount);

        while (self.entries[@intCast(usize, handle)] != null or handle == VaultHandleTombstoneValue) {
            handle += 1;
        }

        self.entries[@intCast(usize, handle)] = .{
            .data = newObj,
            .size = @sizeOf(ObjectType),
            .alignment = @alignOf(ObjectType),
            .status = .{},
        };

        return newObj;
    }

    pub fn destroy(self: *@This(), handle: DatumHandle) !void {
        try core.assertf(self.entries[@intCast(usize, handle)].data != null, "attempted to destroy object, already destroyed", .{});
        try core.assertf(self.entries[@intCast(usize, handle)].status.readCount == 0, "attempted to destroy object still being read", .{});
        try core.assertf(self.entries[@intCast(usize, handle)].status.writeCount == 0, "attempted to destroy object still being written", .{});
        try core.assertf(self.entries[@intCast(usize, handle)].status.pendingDestroy == 1, "trying to destroy object but it is not marked for destroy", .{});
        self.entries[@intCast(usize, handle)] = .{
            .data = null,
            .size = 0,
            .alignment = 0,
            .status = .{},
        };
    }

    pub fn checkOut(self: *@This(), handle: DatumHandle, checkoutMode: DatumCheckoutMode) !Chit {
        try core.assertf(self.entries[@intCast(usize, handle)].status.pendingDestroy != 1, "tried to check out object but it is pending destroy", .{});
        switch (checkoutMode) {
            .ReadOnly => {
                try core.assertf(self.entries[@intCast(usize, handle)].status.writeCount == 0, "cannot check out object as read, it is being written", .{});
            },
            .ReadWrite => {
                try core.assertf(self.entries[@intCast(usize, handle)].status.readCount == 0, "cannot check out object as read/write, it is being read", .{});
            },
            .Destroy => {
                try core.assertf(self.entries[@intCast(usize, handle)].status.writeCount == 0, "cannot check out object as read, it is being written", .{});
                try core.assertf(self.entries[@intCast(usize, handle)].status.readCount == 0, "cannot check out object as read/write, it is being read", .{});
            },
        }

        switch (checkoutMode) {
            .ReadOnly => {
                self.entries[@intCast(usize, handle)].status.readCount += 1;
            },
            .ReadWrite => {
                self.entries[@intCast(usize, handle)].status.writeCount = 1;
            },
            .Destroy => {
                self.entries[@intCast(usize, handle)].status.pendingDestroy = 1;
            },
        }

        return .{
            .data = self.entries[@intCast(usize, handle)].data.?,
            .size = self.entries[@intCast(usize, handle)].size,
            .alignment = self.entries[@intCast(usize, handle)].alignment,
            .vault = self,
            .mode = checkoutMode,
        };
    }

    pub fn checkIn(self: *@This(), chit: Chit) !void {
        _ = self;
        _ = chit;
    }
};
