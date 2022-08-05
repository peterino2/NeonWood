const std = @import("std");

pub const Name = struct {
    utf8: []const u8,
    hash: u32,

    pub fn fromUtf8(source: []const u8) Name {
        const hashFunc = std.hash.CityHash32.hash;

        var self = .{
            .utf8 = source,
            .hash = hashFunc(source),
        };
        return self;
    }
};

pub fn MakeName(comptime utf8: []const u8) Name {
    return comptime Name.fromUtf8(utf8);
}
