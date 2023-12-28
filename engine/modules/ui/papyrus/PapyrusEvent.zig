const std = @import("std");
const papyrus = @import("papyrus.zig");

const NodeHandle = papyrus.NodeHandle;
const PapyrusContext = papyrus.PapyrusContext;

const RingQueueU = @import("RingQueue.zig").RingQueueU;

const core = @import("root").neonwood.core;
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

pub const EventType = enum {
    mouseOver,
    mouseOff,
};

pub const PressedEventType = enum {
    onPressed,
    onReleased,
};

pub const EventHandlerError = error{
    UnknownError,
    EventPanic,
    EventDropped,
    EventIgnored,
};

pub const SingleEventFn = *const fn (NodeHandle, ?*anyopaque) EventHandlerError!void;
pub const PressedEventFn = *const fn (NodeHandle, PressedEventType, ?*anyopaque) EventHandlerError!void;

const EventListener = struct {
    node: NodeHandle,
    event: EventType,
    context: ?*anyopaque,
    eventFn: SingleEventFn,
};

const PressedEventListener = struct {
    node: NodeHandle,
    keycode: Key,
    event: PressedEventType,
    context: ?*anyopaque,
    eventFn: PressedEventFn,
};

backingAllocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
inputEvents: std.AutoHashMapUnmanaged(NodeHandle, std.ArrayListUnmanaged(EventListener)),
pressEvents: std.AutoHashMapUnmanaged(NodeHandle, std.ArrayListUnmanaged(PressedEventListener)),

pub fn installMouseOverEvent(
    self: *@This(),
    node: NodeHandle,
    event: EventType,
    context: ?*anyopaque,
    eventFn: SingleEventFn,
) !void {
    var allocator = self.arena.allocator();

    var listener: EventListener = .{
        .node = node,
        .event = event,
        .context = context,
        .eventFn = eventFn,
    };

    if (self.inputEvents.getPtr(node)) |listenerList| {
        try listenerList.append(allocator, listener);
    } else {
        var newListenerList: std.ArrayListUnmanaged(EventListener) = .{};
        try newListenerList.append(allocator, listener);
        try self.inputEvents.put(allocator, node, newListenerList);
    }
}

pub fn pushMouseOverEvent(self: *@This(), node: NodeHandle, event: EventType) EventHandlerError!void {
    if (self.inputEvents.get(node)) |listeners| {
        for (listeners.items) |listener| {
            if (listener.event == event) {
                try listener.eventFn(node, listener.context);
            }
        }
    }
}

pub fn pushPressedEvent(self: *@This(), node: NodeHandle, event: PressedEventType, keycode: Key) !void {
    if (self.pressEvents.get(node)) |listeners| {
        for (listeners.items) |listener| {
            if (listener.event == event and keycode == listener.keycode) {
                try listener.eventFn(node, event, listener.context);
            }
        }
    }
}

pub fn installOnPressedEvent(self: *@This(), node: NodeHandle, event: PressedEventType, keycode: Key, context: ?*anyopaque, eventFn: PressedEventFn) !void {
    var listener: PressedEventListener = .{
        .node = node,
        .event = event,
        .keycode = keycode,
        .context = context,
        .eventFn = eventFn,
    };

    var allocator = self.arena.allocator();

    if (self.pressEvents.getPtr(node)) |listenerList| {
        try listenerList.append(allocator, listener);
    } else {
        var newListenerList: std.ArrayListUnmanaged(PressedEventListener) = .{};
        try newListenerList.append(allocator, listener);
        try self.pressEvents.put(allocator, node, newListenerList);
    }
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

pub fn uninstallHandlers(self: @This(), node: NodeHandle) void {
    self.inputEvents.remove(node);
    self.pressEvents.remove(node);
}
