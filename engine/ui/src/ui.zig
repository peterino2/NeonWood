const std = @import("std");
const core = @import("core");
const graphics = @import("graphics");
const memory = core.MemoryTracker;

pub const papyrus = @import("papyrus");
pub const HandlerError = papyrus.HandlerError;
pub const NodeHandle = papyrus.NodeHandle;
pub const LocText = papyrus.LocText;
pub const PressedType = papyrus.PressedType;
pub const PapyrusSystem = @import("PapyrusIntegration.zig");

var gPapyrus: *PapyrusSystem = undefined;

pub const Module: core.ModuleDescription = .{
    .name = "ui",
    .enabledByDefault = true,
};

pub fn getSystem() *PapyrusSystem {
    return gPapyrus;
}

pub fn getContext() *papyrus.Context {
    return gPapyrus.papyrusCtx;
}

pub fn start_module(comptime programSpec: anytype, args: anytype, allocator: std.mem.Allocator) !void {
    _ = args;
    _ = programSpec;
    _ = allocator;
    gPapyrus = try core.gEngine.createObject(PapyrusSystem, .{ .can_tick = true });
    try gPapyrus.setup(graphics.getContext());
    core.engine_logs("ui start_module");
    memory.MTPrintStatsDelta();
}

pub fn shutdown_module(allocator: std.mem.Allocator) void {
    _ = allocator;
    // gPapyrus.shutdown();
}
