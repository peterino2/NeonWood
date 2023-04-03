const std = @import("std");
const PapyrusSystem = @import("ui/papyrusSystem.zig");
const core = @import("core.zig");
const graphics = @import("graphics.zig");

var gPapyrus: *PapyrusSystem = undefined;

pub fn getSystem() *PapyrusSystem {
    return gPapyrus;
}

pub fn start_module(allocator: std.mem.Allocator) !void {
    _ = allocator;
    gPapyrus = try core.gEngine.createObject(PapyrusSystem, .{ .can_tick = true });
    try gPapyrus.setup(graphics.getContext());
}

pub fn shutdown_module() void {
    gPapyrus.deinit();
}
