const std = @import("std");

const core = @import("core.zig");
const graphics = @import("graphics.zig");

pub const AssetReference = struct {
    name: core.Name,
    path: []const u8,
};
