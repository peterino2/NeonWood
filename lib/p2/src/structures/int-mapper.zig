const std = @import("std");

// TODO:
//
// This one is not quite finished yet.
//
// The idea for this one is to efficently map one
// arbitrary set of integers to another set of integers.
pub fn IntMapperUnmanaged(comptime IntType: type) type {
    return struct {
        capacity: usize,
        smallMap: []IntType,
    };
}
