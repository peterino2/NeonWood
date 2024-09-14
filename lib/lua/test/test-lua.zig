const std = @import("std");
const lua = @import("lua");
const pod = lua.pod;
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
    x: f64 = 0,
    y: f64 = 0,
    z: f64 = 0,

    // .name = "Vector",
    pub const PodDataTable: pod.DataTable = .{
        .funcs = &.{"magnitude"},
        .operators = .{
            .add = "add",
            .sub = "sub",
            .mul = "mul",
        },
    };

    // todo, update operator2arg so it accepts any argument for second arg
    pub fn mul(self: Vector, right: f64) Vector {
        return .{
            .x = self.x * right,
            .y = self.y * right,
            .z = self.z * right,
        };
    }

    pub fn add(self: Vector, right: Vector) Vector {
        return .{
            .x = self.x + right.x,
            .y = self.y + right.y,
            .z = self.z + right.z,
        };
    }

    pub fn sub(self: Vector, rhs: Vector) Vector {
        return .{
            .x = self.x - rhs.x,
            .y = self.y - rhs.y,
            .z = self.z - rhs.z,
        };
    }

    pub fn magnitude(self: @This()) f64 {
        return std.math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }
};

pub fn main() !void {
    var luaState = try lua.LuaState.init(.{ .defaultSetup = false });
    defer luaState.deinit();

    try pod.setupFormatBuffer(std.heap.page_allocator);

    try luaState.pushFunction(helloFromZig);
    try luaState.setGlobal("helloZig");

    try luaState.pushZigFunction(addFunc);
    try luaState.setGlobal("addFunc");

    try pod.registerPodType(&luaState, Vector);

    std.debug.print("loading hello world\n", .{});
    try luaState.loadFile("scripts/hello-world.lua");

    try luaState.pcall();

    return;
}
