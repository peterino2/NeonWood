const std = @import("std");
const lua = @import("lua.zig");
const p2 = @import("p2");

// function implementators for types which consist of only
// primitive types
//
// primitive types are:
// - bool => LUA_TBOOL
// - f32, f64, i32, i64, u32, u64 => LUA_TNUMBER
//
// if i exclusively overruse a lot of POD types... lots of copy overhead?
//
// entity = core.newEntity(); // default path (will be named /default/entity_x)
// or
// entity = core.newEntity("/game/landscape");
//
// print(entity)
// entity with <d> components, .{ index = , }
//
// lets do some example code what the fck do i even wnat to do with scripting here...
//
//
// I think the base types such as POD, component and system should be sent over to
// core/scripting.zig
//
// ... stuff like vkImgui should bind as a subsystem.
//
// todo.. subsystem implementation
//

pub fn NewFunc(comptime T: type) lua.LuaCFunc {
    const S = struct {
        pub fn inner(state: lua.LuaState) i32 {
            const argc = state.getTop();
            const newValue: *T = state.newZigUserdata(T) catch return 0;
            newValue.* = .{};

            if (argc == 0) {
                return 1;
            }

            if (argc == 1 and state.isTable(-2)) {
                inline for (std.meta.fields(T)) |field| {
                    if (state.getFieldAsNumber(-2, field.name)) |value| {
                        switch (field.type) {
                            f32 => {
                                @field(newValue.*, field.name) = @as(f32, @floatCast(value));
                            },
                            f64 => {
                                @field(newValue.*, field.name) = value;
                            },
                            i32, i64, u32, u64 => {
                                @field(newValue.*, field.name) = @intFromFloat(value);
                            },
                            []const u8 => {
                                @panic("[] const u8 field not implemented yet");
                            },
                            else => {
                                @panic("unknown type not implemented");
                            },
                        }
                    }
                }
            } else {
                inline for (std.meta.fields(T), 0..) |field, index| {
                    if (argc > index) {
                        switch (field.type) {
                            f32 => {
                                @field(newValue.*, field.name) = @as(f32, @floatCast(state.toNumber(index + 1)));
                            },
                            f64 => {
                                @field(newValue.*, field.name) = state.toNumber(index + 1);
                            },
                            i32, i64, u32, u64 => {
                                @field(newValue.*, field.name) = @intFromFloat(state.toNumber(index + 1));
                            },
                            []const u8 => {
                                @panic("[] const u8 field not implemented yet");
                            },
                            else => {
                                @panic("unknown type not implemented");
                            },
                        }
                    }
                }
            }

            return 1;
        }
    };

    return lua.CWrap(S.inner);
}

pub fn Operator2Arg(comptime T: type, comptime Func: anytype) lua.LuaCFunc {
    const S = struct {
        pub fn inner(state: lua.LuaState) i32 {
            const argc = state.getTop();
            state.argCheck(argc == 2, 1, "expected two arguments for add function") catch return 0;

            const lhs = state.toUserdata(T, 1) orelse return 0;
            const rhs = state.toUserdata(T, 2) orelse return 0;
            const rv = state.newZigUserdata(T) catch return 0;
            rv.* = Func(lhs.*, rhs.*);

            return 1;
        }
    };

    _ = S;

    return lua.WrapZigFunc(Func);
}

var Buffer: std.ArrayList(u8) = undefined;

pub fn setupFormatBuffer(allocator: std.mem.Allocator) !void {
    Buffer = std.ArrayList(u8).init(allocator);
}

pub fn shutdownFormatBuffer() void {
    Buffer.deinit();
}

pub fn ToStringFunc(comptime T: type) lua.LuaCFunc {
    const S = struct {
        pub fn inner(state: lua.LuaState) i32 {
            if (state.toUserdata(T, 1)) |value| {
                Buffer.clearRetainingCapacity();

                var writer = Buffer.writer();
                writer.print("{s}{{", .{T.PodDataTable.name}) catch return 0;

                inline for (std.meta.fields(T), 0..) |field, i| {
                    if (i == 0) {
                        writer.print(" {s} = ", .{field.name}) catch return 0;
                    } else {
                        writer.print(", {s} = ", .{field.name}) catch return 0;
                    }
                    switch (field.type) {
                        f32, i32, u32, f64, i64, u64 => {
                            writer.print("{d}", .{@field(value, field.name)}) catch return 0;
                        },
                        else => {
                            writer.print("<unknown type {s}>", .{@typeName(field.type)}) catch return 0;
                        },
                    }
                }

                writer.print(" }}" ++ "\x00", .{}) catch return 0;
                state.pop(1);
                state.pushString(Buffer.items) catch return 0;
                return 1;
            }

            return 0;
        }
    };

    return lua.CWrap(S.inner);
}

