// lwdt can't have meta tables so this doesn't quite work as well.
// meanwhile... impedance mismatch of doing a full decode
// anytime we want to rmw values can be quite bad...
//
// solution: a self-resolvable fatpointer that can resolve differences

pub fn ComponentReferenceType(comptime T: type) type {
    return struct {
        ptr: *T = undefined,

        // used for resolving deltas.
        handle: core.ObjectHandle = undefined,
        stateCount: u32 = 0,
        containerRef: ecs.EcsContainerRef = undefined,

        pub const MetatableName = T.ComponentName;

        // argc = 1,
        // 1. a componentRegistration userdata
        // can only be called from entity.luaAddComponent
        pub fn luaNew(state: lua.LuaState, handle: core.ObjectHandle, ptr: ?*anyopaque) void {
            const ud = state.newZigUserdata(@This()) catch return;
            const containerRef = ecs.getTypeContainer(T);

            ud.* = .{
                .handle = handle,
                .containerRef = containerRef,
                .stateCount = 0,
            };

            if (ptr) |p| {
                ud.ptr = @ptrCast(@alignCast(p));
                ud.stateCount = containerRef.vtable.getStateCount(containerRef.ptr);
            }
        }

        pub fn get(self: *@This()) *T {
            const ref = self.containerRef;
            if (ref.vtable.getStateCount(ref.ptr) != self.stateCount) {
                self.ptr = self.containerRef.vtable.get(self.handle);
            }
            return self.ptr;
        }

        pub fn luaToString(state: lua.LuaState) i32 {
            if (state.toUserdata(T, 1)) |value| {
                Buffer.clearRetainingCapacity();

                var writer = Buffer.writer();
                writer.print("{s}{{", .{MetatableName}) catch return 0;

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
                        []const u8 => {
                            writer.print("\"{s}\"", .{@field(value, field.name)}) catch return 0;
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

        pub fn luaIndex(state: lua.LuaState) i32 {
            if (state.toUserdata(T, 1)) |v| {
                _ = v;
                if (state.isString(2)) {
                    const argument = state.toString(2);
                    core.engine_log(@typeName(T) ++ " got indexed.", .{});
                    // check metatable
                    if (state.getMetafield(1, @ptrCast(argument))) {
                        return 1;
                    }
                }
            }

            return 0;
        }

        fn makeTypeTable() lua.LibSpec {
            const methods = blk: {
                comptime var m: lua.LibSpec = &.{};
                m = m ++ .{.{ .name = "__index", .func = lua.CWrap(luaIndex) }};
                m = m ++ .{.{ .name = "__tostring", .func = lua.CWrap(luaToString) }};

                inline for (T.ScriptExports) |name| {
                    m = m ++ .{.{ .name = @as([*c]const u8, @ptrCast(name)), .func = ComponentFuncWrapper(@field(T, name), T) }};
                }

                // todo: generate function here like FuncWrapper
                break :blk m ++ .{.{ .name = null, .func = null }};
            };

            return methods;
        }

        pub fn registerType(state: lua.LuaState) !void {
            core.engine_log("creating lua metatable {s}", .{MetatableName});

            const methods = comptime makeTypeTable();

            try state.newMetatable(@ptrCast(MetatableName));
            try state.setFuncs(methods, 0);
        }
    };
}

pub fn ComponentFuncWrapper(comptime baseFunc: anytype, comptime baseType: type) lua.LuaCFunc {
    return lua.CWrap(FuncWrapper(baseFunc, baseType).wrapper);
}

pub fn FuncWrapper(comptime baseFunc: anytype, comptime baseType: type) type {
    return struct {
        pub fn wrapper(state: lua.LuaState) i32 {
            const Args = std.meta.ArgsTuple(@TypeOf(baseFunc));

            var args: Args = undefined;
            inline for (std.meta.fields(Args), 0..) |field, index| {
                // std.debug.print("typename = {s}\n", .{@typeName(field.type)});
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
                    []const u8 => {
                        args[index] = state.toString(index + 1);
                    },
                    *baseType => {
                        args[index] = state.toUserdata(baseType, index + 1).?;
                    },
                    baseType => {
                        args[index] = state.toUserdata(baseType, index + 1).?.*;
                    },
                    else => {
                        args[index] = state.toUserdata(field.type, index + 1).?.*;
                    },
                }
            }
            state.pop(@intCast(args.len));

            const rv = @call(.always_inline, baseFunc, args);
            switch (@TypeOf(rv)) {
                i32, u32, i64, u64 => {
                    state.pushNumber(@floatFromInt(rv));
                },
                f32, f64 => {
                    state.pushNumber(@floatCast(rv));
                },
                void => {
                    return 0;
                },
                else => {
                    const ud = state.newZigUserdata(@TypeOf(rv)) catch @panic("not implemented");
                    ud.* = rv;
                },
            }

            return 1;
        }
    };
}

var Buffer: std.ArrayList(u8) = undefined;

pub fn setupFormatBuffer(allocator: std.mem.Allocator) !void {
    Buffer = std.ArrayList(u8).init(allocator);
}
pub fn shutdownFormatBuffer() void {
    Buffer.deinit();
}

const std = @import("std");
const core = @import("../core.zig");
const ecs = @import("../ecs.zig");
const lua = @import("lua");
const pod = lua.pod;
