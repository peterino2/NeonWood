pub const InputStack = struct {
    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        return self;
    }
};

pub fn initInputStack() !void {}

const std = @import("std");
