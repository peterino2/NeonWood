const std = @import("std");
const lua = @import("lua.zig");

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
                return 0;
            }

            if (argc == 1 and state.isTable(-2)) {
                inline for (std.meta.fields(T)) |field| {
                    if (state.getFieldAsNumber(-2, field.name)) |value| {
                        @field(newValue.*, field.name) = value;
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

pub fn AddFunc(comptime T: type, comptime Func: anytype) lua.LuaCFunc {
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

    return lua.CWrap(S.inner);
}

var Buffer: std.ArrayList(u8) = undefined;

pub fn setupFormatBuffer(allocator: std.mem.Allocator) !void {
    Buffer = std.ArrayList(u8).init(allocator);
}

pub fn ToStringFunc(comptime T: type) lua.LuaCFunc {
    const S = struct {
        pub fn inner(state: lua.LuaState) i32 {
            if (state.toUserdata(T, 1)) |value| {
                Buffer.clearRetainingCapacity();

                var writer = Buffer.writer();
                writer.print("{s}{{", .{T.MetatableName}) catch return 0;

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
                            writer.print("<unknown type {s}>", .{field.typeName}) catch return 0;
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

//pub fn IndexFunc() lua.LuaCFunc {}
//pub fn NewIndexFunc() lua.LuaCFunc {}

//math operator
//pub fn AddFunc() lua.LuaCFunc {}
//pub fn SubtractFunc() lua.LuaCFunc {}
//pub fn DivideFunc() lua.LuaCFunc {}
//pub fn MultiplyFunc() lua.LuaCFunc {}
