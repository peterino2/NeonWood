utf8: []const u8,
hash: u32,

pub fn fromUtf8(source: []const u8) @This() {
    var hash: u32 = 5381;

    for (source) |ch| {
        hash = @mulWithOverflow(hash, 33)[0];
        hash = @addWithOverflow(hash, @as(u32, @intCast(ch)))[0];
    }

    var self = .{
        .utf8 = source,
        .hash = hash,
    };
    return self;
}
