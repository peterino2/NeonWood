const std = @import("std");
const core = @import("../core.zig");
const image = @import("../image.zig");
const platform = @import("../platform.zig");
const gameInput = @import("gameInput.zig");
pub const c = @import("c.zig");

const RingQueue = core.RingQueue;
const tracy = core.tracy;
const InputState = @import("InputState.zig");

pub const InputListenerError = error{
    UnknownError,
};

pub const RawInputListenerInterface = struct {

    // required functions
    OnIoEvent: *const fn (*anyopaque, event: IOEvent) InputListenerError!void,

    pub fn from(comptime TargetType: type) @This() {
        const Wrapped = struct {
            pub fn OnIoEvent(pointer: *anyopaque, event: IOEvent) InputListenerError!void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                try ptr.OnIoEvent(event);
            }
        };

        return .{
            .OnIoEvent = Wrapped.OnIoEvent,
        };
    }
};

pub const RawInputObjectRef = struct {
    ptr: *anyopaque,
    vtable: *const RawInputListenerInterface,

    pub fn from(target: anytype) @This() {
        const vtable = &(@TypeOf(target.*)).RawInputListenerVTable;

        return .{
            .ptr = target,
            .vtable = vtable,
        };
    }
};

// We are having some serious issues with this events pump.

pub const PlatformParams = struct {
    extent: core.Vector2c = .{ .x = 1600, .y = 900 },
    windowName: []const u8 = "sample window",
    icon: []const u8 = "content/textures/icon.png",
};

pub var gPlatformSettings: struct {
    pollLockoutTime: ?f32 = null,
    decoratedWindow: bool = true,
    transparentFrameBuffer: bool = false,
} = .{};

pub const InstalledEvents = struct {
    allocator: std.mem.Allocator,
    onWindowFocused: std.ArrayListUnmanaged(c.GLFWwindowfocusfun) = .{},
    onMouseButton: std.ArrayListUnmanaged(c.GLFWmousebuttonfun) = .{},
    onCursorPos: std.ArrayListUnmanaged(c.GLFWcursorposfun) = .{},

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.onWindowFocused.deinit(self.allocator);
        self.onMouseButton.deinit(self.allocator);
        self.onCursorPos.deinit(self.allocator);
    }
};

