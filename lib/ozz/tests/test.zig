const ozz = @import("ozz");
const std = @import("std");

test "helloWorld" {
    ozz.hello();
    ozz.startupOzz();
    defer ozz.shutdownOzz();

    // load an ozz file
}
