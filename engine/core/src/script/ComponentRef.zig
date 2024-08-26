// lwdt can't have meta tables so this doesn't quite work as well.
// meanwhile... impedance mismatch of doing a full decode
// anytime we want to rmw values can be quite bad...
//
// solution: a self-resolvable fatpointer that can resolve differences

pub fn ComponentReferenceType(comptime T: type) type {
    return struct {
        ptr: *anyopaque = undefined,

        // used for resolving deltas.
        handle: core.ObjectHandle = undefined,
        stateCount: u32 = 0,
        containerRef: ecs.ContainerRef = undefined,

        const MetatableName = T.ComponentName;

        // argc = 1,
        // 1. a componentRegistration userdata
        pub fn luaNew(state: lua.LuaState) i32 {
            const ud = state.newZigUserdata(@This());
            _ = ud;

            return 1;
        }

        pub fn luaIndex(state: lua.LuaState) i32 {
            _ = state;

            return 0;
        }

        pub fn registerType(state: lua.LuaState) !void {
            core.engine_log("creating lua metatable {s}", .{MetatableName});

            const methods = blk: {
                comptime var m: lua.LibSpec = &.{};
                m = m ++ .{.{ .name = "__index", .func = lua.CWrap(luaIndex) }};
                break :blk m ++ .{.{ .name = null, .func = null }};
            };

            try state.newMetatable(@ptrCast(MetatableName));
            try state.setFuncs(methods, 0);
        }
    };
}

const core = @import("../core.zig");
const ecs = @import("../ecs.zig");
const lua = @import("lua");
