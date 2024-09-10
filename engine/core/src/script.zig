// scripting integration using lua

const std = @import("std");
const lua = @import("lua");
const core = @import("core.zig");
const startup_script = @embedFile("lua/startup.lua");
const ecs = @import("ecs.zig");
const ComponentRef = @import("script/ComponentRef.zig");
const ComponentRegistration = @import("script/ComponentRegistration.zig");

const script_bindings = @import("script_bindings.zig");

const c = lua.c;

var gLuaState: lua.LuaState = undefined;
var gLuaAllocator: std.mem.Allocator = undefined;

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
            const s = state.toStringL(i);
            state.pop(1);
            core.printRaw("{s}", .{s});
        }
    }

    core.printRaw("\n", .{});
    state.pop(argc);

    return 0;
}

// initialization of the lua scripting interface.
// this interface is only threadsafe to operate on from the main systems thread (at this time).
pub fn start_lua(allocator: std.mem.Allocator) !void {
    gLuaAllocator = allocator;
    gLuaState = try lua.LuaState.init(.{});
    try lua.pod.setupFormatBuffer(allocator);

    // overload and hook into global functions
    _ = gLuaState.getGlobal("_G");
    c.luaL_setfuncs(gLuaState.l, luaRegLibs.ptr, 0);
    gLuaState.pop(1);

    try lua.pod.registerPodType(&gLuaState, ecs.Entity);
    try lua.pod.registerPodType(&gLuaState, ComponentRegistration);

    try script_bindings.registerTypes();

    try gLuaState.loadString(startup_script);
    try gLuaState.pcall();
}

pub fn createLuaComponentDefinitions(globalName: []const u8, container: ecs.EcsContainerRef, luaNew: anytype) !void {
    const reg = try gLuaState.newZigUserdata(ComponentRegistration);
    reg.ref = container;
    reg.name = globalName;
    reg.luaNew = luaNew;
    try gLuaState.setGlobal(globalName);
}

pub fn registerComponent(comptime Component: type, container: ecs.EcsContainerRef) !void {
    const ReferenceType = ComponentRef.ComponentReferenceType(Component);
    try createLuaComponentDefinitions(@ptrCast(Component.ComponentName), container, ReferenceType.luaNew);
    try ReferenceType.registerType(getState());
}

pub fn shutdown_lua() void {
    lua.pod.shutdownFormatBuffer();
    gLuaState.deinit();
}

pub fn getState() *lua.LuaState {
    return &gLuaState;
}

fn findScriptBasepath(s: []const u8) []const u8 {
    var i: usize = s.len - 1;

    while (i > 0) : (i -= 1) {
        if (s[i] == '\\' or s[i] == '/') {
            break;
        }
    }

    if (s[i] == '\\' or s[i] == '/') {
        return s[i + 1 ..];
    }

    return s;
}

pub fn loadTypes(scriptPath: []const u8) !void {
    // 1. scan filesystem for all files under the script path
    var fileList = try core.fs().listAllSubpaths(gLuaAllocator, scriptPath);
    defer fileList.deinit();
    for (fileList.data.items, 0..) |f, i| {
        // 2. enforce naming scheme for each script.
        const basePath = findScriptBasepath(f);

        // core.engine_log("checking script file: {s} path:{s} base {s}", .{ f, fileList.sources.items[i], basePath });
        // 3. for each one, load the script and assign them based on name.
        if (std.ascii.isUpper(basePath[0])) {
            core.engine_log("loading script file: {s} path:{s}", .{ f, fileList.sources.items[i] });
            const scriptFile = try core.fs().loadFile(f);
            defer core.fs().unmap(scriptFile);
            try gLuaState.loadString(scriptFile.bytes);
            try gLuaState.pcall();
        }
    }
}

pub fn runScriptFile(scriptPath: []const u8) !void {
    const scriptFile = try core.fs().loadFile(scriptPath);
    defer core.fs().unmap(scriptFile);
    try gLuaState.loadString(scriptFile.bytes);
    try gLuaState.pcall();
}
