// procedural functions to describe input primitives with which
// we can build on the rest of the engine.

const std = @import("std");
const rtti = @import("rtti.zig");

pub const InputSubsystem = struct {
    const Self = @This();
    pub var NeonObjectTable: rtti.RttiData = rtti.RttiData.from(Self);

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        const self = Self{
            .allocator = allocator,
        };

        return self;
    }
};
