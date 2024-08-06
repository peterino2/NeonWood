const c = @import("c.zig").c;

pub const LuaStateSettings = struct {
    defaultSetup: bool = true,
};

pub const LuaState = struct {
    l: ?*c.lua_State = null,

    pub fn init(settings: LuaStateSettings) !@This() {
        const self: @This() = .{
            .l = c.luaL_newstate(),
        };

        if (self.l == null) {
            return error.OutOfMemory;
        }

        if (settings.defaultSetup) {
            self.stopGC();
            self.openLibs();
            self.useGenerationalGC();
        }

        return self;
    }

    pub fn deinit(self: @This()) void {
        c.lua_close(self.l);
    }

    pub fn openLibs(self: @This()) void {
        c.luaL_openlibs(self.l);
    }

    pub fn stopGC(self: @This()) void {
        _ = c.lua_gc(self.l, c.LUA_GCSTOP);
    }

    pub fn useGenerationalGC(self: @This()) void {
        _ = c.lua_gc(self.l, c.LUA_GCRESTART);
        _ = c.lua_gc(self.l, c.LUA_GCGEN, @as(u32, @intCast(0)), @as(u32, @intCast(0)));
    }

    pub fn loadFile(self: @This(), filename: []const u8) !void {
        const status = c.luaL_loadfilex(self.l, filename.ptr, null);
        if (status != c.LUA_OK) {
            return error.LoadFileError;
        }
    }

    pub fn pcall(self: @This()) !void {
        const status = c.lua_pcallk(self.l, 0, 0, 0, 0, null);
        if (status != c.LUA_OK) {
            return error.LuaRuntimeError;
        }
    }
};
