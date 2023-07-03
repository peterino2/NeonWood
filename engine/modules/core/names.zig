const std = @import("std");

pub const Name = struct {
    utf8: []const u8,
    hash: u32,

    pub fn fromUtf8(source: []const u8) Name {
        var hash: u32 = 5381;

        for (source) |c| {
            hash = @mulWithOverflow(hash, 33)[0];
            hash = @addWithOverflow(hash, @as(u32, @intCast(c)))[0];
        }

        var self = .{
            .utf8 = source,
            .hash = hash,
        };
        return self;
    }
};

pub fn MakeName(comptime utf8: []const u8) Name {
    @setEvalBranchQuota(100000);
    return comptime Name.fromUtf8(utf8);
}
