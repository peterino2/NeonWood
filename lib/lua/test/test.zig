const std = @import("std");
const lua = @import("lua");

// sample engine function

pub fn main() !void {
    var luaState = try lua.LuaState.init(.{});
    defer luaState.deinit();

    try luaState.loadFile("scripts/hello-world.lua");

    try luaState.pcall();

    return;
}
