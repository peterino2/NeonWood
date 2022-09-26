const core = @import("../core.zig");

pub const AssetReference = struct {
    name: core.Name,
    path: []const u8,
};
