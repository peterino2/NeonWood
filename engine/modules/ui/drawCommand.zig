const std = @import("std");

pub const DrawCommand = union(enum(u8)) {
    image: struct {
        index: u32,
    },
    text: struct {
        index: u32,
        small: bool,
    },
};
