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
            state.pushString("component reference") catch return 0;
            return 1;
        }

        pub fn luaIndex(state: lua.LuaState) i32 {
            _ = state;
            core.engine_log(@typeName(T) ++ " got indexed.", .{});

            return 0;
        }

        fn makeTypeTable() lua.LibSpec {
            const methods = blk: {
                comptime var m: lua.LibSpec = &.{};
                m = m ++ .{.{ .name = "__index", .func = lua.CWrap(luaIndex) }};
                m = m ++ .{.{ .name = "__tostring", .func = lua.CWrap(luaToString) }};

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

const core = @import("../core.zig");
const ecs = @import("../ecs.zig");
const lua = @import("lua");
