// procedural functions to describe input primitives with which
// we can build on the rest of the engine.

const std = @import("std");
const engineObject = @import("engineObject.zig");

pub const InputSubsystem = struct {
    const Self = @This();
    pub var NeonObjectTable: engineObject.RttiData = engineObject.RttiData.from(Self);

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        const self = Self{
            .allocator = allocator,
        };

        return self;
    }
};
