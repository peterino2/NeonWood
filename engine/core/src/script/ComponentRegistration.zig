ref: ecs.EcsContainerRef = undefined,
name: []const u8 = undefined,
luaNew: *const fn (state: lua.LuaState, core.ObjectHandle, ?*anyopaque) void = undefined,

pub const PodDataTable: pod.DataTable = .{
    .name = "ComponentRegistration",
    .banInstantiation = true,
    .toStringOverride = lua.CWrap(toString),
};

// I should really move all the registration to this file.
pub fn toString(state: lua.LuaState) i32 {
    var workBuffer: [256]u8 = undefined;
    const ud = state.toUserdata(@This(), 1).?;
    state.pop(1);
    const str = std.fmt.bufPrintZ(&workBuffer, "Component Data Table: {s} 0x{x}", .{ ud.name, ud.ref.ptr }) catch return 0;
    state.pushString(str) catch return 0;
    return 1;
}

pub fn createComponent(self: @This(), handle: core.ObjectHandle) ?*anyopaque {
    const ref = self.ref;
    const rv = ref.vtable.createWithHandle(ref.ptr, handle);
    // std.debug.print("createComponent: {p}\n", .{rv});

    return rv;
}

const lua = @import("lua");
const ecs = @import("../ecs.zig");
const std = @import("std");
const core = @import("../core.zig");
const pod = lua.pod;
