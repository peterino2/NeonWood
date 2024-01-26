const std = @import("std");
const core = @import("core.zig");
const graphics = @import("graphics.zig");

pub const papyrus = @import("ui/papyrus.zig");
pub const NodeHandle = papyrus.NodeHandle;
pub const PapyrusSystem = @import("ui/PapyrusSystem.zig");

var gPapyrus: *PapyrusSystem = undefined;

pub fn getSystem() *PapyrusSystem {
    return gPapyrus;
}

pub fn getContext() *papyrus.Context {
    return gPapyrus.papyrusCtx;
}

pub fn start_module(allocator: std.mem.Allocator) !void {
    _ = allocator;
    gPapyrus = try core.gEngine.createObject(PapyrusSystem, .{ .can_tick = true });
    try gPapyrus.setup(graphics.getContext());
}

pub fn shutdown_module() void {
    gPapyrus.shutdown();
}
