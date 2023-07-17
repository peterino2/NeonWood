const std = @import("std");
const papyrus = @import("papyrus.zig");

const RingQueueU = papyrus.RingQueueU;
pub const PapyrusKeyboardEvent = struct {
    keycode: i32,
    state: enum { keydown, keyup },
};

pub const PapyrusEventBus = struct {
    keyboardEvents: RingQueueU(PapyrusKeyboardEvent),
};
