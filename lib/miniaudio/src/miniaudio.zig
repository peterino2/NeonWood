const c = @cImport({
    @cInclude("miniaudio.h");
});

const std = @import("std");

test "miniaudio-compile-check" {
    try std.testing.expect(c.MA_VERSION_MAJOR == 0);
    try std.testing.expect(c.MA_VERSION_MINOR == 11);

    var engine: c.ma_engine = undefined;
    const result = c.ma_engine_init(null, &engine);
    c.ma_engine_uninit(&engine);

    try std.testing.expect(result == c.MA_SUCCESS);
}
