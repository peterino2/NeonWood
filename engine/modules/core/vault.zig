const std = @import("std");
const core = @import("../core.zig");

// highly experimental multiprocessing runtime.
//
// Takes over all your allocators and every object that is allocated gets stored into this vault.
//
// You can reference allocations with fat pointers which contain a reference to the allocation and an entry into the library.

pub const Vault = struct {};
