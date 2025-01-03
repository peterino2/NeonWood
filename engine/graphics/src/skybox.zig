pub fn MakeCubeMapList(
    comptime down: []const u8,
    comptime left: []const u8,
    comptime right: []const u8,
    comptime forward: []const u8,
    comptime back: []const u8,
) []const []const u8 {
    return &.{ down, left, right, forward, back };
}

pub const CubeMapDirs = enum(u8) {
    up,
    down,
    left,
    right,
    forward,
    back,
};