pub const FuncEntry = struct {
    name: []const u8,
    func: lua.LuaCFunc,
};

// BIG todo: get and set are incredibly slow. need to replace with a look-up table.
//
// string hashmap of bindings would be ideal

pub fn GetFunc(comptime T: type, comptime args: struct {
    allowIndices: bool,
}) lua.LuaCFunc {
    const S = struct {
        pub fn inner(state: lua.LuaState) i32 {
            if (state.toUserdata(T, 1)) |v| {
                if (args.allowIndices and state.isNumber(2)) {
                    const index = state.checkInteger(2);
                    state.argCheck(index <= 3, 2, "index out of bounds") catch return 0;

                    inline for (std.meta.fields(T), 1..) |field, i| {
                        if (i == index) {
                            switch (field.type) {
                                i32, u32, i64, u64 => {
                                    state.pushNumber(@floatFromInt(@field(v, field.name)));
                                },
                                f32, f64 => {
                                    state.pushNumber(@floatCast(@field(v, field.name)));
                                },
                                else => {
                                    @panic("unsupported type");
                                },
                            }
                            break;
                        }
                    }
                } else if (state.isString(2)) {
                    const argument = state.toString(2);

                    // check metatable
                    if (state.getMetafield(1, @ptrCast(argument))) {
                        return 1;
                    }

                    inline for (std.meta.fields(T)) |field| {
                        if (std.mem.eql(u8, argument, field.name)) {
                            switch (field.type) {
                                i32, u32, i64, u64 => {
                                    state.pushNumber(@floatFromInt(@field(v, field.name)));
                                },
                                f32, f64 => {
                                    state.pushNumber(@floatCast(@field(v, field.name)));
                                },
                                else => {
                                    @panic("unsupported type");
                                },
                            }
                            return 1;
                        }
                    }

                    // check the custom funcTable
                    // tbh.. I should never use this...
                    inline for (T.PodDataTable.funcs) |fname| {
                        if (std.mem.eql(u8, argument, fname)) {
                            state.pushCFunction(lua.WrapZigFunc(@field(T, fname))) catch return 0;
                            return 1;
                        }
                    }
                }
            } else {
                @panic("called the Get function for the wrong type");
            }

            return 1;
        }
    };

    return lua.CWrap(S.inner);
}

pub fn SetFunc(comptime T: type, comptime args: struct { allowIndices: bool }) lua.LuaCFunc {
    const S = struct {
        pub fn inner(state: lua.LuaState) i32 {
            if (state.toUserdata(T, 1)) |v| {
                if (args.allowIndices and state.isNumber(2)) {
                    const index = state.toNumber(2);
                    inline for (std.meta.fields(T), 1..) |field, i| {
                        if (index == i) {
                            switch (field.type) {
                                i32, u32, i64, u64 => {
                                    @field(v, field.name) = @intFromFloat(state.toNumber(3));
                                },
                                f32, f64 => {
                                    @field(v, field.name) = @floatCast(state.toNumber(3));
                                },
                                else => {
                                    @panic("unsupported type");
                                },
                            }
                            break;
                        }
                    }
                } else if (state.isString(2)) {
                    const argument = state.toString(2);
                    inline for (std.meta.fields(T)) |field| {
                        if (std.mem.eql(u8, argument, field.name)) {
                            switch (field.type) {
                                i32, u32, i64, u64 => {
                                    @field(v, field.name) = @intFromFloat(state.toNumber(3));
                                },
                                f32, f64 => {
                                    @field(v, field.name) = @floatCast(state.toNumber(3));
                                },
                                else => {
                                    @panic("unsupported type");
                                },
                            }
                            break;
                        }
                    }
                }
            }
            return 0;
        }
    };
    return lua.CWrap(S.inner);
}

