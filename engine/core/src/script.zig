// scripting integration using lua

const std = @import("std");
const lua = @import("lua");
const core = @import("core.zig");
const startup_script = @embedFile("lua/startup.lua");
const ecs = @import("ecs.zig");
const ComponentRegistration = @import("script/ComponentRegistration.zig");

const c = lua.c;

var gLuaState: lua.LuaState = undefined;

const luaRegLibs: []const c.luaL_Reg = &.{
    .{ .name = "print", .func = printWrapper },
    .{ .name = null, .func = null },
};

// binds the default print() function in lua to print to the console
fn printWrapper(l: ?*lua.c.lua_State) callconv(.C) i32 {
    const state: lua.LuaState = .{ .l = l };
    const argc = state.getTop();

    if (core.getLogger() == null) {
        core.printRaw("> ", .{});
    }

    if (argc >= 1) {
        core.printRaw("[SCRIPT   ]: ", .{});
    }

    var i: i32 = 1;
    while (i <= argc) : (i += 1) {
        if (state.isString(i)) {
            if (i > 1) {
                core.printRaw(" ", .{});
            }
            core.printRaw("{s}", .{state.toString(i)});
        } else if (state.isUserdata(i)) {
            core.printRaw("userdata: [todo]", .{});
        }
    }

    core.printRaw("\n", .{});
    state.pop(argc);

    return 0;
}

// initialization of the lua scripting interface.
// this interface is only threadsafe to operate on from the main systems thread (at this time).
pub fn start_lua() !void {
    gLuaState = try lua.LuaState.init(.{});

    // overload and hook into global functions
    _ = gLuaState.getGlobal("_G");
    c.luaL_setfuncs(gLuaState.l, luaRegLibs.ptr, 0);
    gLuaState.pop(1);

    try lua.pod.registerPodType(&gLuaState, ecs.Entity);
    try lua.pod.registerPodType(&gLuaState, ComponentRegistration);

    try gLuaState.loadString(startup_script);
    try gLuaState.pcall();
}

pub fn addComponentRegistration(globalName: []const u8, container: ecs.EcsContainerRef) !void {
    const reg = try gLuaState.newZigUserdata(ComponentRegistration);
    reg.ref = container;
    reg.name = globalName;
    try gLuaState.setGlobal(globalName);
}

pub fn shutdown_lua() void {
    gLuaState.deinit();
}

pub fn getState() lua.LuaState {
    return gLuaState;
}

pub fn runScriptFile(scriptPath: []const u8) !void {
    const scriptFile = try core.fs().loadFile(scriptPath);
    defer core.fs().unmap(scriptFile);
    try gLuaState.loadString(scriptFile.bytes);
    try gLuaState.pcall();
}
