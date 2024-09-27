allocator: std.mem.Allocator,

pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

pub fn init(allocator: std.mem.Allocator) !*@This() {
    const self = try allocator.create(@This());
    self.* = .{
        .allocator = allocator,
    };
    return self;
}

pub fn prepare_game(self: *@This()) !void {
    _ = self;
    try core.fs().addContentPath("empty");
    try script.loadTypes("scripts");
    try script.runScriptFile("scripts/prepare.lua");
}

pub fn tick(self: *@This(), _: f64) void {
    _ = self;
}

pub fn deinit(self: *@This()) void {
    self.allocator.destroy(self);
}

pub fn main() anyerror!void {
    try neonwood.initializeAndRunStandardProgram(@This(), .{
        .name = "Hello World",
    });
}

const std = @import("std");
const neonwood = @import("NeonWood");
const core = neonwood.core;
const script = core.script;
