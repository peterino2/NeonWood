pub const BindingType = enum(u8) {
    action,
    axis1d,
    axis2d,
};

const glfw_release = 0;

pub const IOEvent = union(enum(u8)) {
    windowFocused: struct { focused: c_int },
    mousePosition: struct { x: f64, y: f64 },
    mouseButton: struct { button: c_int, action: c_int, mods: c_int },
    scroll: struct { xoffset: f64, yoffset: f64 },
    key: struct { key: c_int, scancode: c_int, action: c_int, mods: c_int },
    windowResize: struct { newSize: core.Vector2f },
    codepoint: c_uint,
};

pub const ActionEvent = enum(u8) {
    keyUp,
    keyDown,
    keyHeld,
};

pub const ActionBindingKey = struct {
    key: Key,
    event: ActionEvent = .keyDown,
};

fn arenaAlloc() std.mem.Allocator {
    return gInputStack.arena.allocator();
}

fn BindingData(Listener: type, Func: type) type {
    return struct {
        keysDown: KeysDownQueue,
        keysUp: std.ArrayListUnmanaged(Key) = .{},
        listeners: std.ArrayListUnmanaged(Listener) = .{},
        consumed: bool = false,
        routed: bool = false,
        count: u32 = 0,
        name: core.Name,

        pub const KeysDownQueue = core.RingQueueU(struct { key: Key, first: bool = true });

        pub fn init(name: core.Name) @This() {
            return .{
                .name = name,
                .keysDown = KeysDownQueue.init(arenaAlloc(), 256) catch unreachable,
            };
        }

        pub fn addListener(self: *@This(), ctx: ?*anyopaque, func: Func) u32 {
            const allocator = arenaAlloc();
            self.listeners.append(allocator, .{ .id = self.count, .ctx = ctx, .func = func }) catch unreachable;
            self.count +%= 1;

            return self.count;
        }

        pub fn removeListener(self: *@This(), id: u32) void {
            for (self.listeners.items.len, 0..) |listener, i| {
                if (listener.id == id) {
                    self.listeners.swapRemove(i);
                    return;
                }
            }
        }

        pub fn setKeyDown(self: *@This(), key: Key) void {
            self.keysDown.push(.{ .key = key, .first = true }) catch unreachable;
        }

        pub fn setKeyHeld(self: *@This(), key: Key) void {
            // core.engine_log("repeating key {any}", .{key});
            self.keysDown.push(.{ .key = key, .first = false }) catch unreachable;
        }

        pub fn setKeyUp(self: *@This(), key: Key) void {
            self.keysUp.append(arenaAlloc(), key) catch unreachable;
        }

        pub fn deinit(self: *@This()) void {
            self.keysDown.deinit(arenaAlloc());
            self.listeners.deinit(arenaAlloc());
        }
    };
}

pub const ActionBinding = struct {
    data: BindingData(Listener, ActionFunc),
    keys: std.ArrayListUnmanaged(ActionBindingKey) = .{},

    pub const Listener = struct {
        id: u32,
        ctx: ?*anyopaque,
        func: ActionFunc,
    };

    pub fn create(name: core.Name) !*@This() {
        const allocator = arenaAlloc();
        const self = try allocator.create(@This());

        self.* = .{
            .data = BindingData(Listener, ActionFunc).init(name),
        };

        return self;
    }
    // pushes this binding to the active layer
    pub fn activate(self: *@This()) void {
        gInputStack.active.addBindingByName(self.data.name, self) catch unreachable;
    }

    pub fn deactivate(self: *@This()) void {
        gInputStack.active.removeBindingByName(self.data.name);
    }

    pub fn addKey(self: *@This(), key: Key, event: ActionEvent) void {
        const allocator = arenaAlloc();
        self.keys.append(allocator, .{ .key = key, .event = event }) catch unreachable;
    }

    pub fn deinit(self: *@This()) void {
        const allocator = arenaAlloc();
        self.data.deinit();
        self.keys.deinit(allocator);
    }
};

pub const ActionFunc = *const fn (?*anyopaque, ActionEvent) void;

pub const AxisBindingKeyMagnitude = struct {
    key: Key,
    magnitude: f32 = 1.0,
};

pub const Axis1dFunc = *const fn (?*anyopaque, f32) void;

