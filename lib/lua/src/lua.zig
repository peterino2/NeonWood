pub const c = @import("c.zig").c;
const std = @import("std");

pub const LuaStateSettings = struct {
    defaultSetup: bool = true,
};

pub const LuaCFunc = *const fn (?*c.lua_State) callconv(.C) i32;
pub const LuaZigFunc = *const fn (LuaState) i32;

fn FuncWrapper(comptime baseFunc: anytype) type {
    return struct {
        pub fn wrapper(state: LuaState) i32 {
            const Args = std.meta.ArgsTuple(@TypeOf(baseFunc));

            var args: Args = undefined;
            inline for (std.meta.fields(Args), 0..) |field, index| {
                switch (field.type) {
                    f32 => {
                        args[index] = @as(f32, @floatCast(state.toNumber(index + 1)));
                    },
                    f64 => {
                        args[index] = state.toNumber(index + 1);
                    },
                    i32 => {
                        args[index] = @intFromFloat(state.toNumber(index + 1));
                    },
                    else => {
                        @panic("not implemented");
                    },
                }
            }
            state.pop(@intCast(args.len));

            const rv = @call(.always_inline, baseFunc, args);
            state.pushNumber(rv);

            return 1;
        }
    };
}

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
            // TODO: get rid of the IO library instead load in my own version of the io library.
            // math and some other stuff too we'll need to figure out.
            self.openLibs();
            self.useGenerationalGC();
        } else {
            self.stopGC();
            // TODO: get rid of the IO library instead load in my own version of the io library.
            // math and some other stuff too we'll need to figure out.
            self.openLimited();
            self.useGenerationalGC();
        }

        return self;
    }

    pub fn deinit(self: @This()) void {
        c.lua_close(self.l);
    }

    pub fn openLimited(self: @This()) void {
        c.open_limitedio_libs(self.l);
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

    pub fn pushFunction(self: @This(), comptime func: LuaZigFunc) !void {
        const Wrap = struct {
            pub fn inner(l: ?*c.lua_State) callconv(.C) i32 {
                return func(.{ .l = l });
            }
        };
        _ = c.lua_pushcfunction(self.l, Wrap.inner);
    }

    pub fn pushCFunction(self: @This(), comptime func: LuaCFunc) !void {
        _ = c.lua_pushcfunction(self.l, func);
    }

    pub fn setGlobal(self: @This(), value: []const u8) !void {
        _ = c.lua_setglobal(self.l, value.ptr);
    }

    pub fn toNumber(self: @This(), index: i32) f64 {
        return c.lua_tonumberx(self.l, index, null);
    }

    pub fn pop(self: @This(), count: i32) void {
        c.lua_pop(self.l, count);
    }

    pub fn pushNumber(self: @This(), number: f64) void {
        c.lua_pushnumber(self.l, number);
    }

    pub fn pushZigFunction(self: @This(), func: anytype) !void {
        try self.pushFunction(FuncWrapper(func).wrapper);
    }

    pub fn toString(self: @This(), index: i32) []const u8 {
        const cstr = c.lua_tolstring(self.l, index, null);
        const len = std.mem.len(cstr);

        return cstr[0..len];
    }

    pub fn isString(self: @This(), index: i32) bool {
        return c.lua_isstring(self.l, index) > 0;
    }

    pub inline fn getGlobal(self: @This(), definition: []const u8) i32 {
        return c.lua_getglobal(self.l, definition.ptr);
    }

    pub inline fn getTop(self: @This()) i32 {
        return c.lua_gettop(self.l);
    }

    pub fn loadString(self: @This(), string: []const u8) !void {
        const status = c.luaL_loadstring(self.l, string.ptr);
        if (status != c.LUA_OK) {
            return error.LuaRuntimeError;
        }
    }
};
