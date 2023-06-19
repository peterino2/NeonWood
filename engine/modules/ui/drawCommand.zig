const std = @import("std");

pub const DrawCommand = union(enum(u8)) {
    image: u32, // an index referencing which ssbo we are drawing with
    text: u32, // an index into the textRender buffer. (actual index is unused for now).
};