pub const Axis1dBinding = struct {
    data: BindingData(Listener, Axis1dFunc),
    keys: std.ArrayListUnmanaged(AxisBindingKeyMagnitude) = .{},
    magnitude: f32 = 0.0,

    pub const Listener = struct {
        id: u32,
        ctx: ?*anyopaque,
        func: Axis1dFunc,
    };

    pub fn create(name: core.Name) !*@This() {
        const allocator = arenaAlloc();
        const self = try allocator.create(@This());

        self.* = .{
            .data = BindingData(Listener, Axis1dFunc).init(name),
        };

        return self;
    }

    // pushes this binding to the active layer
    pub fn activate(self: *@This()) void {
        gInputStack.active.addBindingByName(self.data.name, self) catch unreachable;
    }

    pub fn deactivate(self: *@This()) void {
        gInputStack.active.removeBindingByName(self.data.name);
    }

    pub fn addKey(self: *@This(), key: Key, magnitude: f32) void {
        const allocator = arenaAlloc();
        self.keys.append(allocator, .{ .key = key, .magnitude = magnitude }) catch unreachable;
    }

    pub fn deinit(self: *@This()) void {
        const allocator = arenaAlloc();
        self.data.deinit();
        self.keys.deinit(allocator);
        self.listeners.deinit(allocator);
    }
};

pub const Axis2dFunc = *const fn (?*anyopaque, core.Vector2f) void;
pub const Axis2dBinding = struct {
    data: BindingData(Listener, Axis2dFunc),
    yKeys: std.ArrayListUnmanaged(AxisBindingKeyMagnitude) = .{},
    xKeys: std.ArrayListUnmanaged(AxisBindingKeyMagnitude) = .{},

    magnitude: core.Vector2f = core.Vector2f.Zeroes,

    pub const Listener = struct {
        id: u32,
        ctx: ?*anyopaque,
        func: Axis2dFunc,
    };

    pub fn create(name: core.Name) !*@This() {
        const allocator = arenaAlloc();
        const self = try allocator.create(@This());

        self.* = .{
            .data = BindingData(Listener, Axis2dFunc).init(name),
        };

        return self;
    }

    // pushes this binding to the active layer
    pub fn activate(self: *@This()) void {
        gInputStack.active.addBindingByName(self.data.name, self) catch unreachable;
    }

    pub fn deactivate(self: *@This()) void {
        gInputStack.active.removeBindingByName(self.data.name);
    }

    pub fn addKey(self: *@This(), key: Key, magnitude: f32, axis: enum { x, y }) void {
        const allocator = arenaAlloc();
        switch (axis) {
            .x => {
                self.xKeys.append(allocator, .{ .key = key, .magnitude = magnitude }) catch unreachable;
            },
            .y => {
                self.yKeys.append(allocator, .{ .key = key, .magnitude = magnitude }) catch unreachable;
            },
        }
    }

    pub fn deinit(self: *@This()) void {
        const allocator = arenaAlloc();
        self.xKeys.deinit(allocator);
        self.yKeys.deinit(allocator);
        self.data.deinit();
    }
};

