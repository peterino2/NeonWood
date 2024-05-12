backingAllocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
inputEvents: std.AutoHashMapUnmanaged(NodeHandle, std.ArrayListUnmanaged(Listener)),
pressEvents: std.AutoHashMapUnmanaged(NodeHandle, std.ArrayListUnmanaged(PressedListener)),

const std = @import("std");
const papyrus = @import("papyrus.zig");

const NodeHandle = papyrus.NodeHandle;
const Context = papyrus.Context;

const RingQueueU = core.RingQueueU;

const core = @import("core");
const assertf = core.assertf;

pub const Key = enum(i32) {
    Unknown = -1,
    Space = 32,
    Apostrophe = 39,
    Comma = 44,
    Period = 45,
    Slash = 47,
    @"0" = 48,
    @"1" = 49,
    @"2" = 50,
    @"3" = 51,
    @"4" = 52,
    @"5" = 53,
    @"6" = 54,
    @"7" = 55,
    @"8" = 56,
    @"9" = 57,
    Semicolon = 59,
    Equal = 61,
    A = 65,
    B = 66,
    C = 67,
    D = 68,
    E = 69,
    F = 70,
    G = 71,
    H = 72,
    I = 73,
    J = 74,
    K = 75,
    L = 76,
    M = 77,
    N = 78,
    O = 79,
    P = 80,
    Q = 81,
    R = 82,
    S = 83,
    T = 84,
    U = 85,
    V = 86,
    W = 87,
    X = 88,
    Y = 89,
    Z = 90,
    LeftBrackSq = 91,
    BackSlash = 92,
    RightBrackSq = 93,
    Mouse1 = 10001,
    Mouse2 = 10002,
    Mouse3 = 10003,
    Mouse4 = 10004,
    Mouse5 = 10005,
    _,
};

pub const Type = enum {
    mouseOver,
    mouseOff,
};

pub const PressedType = enum {
    onPressed,
    onReleased,
};

pub const HandlerError = error{
    UnknownError,
    EventPanic,
    EventDropped,
    EventIgnored,
};

pub const SingleFn = *const fn (NodeHandle, ?*anyopaque) HandlerError!void;
pub const PressedFn = *const fn (NodeHandle, PressedType, ?*anyopaque) HandlerError!void;

const Listener = struct {
    node: NodeHandle,
    event: Type,
    context: ?*anyopaque,
    eventFn: SingleFn,
    innate: bool,
};

const PressedListener = struct {
    node: NodeHandle,
    keycode: Key,
    event: PressedType,
    context: ?*anyopaque,
    eventFn: PressedFn,
    innate: bool,
};

pub fn installMouseOverEventAdvanced(
    self: *@This(),
    node: NodeHandle,
    event: Type,
    context: ?*anyopaque,
    eventFn: SingleFn,
    innate: bool,
) !void {
    const allocator = self.arena.allocator();

    const listener: Listener = .{
        .node = node,
        .event = event,
        .context = context,
        .eventFn = eventFn,
        .innate = innate,
    };

    if (self.inputEvents.getPtr(node)) |listenerList| {
        try listenerList.append(allocator, listener);
    } else {
        var newListenerList: std.ArrayListUnmanaged(Listener) = .{};
        try newListenerList.append(allocator, listener);
        try self.inputEvents.put(allocator, node, newListenerList);
    }
}

pub fn installMouseOverEvent(
    self: *@This(),
    node: NodeHandle,
    event: Type,
    context: ?*anyopaque,
    eventFn: SingleFn,
) !void {
    try installMouseOverEventAdvanced(self, node, event, context, eventFn, false);
}

pub fn pushMouseOverEvent(self: *@This(), node: NodeHandle, event: Type) HandlerError!void {
    if (self.inputEvents.get(node)) |listeners| {
        for (listeners.items) |listener| {
            if (listener.event == event) {
                try listener.eventFn(node, listener.context);
            }
        }
    }
}

pub fn pushPressedEvent(self: *@This(), node: NodeHandle, event: PressedType, keycode: Key) !void {
    if (self.pressEvents.get(node)) |listeners| {
        for (listeners.items) |listener| {
            if (listener.event == event and keycode == listener.keycode) {
                try listener.eventFn(node, event, listener.context);
            }
        }
    }
}

pub fn installOnPressedEventAdvanced(self: *@This(), node: NodeHandle, event: PressedType, keycode: Key, context: ?*anyopaque, eventFn: PressedFn, innate: bool) !void {
    const listener: PressedListener = .{
        .node = node,
        .event = event,
        .keycode = keycode,
        .context = context,
        .eventFn = eventFn,
        .innate = innate,
    };

    const allocator = self.arena.allocator();

    if (self.pressEvents.getPtr(node)) |listenerList| {
        try listenerList.append(allocator, listener);
    } else {
        var newListenerList: std.ArrayListUnmanaged(PressedListener) = .{};
        try newListenerList.append(allocator, listener);
        try self.pressEvents.put(allocator, node, newListenerList);
    }
}

pub fn installOnPressedEvent(self: *@This(), node: NodeHandle, event: PressedType, keycode: Key, context: ?*anyopaque, eventFn: PressedFn) !void {
    try installOnPressedEventAdvanced(self, node, event, keycode, context, eventFn, false);
}

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{
        .backingAllocator = allocator,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .inputEvents = .{},
        .pressEvents = .{},
    };
}

pub fn deinit(self: *@This()) void {
    self.arena.deinit();
}

pub fn uninstallAllEvents(self: *@This(), node: NodeHandle) !void {
    try self.uninstallPressEvents(node);
    try self.uninstallBasicEvents(node);
}

pub fn uninstallPressEvents(self: *@This(), node: NodeHandle) !void {
    if (self.pressEvents.contains(node)) {
        const allocator = self.arena.allocator();
        var newList = std.ArrayListUnmanaged(PressedListener){};
        var items = self.pressEvents.get(node).?;
        for (items.items) |i| {
            if (i.innate) {
                try newList.append(allocator, i);
            }
        }
        try self.pressEvents.put(allocator, node, newList);
        items.deinit(allocator);
    }
}

pub fn uninstallBasicEvents(self: *@This(), node: NodeHandle) !void {
    if (self.inputEvents.contains(node)) {
        const allocator = self.arena.allocator();
        var newList = std.ArrayListUnmanaged(Listener){};
        var items = self.inputEvents.get(node).?;
        for (items.items) |i| {
            if (i.innate) {
                try newList.append(allocator, i);
            }
        }
        try self.inputEvents.put(allocator, node, newList);
        items.deinit(allocator);
    }
}

// a more extreme version of uninstallAllEvents that purges even builtin events
pub fn uninstallAllEvents_OnDestroy(self: *@This(), node: NodeHandle) void {
    _ = self.inputEvents.remove(node);
    _ = self.pressEvents.remove(node);
}