// For windows and linux computers this is a glfw instance
pub const PlatformInstance = struct {
    allocator: std.mem.Allocator,
    windowName: []const u8,
    iconPath: []const u8,

    window: ?*c.GLFWwindow = null,
    extent: core.Vector2c,
    exitSignal: bool = false,
    eventQueue: RingQueue(IOEvent),
    handlers: InstalledEvents,
    workBuffer: std.ArrayList(IOEvent),
    listeners: std.ArrayList(RawInputObjectRef),
    gameInput: *gameInput.GameInputSystem = undefined,

    cursorEnabled: bool = true,

    cursorPos: core.Vector2f = .{},

    // Low level controls of the current state of input,
    inputState: InputState = .{},

    pub fn deinit(self: *@This()) void {
        self.workBuffer.deinit();
        self.eventQueue.deinit();
        self.handlers.deinit();
        self.gameInput.deinit();
        self.allocator.destroy(self.gameInput);

        for (self.listeners.items) |listener| {
            _ = listener;
        }

        self.listeners.deinit();
    }

    pub fn init(
        allocator: std.mem.Allocator,
        params: PlatformParams,
    ) !@This() {
        var self: @This() = .{
            .windowName = params.windowName,
            .allocator = allocator,
            .iconPath = params.icon,
            .extent = params.extent,
            .eventQueue = try RingQueue(IOEvent).init(allocator, 8096),
            .handlers = InstalledEvents.init(allocator),
            .listeners = std.ArrayList(RawInputObjectRef).init(allocator),
            .workBuffer = std.ArrayList(IOEvent).init(allocator),
        };

        core.engine_log("Creating IO Buffer with {x} size", .{@sizeOf(IOEvent) * 8096});

        return self;
    }

    pub fn setup(self: *@This()) !void {
        try self.initGlfw();
        try self.initInput();
    }

    pub fn initInput(self: *@This()) !void {
        self.gameInput = try self.allocator.create(gameInput.GameInputSystem);
        try self.listeners.append(RawInputObjectRef.from(self.gameInput));
    }

    pub fn installListener(self: *@This(), listener: anytype) !void {
        core.engine_logs("installed listener:");
        try self.listeners.append(RawInputObjectRef.from(listener));
    }

    pub fn initGlfw(self: *@This()) !void {
        if (c.glfwInit() != c.GLFW_TRUE) {
            core.engine_errs("Glfw Init Failed");
            return error.GlfwInitFailed;
        }

        core.engine_log("platform starting: GLFW", .{});

        c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);
        c.glfwWindowHint(c.GLFW_DECORATED, if (gPlatformSettings.decoratedWindow) c.GLFW_TRUE else c.GLFW_FALSE);
        c.glfwWindowHint(c.GLFW_TRANSPARENT_FRAMEBUFFER, if (gPlatformSettings.transparentFrameBuffer) c.GLFW_TRUE else c.GLFW_FALSE);

        self.window = c.glfwCreateWindow(
            @as(c_int, @intCast(self.extent.x)),
            @as(c_int, @intCast(self.extent.y)),
            self.windowName.ptr,
            null,
            null,
        ) orelse return error.WindowInitFailed;

        var png = try image.PngContents.init(self.allocator, self.iconPath);
        defer png.deinit();

        var pixels: ?*u8 = &png.pixels[0];
        var iconImage = c.GLFWimage{
            .width = @as(c_int, @intCast(png.size.x)),
            .height = @as(c_int, @intCast(png.size.y)),
            .pixels = pixels,
        };

        if (c.glfwRawMouseMotionSupported() != 0)
            c.glfwSetInputMode(self.window, c.GLFW_RAW_MOUSE_MOTION, c.GLFW_TRUE);

        c.glfwSetWindowIcon(self.window, 1, &iconImage);
        c.glfwSetWindowAspectRatio(self.window, 16, 9);

        var extensionsCount: u32 = 0;
        const extensions = platform.c.glfwGetRequiredInstanceExtensions(&extensionsCount);

        core.engine_log("glfw has requested the following extensions: {d}", .{extensionsCount});
        if (extensionsCount > 0) {
            var i: usize = 0;
            while (i < extensionsCount) : (i += 1) {
                var x = @as([*]const core.CStr, @ptrCast(extensions));
                core.engine_log("  glfw_extension: {s}", .{x[i]});
            }
        }

        self.installHandlers();
    }

    pub fn pollEvents(self: *@This()) void {
        c.glfwPollEvents();

        if (self.shouldExit()) {
            core.gEngine.exit();
        }
    }

    pub fn processEvents(self: *@This(), frameNumber: u64) !void {
        _ = frameNumber;
        var t1 = tracy.ZoneN(@src(), "Pumping Events");
        defer t1.End();

        try self.pumpEvents();
    }

    pub fn getCursorPosition(self: *@This()) core.Vector2f {
        return self.cursorPos;
    }

    pub fn installHandlers(self: *@This()) void {
        core.engine_logs("platform.windowing:: installing handlers");
        _ = c.glfwSetCursorPosCallback(@as(?*c.GLFWwindow, @ptrCast(self.window)), mousePositionCallback);
        _ = c.glfwSetMouseButtonCallback(@as(?*c.GLFWwindow, @ptrCast(self.window)), mouseButtonCallback);
        _ = c.glfwSetKeyCallback(@as(?*c.GLFWwindow, @ptrCast(self.window)), keyCallback);
    }

    pub fn pumpEvents(self: *@This()) !void {
        if (self.eventQueue.count() > 0) {
            self.eventQueue.lock();

            while (self.eventQueue.popFromUnlocked()) |event| {
                try self.workBuffer.append(event);
            }

            self.eventQueue.unlock();

            for (self.workBuffer.items) |event| {
                for (self.listeners.items) |listener| {
                    try listener.vtable.OnIoEvent(listener.ptr, event);
                }

                switch (event) {
                    .mousePosition => |mousePos| {
                        for (self.handlers.onCursorPos.items) |handler| {
                            handler.?(self.window, mousePos.x, mousePos.y);
                            self.cursorPos.x = @floatCast(mousePos.x);
                            self.cursorPos.y = @floatCast(mousePos.y);
                        }

                        self.inputState.mousePos = core.Vector2{ .x = mousePos.x, .y = mousePos.y };
                    },
                    .mouseButton => {},
                    .windowFocused => {},
                    .scroll => {},
                    .key => {},
                }
            }

            self.workBuffer.clearRetainingCapacity();
        }
    }

    pub fn shouldExit(self: @This()) bool {
        if (c.glfwWindowShouldClose(self.window) == c.GLFW_TRUE)
            return true;

        if (self.exitSignal)
            return true;

        return false;
    }

    pub fn setCursorEnabled(self: *@This(), cursorEnabled: bool) void {
        self.cursorEnabled = cursorEnabled;
        c.glfwSetInputMode(self.window, c.GLFW_CURSOR, if (cursorEnabled) c.GLFW_CURSOR_NORMAL else c.GLFW_CURSOR_DISABLED);
    }

    pub fn isCursorEnabled(self: @This()) bool {
        return self.cursorEnabled;
    }

    // Low level API
    pub fn installCursorPosCallback(self: *@This(), pfn: c.GLFWcursorposfun) !void {
        try self.handlers.onCursorPos.append(self.handlers.allocator, pfn);
    }
};

