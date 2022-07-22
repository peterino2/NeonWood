const std = @import("std");

pub fn getEngineTime() f64 {
    return @floatCast(f64, std.time.nanoTimestamp()) / 1000000000;
}
