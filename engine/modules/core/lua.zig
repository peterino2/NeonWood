const std = @import("std");

const c = @cImport({
    @cInclude("lua.h");
    @cInclude("lualib.h");
    @cInclude("lauxlib.h");
});

pub fn test_lua() !void {
    var L = c.luaL_newstate();
    defer c.lua_close(L);

    c.luaL_openlibs(L);

    if (c.luaL_loadstring(L, "print('Hello world from lua')") == c.LUA_OK) {
        if (c.lua_pcallk(L, 0, 0, 0, 0, null) == c.LUA_OK) {
            c.lua_pop(L, c.lua_gettop(L));
        }
    }
}
