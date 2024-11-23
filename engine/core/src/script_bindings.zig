const luaRegLibs: []const lua.c.luaL_Reg = &.{
    .{ .name = "registerTick", .func = lua.CWrap(registerTick) },
    .{ .name = null, .func = null },
};

// register core types and subsystems into the scripting engine
pub fn registerTypes() !void {
    // transform POD type

    const state = script.getState();
    try lua.pod.registerPodType(state, core.Vector);
    try lua.pod.registerPodType(state, core.Vectorf);
    try lua.pod.registerPodType(state, core.Vector2);
    try lua.pod.registerPodType(state, core.Vector2f);
    // try lua.pod.registerPodType(state, core.Transform);

    // lua.pod.registerPodType(state, core.Vector4, "Vector4");
    try state.createLibrary("Systems", luaRegLibs);
}

pub fn registerTick(l: lua.LuaState) i32 {
    // two arguments first one is going to be userdata entity
    // second one is going to be a lua function.
    _ = l;
    return 0;
}

pub const ScriptTicks = struct {
    allocator: std.mem.Allocator,

    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
        };
        return self;
    }

    pub fn tick(self: *@This(), deltaTime: f64) void {
        _ = self;
        const state = script.getState();
        _ = state.getGlobal("__TickScripts");
        state.pushNumber(deltaTime);
        state.pcallStack(1) catch {
            core.engine_logs("could not execute lua script");
        };
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

const lua = @import("lua");
const std = @import("std");
const script = @import("script.zig");
const core = @import("core.zig");