pub fn funcEntry(comptime name: []const u8, comptime func: anytype) lua.WrapZigFunc {
    return .{ .name = name, .func = lua.WrapZigFunc(func) };
}

pub const DirectFunc = struct {
    name: []const u8,
    func: []const u8,
};

pub const DataTable = struct {
    name: []const u8,
    funcs: []const []const u8 = &.{},
    luaFuncs: []const []const u8 = &.{},
    newFuncOverride: ?lua.LuaCFunc = null,
    toStringOverride: ?lua.LuaCFunc = null,
    banInstantiation: bool = false,
    operators: struct {
        // i've decided I shall not support operator overloading for now
        add: ?[]const u8 = null,
        sub: ?[]const u8 = null,
        mul: ?[]const u8 = null,
        eq: ?[]const u8 = null,
    } = .{},
    luaDirectFuncs: []const DirectFunc = &.{},
};

const PodLib = struct {
    methods: lua.LibSpec,
    functions: lua.LibSpec,
};

pub fn MakeMetatable(comptime T: type) PodLib {
    const methods = blk: {
        comptime var m: lua.LibSpec = &.{};
        if (T.PodDataTable.toStringOverride != null) {
            m = m ++ .{.{ .name = "__tostring", .func = comptime T.PodDataTable.toStringOverride.? }};
        } else {
            m = m ++ .{.{ .name = "__tostring", .func = comptime ToStringFunc(T) }};
        }
        m = m ++ .{.{ .name = "__newindex", .func = comptime SetFunc(T, .{ .allowIndices = true }) }};
        m = m ++ .{.{ .name = "__index", .func = comptime GetFunc(T, .{ .allowIndices = true }) }};

        if (T.PodDataTable.operators.add) |f| {
            m = m ++ .{.{ .name = "__add", .func = comptime Operator2Arg(T, @field(T, f)) }};
        }
        if (T.PodDataTable.operators.sub) |f| {
            m = m ++ .{.{ .name = "__sub", .func = comptime Operator2Arg(T, @field(T, f)) }};
        }
        if (T.PodDataTable.operators.mul) |f| {
            m = m ++ .{.{ .name = "__mul", .func = comptime Operator2Arg(T, @field(T, f)) }};
        }
        if (T.PodDataTable.operators.eq) |f| {
            m = m ++ .{.{ .name = "__eq", .func = comptime Operator2Arg(T, @field(T, f)) }};
        }

        inline for (T.PodDataTable.funcs) |f| {
            m = m ++ .{.{ .name = @as([*c]const u8, @ptrCast(f)), .func = comptime lua.WrapZigFunc(@field(T, f)) }};
        }

        inline for (T.PodDataTable.luaFuncs) |f| {
            m = m ++ .{.{ .name = @as([*c]const u8, @ptrCast(f)), .func = @field(T, f) }};
        }

        inline for (T.PodDataTable.luaDirectFuncs) |f| {
            m = m ++ .{.{ .name = @as([*c]const u8, @ptrCast(f.name)), .func = comptime lua.CWrap(@field(T, f.func)) }};
        }

        break :blk m ++ .{.{ .name = null, .func = null }};
    };

    const functions = blk: {
        comptime var m: lua.LibSpec = &.{};
        if (!T.PodDataTable.banInstantiation) {
            if (T.PodDataTable.newFuncOverride != null) {
                m = m ++ .{lua.c.luaL_Reg{ .name = "new", .func = comptime T.PodDataTable.newFuncOverride.? }};
            } else {
                m = m ++ .{lua.c.luaL_Reg{ .name = "new", .func = comptime NewFunc(T) }};
            }
        }
        break :blk m ++ .{.{ .name = null, .func = null }};
    };
    return .{ .methods = methods, .functions = functions };
}

pub fn registerPodType(luaState: *lua.LuaState, comptime T: type) !void {
    const Metatable = MakeMetatable(T);

    // walk through and generate index registry for all methods and fields.
    try luaState.newMetatable(@ptrCast(T.PodDataTable.name));
    try luaState.setFuncs(Metatable.methods, 0);
    try luaState.newLib(Metatable.functions);
    try luaState.setGlobal(T.PodDataTable.name);
}
