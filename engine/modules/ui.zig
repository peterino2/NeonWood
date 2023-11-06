const std = @import("std");
const PapyrusSystem = @import("ui/papyrusSystem.zig");
const core = @import("core.zig");
const graphics = @import("graphics.zig");

pub usingnamespace @import("ui/papyrus/PapyrusEvent.zig");

pub const papyrus = PapyrusSystem.papyrus;

pub const PapyrusContext = papyrus.PapyrusContext;

pub const NodeHandle = papyrus.NodeHandle;

var gPapyrus: *PapyrusSystem = undefined;

pub fn getSystem() *PapyrusSystem {
    return gPapyrus;
}

pub fn getContext() *papyrus.PapyrusContext {
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
