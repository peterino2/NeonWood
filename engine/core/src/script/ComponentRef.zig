// lwdt can't have meta tables so I'm going to create component references
//
// the way this works is
// - entities are created as POD types
// - entities can get components added to them via entity:addComponent
// - this returns a ComponentReference
// - you can also get components from an entity via enity:get()
// - this also returns a ComponentReference
//
// - ComponentReferences allow you to modify data on a component or call functions on them
//
//
// How the registration works
//
// - define component
//  - ecs.zig defineComponent
//      - ComponentRef.zig - ReferenceType
//      - addComponentRegistration - script.zig
//      - ComponentRef - ReferenceType.registerType

// this represents the lua side of the object
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

            // std.debug.print("luaNew ComponentReferenceType: {x}\n", .{@intFromPtr(ud)});
            // std.debug.print("luaNew ContainerRef: {x}\n", .{@intFromPtr(containerRef.ptr)});
            // std.debug.print("luaNew " ++ @typeName(T) ++ " ud.ptr = {x}\n", .{@intFromPtr(ptr)});

            if (ptr) |p| {
                ud.ptr = @ptrCast(@alignCast(p));
                ud.stateCount = containerRef.vtable.getStateCount(containerRef.ptr);
            }

            if (@hasDecl(@TypeOf(T.BaseContainer.*), "IsMultiset")) {
                // ... there are several things that need to be reworked here...
                ud.ptr = @ptrCast(@alignCast(@as(*anyopaque, @ptrCast(&ud.handle))));
                // std.debug.print("luaNew " ++ @typeName(T) ++ " v = {any}\n", .{ud.ptr.getPosition()});
            }
        }

        pub fn resolve(self: *@This()) void {
            const ref = self.containerRef;
            // std.debug.print("self: {x}\n", .{@intFromPtr(self)});
            // std.debug.print("ptr: {x}\n", .{@intFromPtr(ref.ptr)});
            if (@hasDecl(@TypeOf(T.BaseContainer.*), "IsMultiset")) {
                //
            }
            if (ref.vtable.getStateCount(ref.ptr) != self.stateCount) {
                self.ptr = @ptrCast(@alignCast(ref.vtable.get(ref.ptr, self.handle)));
            }
        }

        pub fn get(self: *@This()) *T {
            self.resolve();
            return self.ptr;
        }

        pub fn luaToString(state: lua.LuaState) i32 {
            // oh god... this isn't good
            // I think i've been treating this component ref as the user type
            // huge failure of type resolution
            if (state.toUserdata(@This(), 1)) |self| {
                self.resolve();
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
                            writer.print("{d}", .{@field(self.ptr, field.name)}) catch return 0;
                        },
                        []const u8 => {
                            writer.print("\"{s}\"", .{@field(self.ptr, field.name)}) catch return 0;
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
            if (state.toUserdata(@This(), 1)) |self| {
                if (state.isString(2)) {
                    _ = self;
                    const argument = state.toString(2);
                    // core.engine_log(@typeName(@This()) ++ " got indexed. 0x{x}", .{self.handle.index});

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

                break :blk m ++ .{.{ .name = null, .func = null }};
            };

            return methods;
        }

        pub fn registerType(state: *lua.LuaState) !void {
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
                    // I'll be honest how the hell does this work?
                    //
                    // the pointer being passed in here isn't the actual resulting type...
                    // it's the reference type
                    *baseType => {
                        const ref = state.toUserdata(ComponentReferenceType(baseType), index + 1).?;
                        ref.resolve();
                        args[index] = ref.ptr;
                    },
                    baseType => {
                        const ref = state.toUserdata(ComponentReferenceType(baseType), index + 1).?;
                        ref.resolve();
                        args[index] = ref.ptr.*;
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
const scene = @import("../scene.zig");
