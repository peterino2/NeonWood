const logging = @import("logging.zig");
const log = logging.test_log;
const logs = logging.test_logs;
const test_setup = logging.test_setup;

test "logging" {
    const misc = @import("misc.zig");
    const count = misc.count;
    const range = misc.range;

    _ = count;
    _ = range;

    test_setup();
    logs("Test logging baybe");

    for (count(9)) |_, i| {
        log("count: {}", .{i});
    }
    logs("Running test for range");

    inline for (comptime range(9, 12)) |i| {
        log("range(9, 12): {}", .{i});
    }
}
