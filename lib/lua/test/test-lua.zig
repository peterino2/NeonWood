const std = @import("std");
const lua = @import("lua");
const c = lua.c;

const CLuaState = ?*c.lua_State;

// sample engine function
fn helloFromZig(state: lua.LuaState) i32 {
    _ = state;
    std.debug.print("hello from zig \n", .{});
    return 0;
}

fn addFunc(a: f64, b: f64) f64 {
    std.debug.print("> a{d} b{d} \n", .{ a, b });
    return a + b;
}

var formatBuffer: [4096]u8 = undefined;

const Vector = extern struct {
    x: f64,
    y: f64,
    z: f64,

    pub const MetatableName = "Vector";

    pub fn lua_new(state: lua.LuaState) i32 {
        const argc = state.getTop();
        const newVector: *Vector = state.newUserdata(Vector) catch return 0;

        state.getMetatableByName(MetatableName) catch return 0;
        state.setMetatable(-2) catch {
            return 0;
        };

        newVector.x = 0;
        newVector.y = 0;
        newVector.z = 0;

        if (argc == 0) {
            return 1;
        }

        if (argc == 1 and state.isTable(-2)) {
            // do table initialization

            inline for (.{ "x", "y", "z" }) |x| {
                if (state.getFieldAsNumber(-2, x)) |value| {
                    @field(newVector, x) = value;
                }
            }
        } else {
            if (argc >= 1) {
                newVector.x = state.toNumber(1);
            }
            if (argc >= 2) {
                newVector.y = state.toNumber(2);
            }
            if (argc >= 3) {
                newVector.z = state.toNumber(3);
            }
        }

        return 1;
    }

    pub fn lua_size(state: lua.LuaState) i32 {
        if (state.toUserdata(@This(), 1) == null) {
            state.argCheck(false, 1, "expected type 'Vector'") catch return 0;
        }
        state.pushInteger(3);
        return 1;
    }

    pub fn lua_get(state: lua.LuaState) i32 {
        if (state.toUserdata(Vector, 1)) |v| {
            if (state.isNumber(2)) {
                const index = state.checkInteger(2);
                state.argCheck(index <= 3, 2, "index out of bounds") catch return 0;

                if (index == 1) {
                    state.pushNumber(v.x);
                } else if (index == 2) {
                    state.pushNumber(v.y);
                } else if (index == 3) {
                    state.pushNumber(v.z);
                }
            } else if (state.isString(2)) {
                const argument = state.toString(2);

                if (std.mem.eql(u8, argument, "magnitude")) {
                    state.pushFunction(@This().lua_magnitude) catch return 0;
                    return 1;
                }
            }
        }
        return 1;
    }

    pub fn lua_set(state: lua.LuaState) i32 {
        if (state.toUserdata(Vector, 1)) |v| {
            const index = state.checkInteger(2);
            const setValue = state.toNumber(3);
            state.argCheck(index <= 3, 2, "index out of bounds") catch return 0;

            if (index == 1) {
                v.x = setValue;
            } else if (index == 2) {
                v.y = setValue;
            } else if (index == 3) {
                v.z = setValue;
            }
        }
        return 0;
    }

    pub fn lua_toString(l: CLuaState) callconv(.C) i32 {
        const maybe: ?*Vector = @ptrCast(@alignCast(c.lua_touserdata(l, 1)));

        if (maybe) |v| {
            const str = std.fmt.bufPrint(
                &formatBuffer,
                "Vector{{ .x = {d}, .y = {d}, .z = {d} }}",
                .{ v.x, v.y, v.z },
            ) catch return 0;

            c.lua_pop(l, 1);
            _ = c.lua_pushlstring(l, str.ptr, str.len);
            return 1;
        } else {
            std.debug.print("error: expected vector", .{});
            return 0;
        }
        return 0;
    }

    pub fn add(self: Vector, right: Vector) Vector {
        return .{
            .x = self.x + right.x,
            .y = self.y + right.y,
            .z = self.z + right.z,
        };
    }

    pub fn lua_add(state: lua.LuaState) i32 {
        const argc = state.getTop();
        state.argCheck(argc == 2, 1, "expected two arguments for add functio ") catch return 0;

        const left = state.toUserdata(Vector, 1) orelse return 0;
        const right = state.toUserdata(Vector, 2) orelse return 0;
        const rv = state.newZigUserdata(Vector) catch return 0;
        rv.* = left.add(right.*);

        return 1;
    }

    pub fn magnitude(self: @This()) f64 {
        return std.math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    pub fn lua_magnitude(state: lua.LuaState) i32 {
        if (state.toUserdata(Vector, 1)) |v| {
            state.pushNumber(v.magnitude());
            return 1;
        } else {
            state.argCheck(false, 1, "expected 'Vector' object") catch return 0;
            return 0;
        }
    }
};

const vector_methods: lua.LibSpec = &.{
    .{ .name = "__tostring", .func = Vector.lua_toString },
    .{ .name = "__newindex", .func = lua.CWrap(Vector.lua_set) },
    .{ .name = "__index", .func = lua.CWrap(Vector.lua_get) },
    .{ .name = "__add", .func = lua.CWrap(Vector.lua_add) },
    .{ .name = "__len", .func = lua.CWrap(Vector.lua_size) },
    .{ .name = "magnitude", .func = lua.CWrap(Vector.lua_magnitude) },
    .{ .name = null, .func = null },
};

const vector_functions: lua.LibSpec = &.{
    .{ .name = "new", .func = lua.CWrap(Vector.lua_new) },
    .{ .name = "mag", .func = lua.CWrap(Vector.lua_magnitude) },
    .{ .name = null, .func = null },
};

pub fn main() !void {
    var luaState = try lua.LuaState.init(.{ .defaultSetup = false });
    defer luaState.deinit();

    try luaState.pushFunction(helloFromZig);
    try luaState.setGlobal("helloZig");

    try luaState.pushZigFunction(addFunc);
    try luaState.setGlobal("addFunc");

    try luaState.newMetatable(Vector.MetatableName);
    try luaState.setFuncs(vector_methods, 0);
    try luaState.newLib(vector_functions);
    try luaState.setGlobal("vector");

    std.debug.print("loading hello world\n", .{});
    try luaState.loadFile("scripts/hello-world.lua");

    try luaState.pcall();

    return;
}