pub const IOEvent = union(enum(u8)) {
    windowFocused: struct { focused: c_int },
    mousePosition: struct { x: f64, y: f64 },
    mouseButton: struct { button: c_int, action: c_int, mods: c_int },
    scroll: struct { xoffset: f64, yoffset: f64 },
    key: struct { key: c_int, scancode: c_int, action: c_int, mods: c_int },
};

pub fn pushEventSafe(event: IOEvent) void {
    platform.getInstance().eventQueue.pushLocked(event) catch {
        core.engine_logs("too many events queued, dropping event...");
    };
}

pub fn mousePositionCallback(_: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    pushEventSafe(.{ .mousePosition = .{ .x = xpos, .y = ypos } });
}

pub fn mouseButtonCallback(_: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    pushEventSafe(.{ .mouseButton = .{ .button = button, .action = action, .mods = mods } });
}

pub fn windowFocusedCallback(_: ?*c.GLFWwindow, focused: c_int) callconv(.C) void {
    pushEventSafe(.{ .windowFocused = .{ .focused = focused } });
}

pub fn scrollCallback(_: ?*c.GLFWwindow, xoffset: c_int, yoffset: c_int) callconv(.C) void {
    pushEventSafe(.{ .scroll = .{ .xoffset = xoffset, .yoffset = yoffset } });
}

pub fn keyCallback(_: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    pushEventSafe(.{ .key = .{ .key = key, .scancode = scancode, .action = action, .mods = mods } });
}

pub fn getPlatformExtensions(allocator: std.mem.Allocator) !std.ArrayList([*:0]const u8) {
    var rv = std.ArrayList([*:0]const u8).init(allocator);

    var extCount: u32 = 0;
    const extensions = platform.c.glfwGetRequiredInstanceExtensions(&extCount);

    for (0..extCount) |i| {
        var x = @as([*]const [*:0]const u8, @ptrCast(extensions));
        try rv.append(x[i]);
    }

    return rv;
}
