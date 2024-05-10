const std = @import("std");
const testcases = @import("testcases.zig");
const test_values = @import("facts/test_values.zig");

test "hmm" {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(testcases);
    std.testing.refAllDecls(test_values);
}