pub const Binding = union(BindingType) {
    action: *ActionBinding,
    axis1d: *Axis1dBinding,
    axis2d: *Axis2dBinding,

    pub fn setKeyDown(self: @This(), key: Key) void {
        switch (self) {
            .action => |p| {
                p.data.setKeyDown(key);
            },
            .axis1d => |p| {
                p.data.setKeyDown(key);
            },
            .axis2d => |p| {
                p.data.setKeyDown(key);
            },
        }
    }

    pub fn setKeyHeld(self: @This(), key: Key) void {
        switch (self) {
            .action => |p| {
                p.data.setKeyHeld(key);
            },
            .axis1d => |p| {
                p.data.setKeyHeld(key);
            },
            .axis2d => |p| {
                p.data.setKeyHeld(key);
            },
        }
    }

    pub fn setKeyUp(self: @This(), key: Key) void {
        switch (self) {
            .action => |p| {
                p.data.setKeyUp(key);
            },
            .axis1d => |p| {
                p.data.setKeyUp(key);
            },
            .axis2d => |p| {
                p.data.setKeyUp(key);
            },
        }
    }

    pub fn sendAxisUpdates(self: @This()) void {
        switch (self) {
            .action => {},
            .axis1d => |p| {
                p.data.routed = false;
                for (p.data.listeners.items) |listener| {
                    listener.func(listener.ctx, p.magnitude);
                }
                p.magnitude = 0.0;
            },
            .axis2d => |p| {
                p.data.routed = false;
                for (p.data.listeners.items) |listener| {
                    listener.func(listener.ctx, p.magnitude);
                }
                p.magnitude = core.Vector2f.Zeroes;
            },
        }
    }

    pub fn routeBindingEvent(self: @This(), key: Key, event: ActionEvent, consumedOut: *bool) bool {
        var consumed: bool = false;
        var routed: bool = false;
        switch (self) {
            .action => |p| {
                for (p.keys.items) |keyBinding| {
                    if (keyBinding.key == key and event == keyBinding.event) {
                        consumed = p.data.consumed;
                        routed = true;
                    }
                }

                if (routed) {
                    for (p.data.listeners.items) |listener| {
                        listener.func(listener.ctx, event);
                    }
                }

                p.data.routed = routed;
            },
            .axis1d => |p| {
                for (p.keys.items) |keyBinding| {
                    if (keyBinding.key == key and (event == .keyDown or event == .keyHeld)) {
                        p.magnitude += keyBinding.magnitude;
                        consumed = p.data.consumed;
                        routed = true;
                    }
                }

                p.magnitude = std.math.clamp(p.magnitude, -1.0, 1.0);

                p.data.routed = routed;
                // for (p.data.listeners.items) |listener| {
                //     listener.func(listener.ctx, magnitude);
                // }
            },
            .axis2d => |p| {
                for (p.xKeys.items) |keyBinding| {
                    if (keyBinding.key == key and (event == .keyDown or event == .keyHeld)) {
                        p.magnitude.x += keyBinding.magnitude;
                        consumed = p.data.consumed;
                        routed = true;
                    }
                }

                for (p.yKeys.items) |keyBinding| {
                    if (keyBinding.key == key and (event == .keyDown or event == .keyHeld)) {
                        p.magnitude.y += keyBinding.magnitude;
                        consumed = p.data.consumed;
                        routed = true;
                    }
                }

                p.magnitude.x = std.math.clamp(p.magnitude.x, -1.0, 1.0);
                p.magnitude.y = std.math.clamp(p.magnitude.y, -1.0, 1.0);

                // for (p.data.listeners.items) |listener| {
                //     listener.func(listener.ctx, p.magnitude);
                // }
                p.data.routed = routed;
            },
        }

        consumedOut.* = consumed;

        return routed;
    }

    fn processKeysHeldDown(self: @This(), p: anytype) void {
        const keysCount = p.data.keysDown.count();

        var i: usize = 0;
        while (i < keysCount) : (i += 1) {
            const keydown = p.data.keysDown.pop().?;
            var isKeyUp: bool = false;

            for (p.data.keysUp.items) |up| {
                if (up == keydown.key) {
                    isKeyUp = true;
                    break;
                }
            }
            var consumed: bool = false;

            if (!isKeyUp and !keydown.first) {
                _ = self.routeBindingEvent(keydown.key, .keyHeld, &consumed);
            }

            if (!isKeyUp) {
                p.data.setKeyHeld(keydown.key);
            }
        }

        p.data.keysUp.clearRetainingCapacity();
    }

    pub fn processHeldKeys(self: @This()) void {
        switch (self) {
            .action => |p| {
                self.processKeysHeldDown(p);
            },
            .axis1d => |p| {
                self.processKeysHeldDown(p);
            },
            .axis2d => |p| {
                self.processKeysHeldDown(p);
            },
        }
    }

    pub fn releaseKeys(self: @This()) void {
        switch (self) {
            .action => |p| {
                p.keysDown.clearRetainingCapacity();
            },
            .axis1d => |p| {
                p.keysDown.clearRetainingCapacity();
            },
            .axis2d => |p| {
                p.keysDown.clearRetainingCapacity();
            },
        }
    }
};

