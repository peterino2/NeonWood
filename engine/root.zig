pub const neonwood = @import("modules/neonwood.zig");

const realMain = @import("main");

pub fn main() !void {
    try realMain.main();
}
