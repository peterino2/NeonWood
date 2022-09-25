const std = @import("std");

// todo need a better timing system than this
pub fn getEngineTime() f64 {
    return @intToFloat(f64, std.time.milliTimestamp()) / 1000;
}

// return the current system timestamp in nanoseconds
pub fn getEngineTimeStamp() i128 {
    return std.time.nanoTimestamp();
}
