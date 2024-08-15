pub const c = @import("c.zig").c;
const std = @import("std");

pub const LuaStateSettings = struct {
    defaultSetup: bool = true,
};

pub const LuaCFunc = *const fn (?*c.lua_State) callconv(.C) i32;
pub const LuaZigFunc = *const fn (LuaState) i32;
pub const LibSpec = []const c.luaL_Reg;

pub fn CWrap(comptime Func: anytype) LuaCFunc {
    const Wrap = struct {
        pub fn inner(l: ?*c.lua_State) callconv(.C) i32 {
            return Func(.{ .l = l });
        }
    };

    return Wrap.inner;
}

pub fn FuncWrapper(comptime baseFunc: anytype) type {
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

var gErrorPrinterContext: ?*anyopaque = null;
var errorPrintFunc: ?*const fn (?*anyopaque, []const u8) void = undefined;

pub fn registerLuaErrorPrinter(context: ?*anyopaque, func: *const fn (?*anyopaque, []const u8) void) void {
    errorPrintFunc = func;
    gErrorPrinterContext = context;
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
            const errorString = c.lua_tolstring(self.l, -1, 0);
            if (errorPrintFunc) |printFunc| {
                printFunc(gErrorPrinterContext, std.mem.span(errorString));
            } else {
                std.debug.print("{s}\n", .{errorString});
            }

            return error.LoadFileError;
        }
    }

    pub fn pcall(self: @This()) !void {
        const status = c.lua_pcallk(self.l, 0, 0, 0, 0, null);
        if (status != c.LUA_OK) {
            const errorString = c.lua_tolstring(self.l, -1, 0);
            if (errorPrintFunc) |printFunc| {
                printFunc(gErrorPrinterContext, std.mem.span(errorString));
            } else {
                std.debug.print("{s}\n", .{errorString});
            }
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

    pub fn toUserdata(self: @This(), comptime T: type, index: i32) ?*T {
        return @ptrCast(@alignCast(c.lua_touserdata(self.l, index)));
    }

    pub fn checkString(self: @This(), index: i32) []const u8 {
        return std.mem.span(c.luaL_checklstring(self.l, index, null));
    }

    pub fn checkInteger(self: @This(), index: i32) i32 {
        return @intCast(c.luaL_checkinteger(self.l, index));
    }

    pub fn pushInteger(self: @This(), index: i32) void {
        c.lua_pushinteger(self.l, index);
    }

    pub fn argCheck(self: @This(), condition: bool, index: i32, message: []const u8) !void {
        if (!condition) {
            _ = c.luaL_argerror(self.l, index, message.ptr);
            return error.BadArgument;
        }
    }

    pub fn newLib(self: @This(), lib: LibSpec) !void {
        c.luaL_checkversion(self.l);
        c.lua_createtable(self.l, 0, @as(c_int, @intCast(lib.len)) - 1);
        c.luaL_setfuncs(self.l, lib.ptr, 0);
    }

    pub fn setFuncs(self: @This(), lib: LibSpec, index: i32) !void {
        c.luaL_setfuncs(self.l, lib.ptr, index);
    }

    pub fn newUserdata(self: @This(), comptime T: type) !*T {
        return @ptrCast(@alignCast(c.lua_newuserdata(self.l, @as(c_int, @intCast(@sizeOf(T))))));
    }

    pub fn newMetatable(self: @This(), name: [:0]const u8) !void {
        _ = c.luaL_newmetatable(self.l, name);
    }

    pub fn getMetatable(self: @This(), index: i32) !void {
        if (c.lua_getmetatable(self.l, index) == 0) {
            return error.BadMetatable;
        }
    }

    pub fn getMetatableByName(self: @This(), name: [:0]const u8) !void {
        if (c.luaL_getmetatable(self.l, name) == 0) {
            return error.BadMetatable;
        }
    }

    pub fn setMetatable(self: @This(), index: i32) !void {
        _ = c.lua_setmetatable(self.l, index);
    }

    pub fn pushValue(self: @This(), index: i32) !void {
        _ = c.lua_pushvalue(self.l, index);
    }

    pub fn getField(self: @This(), index: i32, name: [:0]const u8) !void {
        _ = c.lua_getfield(self.l, index, name);
        if (self.isNil(1)) {
            return error.FieldNotFound;
        }
    }

    pub fn isNumber(self: @This(), index: i32) bool {
        const typeIndex = c.lua_type(self.l, index);
        return (typeIndex == c.LUA_TNUMBER);
    }

    pub fn isNil(self: @This(), index: i32) bool {
        const typeIndex = c.lua_type(self.l, index);
        return (typeIndex == c.LUA_TNIL);
    }

    pub fn isTable(self: @This(), index: i32) bool {
        return c.lua_type(self.l, index) == c.LUA_TTABLE;
    }

    pub fn getFieldAsNumber(self: @This(), index: i32, name: [:0]const u8) ?f64 {
        const t = c.lua_getfield(self.l, index, name);
        defer self.pop(1);
        if (t != c.LUA_TNUMBER) {
            return null;
        }
        const n = self.toNumber(self.getTop());
        return n;
    }

    pub fn newZigUserdata(self: @This(), comptime T: type) !*T {
        const rv = try self.newUserdata(T);
        try self.getMetatableByName(T.MetatableName);
        try self.setMetatable(-2);
        return rv;
    }

    // pub fn isType(self: @This(), comptime T: type, index: i32) bool {
    //     const typeIndex = c.lua_type(self.l, index);
    //     switch (T) {
    //         .i32 => {
    //             if (typeIndex == c.LUA_TINTEGER)
    //                 return true;
    //         },
    //         .f64 => {
    //             if (typeIndex == c.LUA_TNUMBER)
    //                 return true;
    //         },
    //         .bool => {
    //             if (typeIndex == c.LUA_TBOOLEAN)
    //                 return true;
    //         },
    //         .Pointer => {
    //             if (typeIndex == c.LUA_TSTRING)
    //                 return true;
    //         },
    //     }
    //     return false;
    // }
};
