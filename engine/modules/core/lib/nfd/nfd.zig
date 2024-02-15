pub const c = @cImport({
    @cInclude("nfd.h");
});

const std = @import("std");

pub const nfdContext = struct {
    pub fn init(allocator: std.mem.Allocator) *@This() {
        _ = allocator;
    }
};
