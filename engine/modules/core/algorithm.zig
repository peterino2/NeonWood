const std = @import("std");

const ArrayList = std.ArrayList;

pub fn AppendToArrayListUnique(list: anytype, value: anytype) !void {
    for (list.items) |v| {
        if (v == value)
            return;
    }

    try list.append(value);
}
