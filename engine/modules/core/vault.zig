const std = @import("std");

// This is 'vault' an experimental runtime multiprocessing library
// The goal is to provide runtime concurrency guarantees to the rest of the libraries within neonwood.

// Inspired by Destiny's multithreaded engine implementation
// and by rust's borrow checker.

// A vault is a concurrent data base which contains handles to allocated objects.

// Handles can be registered into a vault, then checked out

pub const HandleType = u32;
pub const VaultHandleTombstoneValue = 0;

pub const DatumHandle = u32;

pub const DatumStatus = struct {
    readCount: u7 = 0,
    writeCount: bool = 0,
};

pub const Datum = struct {
    data: ?*anyopaque,
    size: usize,
    alignment: usize,
    status: DatumStatus,
};

pub const DatumCheckoutMode = enum {
    ReadOnly,
    ReadWrite,
};

// A chit is returned from a checkout operation.
pub const Chit = struct {
    data: *anyopaque,
    size: usize,
    alignment: usize,
    handle: DatumHandle,
    mode: DatumCheckoutMode,
};

pub const Vault = struct {
    mutex: std.Thread.Mutex = .{},
    allocator: std.mem.Allocator, // backed allocator
    entries: []Datum,

    pub fn acquireLock(self: *@This()) void {
        self.mutex.lock();
        self.mutex.unlock();
    }

    pub fn createAndCheckout(comptime ObjectType: type) !Chit {
        _ = ObjectType;
    }

    pub fn checkOut(comptime ObjectType: type, handle: DatumHandle) !Chit {
        _ = ObjectType;
        _ = handle;
    }
};
