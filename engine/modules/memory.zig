// memory tracker

pub const MemoryTracker = @import("memory/MemoryTracker.zig");

pub const setupMemTracker = MemoryTracker.setup;
pub const shutdownMemTracker = MemoryTracker.shutdown;
pub const getMemTracker = MemoryTracker.get;
