const std = @import("std");
const lua = @import("lua");
const c = lua.c;

// sample engine function
fn helloFromZig(state: lua.LuaState) i32 {
    _ = state;
    std.debug.print("hello from zig \n", .{});
    return 0;
}

fn addFunc(a: f64, b: f64) f64 {
    std.debug.print("> a{d} b{d} \n", .{ a, b });
    return a + b;
}

pub fn main() !void {
    var luaState = try lua.LuaState.init(.{ .defaultSetup = false });
    defer luaState.deinit();

    try luaState.pushFunction(helloFromZig);
    try luaState.setGlobal("helloZig");

    try luaState.pushZigFunction(addFunc);
    try luaState.setGlobal("addFunc");

    try luaState.loadFile("scripts/hello-world.lua");

    try luaState.pcall();

    return;
}