pub const BindingLayer = struct {
    allocator: std.mem.Allocator,

    bindingsByName: std.AutoHashMapUnmanaged(u32, u32) = .{},
    bindingStack: std.ArrayListUnmanaged(Binding) = .{},

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .allocator = allocator,
        };

        return self;
    }

    pub fn addBindingByName(self: *@This(), _name: core.Name, new: anytype) !void {
        var name = _name;
        if (self.bindingsByName.contains(name.handle())) {
            self.removeBindingByName(name);
        }
        try self.bindingsByName.put(self.allocator, name.handle(), @intCast(self.bindingStack.items.len));

        var newBinding: Binding = undefined;

        switch (@TypeOf(new)) {
            *ActionBinding => {
                newBinding = .{ .action = new };
            },
            *Axis1dBinding => {
                newBinding = .{ .axis1d = new };
            },
            *Axis2dBinding => {
                newBinding = .{ .axis2d = new };
            },
            else => {
                @panic("uh oh");
            },
        }

        try self.bindingStack.append(self.allocator, newBinding);
    }

    pub fn removeBindingByName(self: *@This(), _name: core.Name) void {
        var name = _name;
        _ = self.bindingStack.orderedRemove(self.bindingsByName.get(name.handle()).?);
        _ = self.bindingsByName.remove(name.handle());
    }

    pub fn destroy(self: *@This()) void {
        self.bindingsByName.deinit(self.allocator);
        self.bindingStack.deinit(self.allocator);
        self.allocator.destroy(self);
    }
};

// not gonna actually deal with layers right now
pub const InputStack = struct {
    allocator: std.mem.Allocator,

    active: *BindingLayer,
    arena: std.heap.ArenaAllocator,

    keysDown: std.AutoHashMapUnmanaged(Key, bool) = .{},

    pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{
            .allocator = allocator,
            .arena = std.heap.ArenaAllocator.init(allocator),
            .active = try BindingLayer.create(allocator),
        };

        gInputStack = self;

        return self;
    }

    pub fn updatePreviousInputs(self: *@This()) void {
        if (self.active.bindingStack.items.len == 0) {
            return;
        }

        var i: i32 = @intCast(self.active.bindingStack.items.len - 1);
        while (i >= 0) : (i -= 1) {
            const binding = &self.active.bindingStack.items[@intCast(i)];
            binding.processHeldKeys();
        }
    }

    pub fn sendAxisUpdates(self: *@This()) void {
        for (self.active.bindingStack.items) |binding| {
            binding.sendAxisUpdates();
        }
    }

    fn routeKeyEvent(self: *@This(), key: Key, event: ActionEvent) void {
        // for all bindings in reverse order from this layer, route the input, stop the
        // route if the input was consumed
        if (self.active.bindingStack.items.len == 0) {
            return;
        }

        var i: i32 = @intCast(self.active.bindingStack.items.len - 1);
        while (i >= 0) : (i -= 1) {
            const binding = self.active.bindingStack.items[@intCast(i)];
            var consumed: bool = false;
            var routed: bool = false;

            if (binding.routeBindingEvent(key, event, &consumed)) {
                routed = true;
            }

            if (event == .keyDown) {
                binding.setKeyDown(key);
            }
            if (event == .keyHeld) {
                binding.setKeyHeld(key);
            }
            if (event == .keyUp) {
                binding.setKeyUp(key);
            }

            if (consumed) {
                break;
            }
        }
    }

    pub fn routeEvent(self: *@This(), eventToRoute: IOEvent) void {
        switch (eventToRoute) {
            .key => |key| {
                const keyEvent: ActionEvent = @enumFromInt(@as(u8, @intCast(key.action)));
                if (keyEvent != .keyHeld) {
                    self.routeKeyEvent(@enumFromInt(key.key), keyEvent);
                }
            },
            else => {},
        }
    }

    pub fn deinit(self: *@This()) void {
        self.arena.deinit();
        self.active.destroy();
        self.allocator.destroy(self);
    }
};

var gInputStack: *InputStack = undefined;

pub fn getInputStack() *InputStack {
    return gInputStack;
}

pub fn initInputStack() !void {
    gInputStack = try core.createObject(InputStack, .{});
}

// creates a binding for a lua type
// TODO
// pub fn LuaBinding(comptime T: type, comptime typeName: []const u8) type {
//     return struct {
//         p: ?*T,
//
//         pub const PodDataTable = pod.DataTable{
//             .name = typeName,
//             .funcs = &.{},
//         };
//
//         pub fn create() @This() {
//             return .{};
//         }
//     };
// }

const lua = core.lua;
const pod = lua.pod;

const Key = @import("keys.zig").Key;
const std = @import("std");
const core = @import("../core.zig");
