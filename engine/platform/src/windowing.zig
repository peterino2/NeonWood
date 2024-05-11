const std = @import("std");
const core = @import("core");
const platform = @import("platform.zig");
const gameInput = @import("gameInput.zig");
pub const glfw3 = @import("c.zig").glfw3;
const graphicsBackend = @import("graphicsBackend");

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
    noinit: bool = false,
    icon: []const u8 = "content/textures/icon.png",
};

pub var gPlatformSettings: struct {
    pollLockoutTime: ?f32 = null,
    decoratedWindow: bool = true,
    transparentFrameBuffer: bool = false,
} = .{};

pub const InstalledEvents = struct {
    allocator: std.mem.Allocator,
    onWindowFocused: std.ArrayListUnmanaged(glfw3.GLFWwindowfocusfun) = .{},
    onMouseButton: std.ArrayListUnmanaged(glfw3.GLFWmousebuttonfun) = .{},
    onCursorPos: std.ArrayListUnmanaged(glfw3.GLFWcursorposfun) = .{},
    onTextEntry: std.ArrayListUnmanaged(glfw3.GLFWcharfun) = .{},

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.onWindowFocused.deinit(self.allocator);
        self.onMouseButton.deinit(self.allocator);
        self.onCursorPos.deinit(self.allocator);
        self.onTextEntry.deinit(self.allocator);
    }
};

// For windows and linux computers this is a glfw instance
pub const PlatformInstance = struct {
    allocator: std.mem.Allocator,
    windowName: []const u8,
    iconPath: []const u8,

    window: ?*glfw3.GLFWwindow = null,
    extent: core.Vector2c,
    exitSignal: bool = false,
    eventQueue: RingQueue(IOEvent),
    handlers: InstalledEvents,
    workBuffer: std.ArrayList(IOEvent),
    listeners: std.ArrayList(RawInputObjectRef),
    gameInput: *gameInput.GameInputSystem = undefined,

    cursorEnabled: bool = true,

    cursorPos: core.Vector2f = .{},

    contentScale: core.Vector2f = .{},

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
        const self: @This() = .{
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

        //if (graphicsBackend.UseVulkan) {
        core.engine_logs("Initializing with Vulkan 1.3");
        // }
        // if (graphicsBackend.UseGLES2) {
        //     core.engine_logs("Initializing with OpenGLES");
        // }

        return self;
    }

    pub fn setup(self: *@This()) !void {
        try self.initGlfw();
        try self.initInput();

        core.setupEnginePlatform(self, enginePoll, processEvents);
    }

    pub fn enginePoll(opaqueSelf: *anyopaque) core.RttiDataEventError!void {
        var self: *@This() = @alignCast(@ptrCast(opaqueSelf));

        self.pollEvents();
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
        if (glfw3.glfwInit() != glfw3.GLFW_TRUE) {
            core.engine_errs("Glfw Init Failed");
            return error.GlfwInitFailed;
        }

        core.engine_log("platform starting: GLFW", .{});

        //if (graphicsBackend.UseVulkan) {
        glfw3.glfwWindowHint(glfw3.GLFW_CLIENT_API, glfw3.GLFW_NO_API);
        //} else if (graphicsBackend.UseGLES2) {
        //    glfw3.glfwWindowHint(glfw3.GLFW_CLIENT_API, glfw3.GLFW_OPENGL_ES_API);
        //    glfw3.glfwWindowHint(glfw3.GLFW_CONTEXT_VERSION_MAJOR, 2);
        //    glfw3.glfwWindowHint(glfw3.GLFW_CONTEXT_VERSION_MINOR, 0);
        //    glfw3.glfwWindowHint(glfw3.GLFW_OPENGL_PROFILE, glfw3.GLFW_OPENGL_ANY_PROFILE);
        //} else {
        //    @panic("Unknown graphics api configs");
        //}

        glfw3.glfwWindowHint(glfw3.GLFW_DECORATED, if (gPlatformSettings.decoratedWindow) glfw3.GLFW_TRUE else glfw3.GLFW_FALSE);
        glfw3.glfwWindowHint(glfw3.GLFW_TRANSPARENT_FRAMEBUFFER, if (gPlatformSettings.transparentFrameBuffer) glfw3.GLFW_TRUE else glfw3.GLFW_FALSE);

        self.window = glfw3.glfwCreateWindow(
            @as(c_int, @intCast(self.extent.x)),
            @as(c_int, @intCast(self.extent.y)),
            self.windowName.ptr,
            null,
            null,
        ) orelse return error.WindowInitFailed;

        self.maybeSetPngIcon();

        if (glfw3.glfwRawMouseMotionSupported() != 0)
            glfw3.glfwSetInputMode(self.window, glfw3.GLFW_RAW_MOUSE_MOTION, glfw3.GLFW_TRUE);

        glfw3.glfwSetWindowAspectRatio(self.window, 16, 9);

        //if (graphicsBackend.UseVulkan) {
        var extensionsCount: u32 = 0;
        const extensions = platform.glfw3.glfwGetRequiredInstanceExtensions(&extensionsCount);

        core.engine_log("glfw has requested the following vulkan extensions: {d}", .{extensionsCount});
        if (extensionsCount > 0) {
            var i: usize = 0;
            while (i < extensionsCount) : (i += 1) {
                const x = @as([*]const core.CStr, @ptrCast(extensions));
                core.engine_log("  glfw_extension: {s}", .{x[i]});
            }
        }
        //}

        self.installHandlers();
    }

    pub fn maybeSetPngIcon(self: *@This()) void {
        var pngContents = core.png.PngContents.init(self.allocator, self.iconPath) catch return;
        defer pngContents.deinit();

        const pixels: ?*u8 = &pngContents.pixels[0];
        var iconImage = glfw3.GLFWimage{
            .width = @as(c_int, @intCast(pngContents.size.x)),
            .height = @as(c_int, @intCast(pngContents.size.y)),
            .pixels = pixels,
        };
        glfw3.glfwSetWindowIcon(self.window, 1, &iconImage);
    }

    pub fn pollEvents(self: *@This()) void {
        glfw3.glfwPollEvents();

        if (self.shouldExit()) {
            core.gEngine.exit();
        }
    }

    pub fn processEvents(ptr: *anyopaque, frameNumber: u64) core.RttiDataEventError!void {
        const self: *@This() = @alignCast(@ptrCast(ptr));
        _ = frameNumber;
        var t1 = tracy.ZoneN(@src(), "Pumping Events");
        defer t1.End();

        self.pumpEvents() catch return error.UnknownStatePanic;
    }

    pub fn getCursorPosition(self: *@This()) core.Vector2f {
        return self.cursorPos;
    }

    pub fn installHandlers(self: *@This()) void {
        core.engine_logs("platform.windowing:: installing handlers");
        _ = glfw3.glfwSetCursorPosCallback(@as(?*glfw3.GLFWwindow, @ptrCast(self.window)), mousePositionCallback);
        _ = glfw3.glfwSetMouseButtonCallback(@as(?*glfw3.GLFWwindow, @ptrCast(self.window)), mouseButtonCallback);
        _ = glfw3.glfwSetKeyCallback(@as(?*glfw3.GLFWwindow, @ptrCast(self.window)), keyCallback);
        _ = glfw3.glfwSetFramebufferSizeCallback(@as(?*glfw3.GLFWwindow, @ptrCast(self.window)), windowResizeCallback);
        _ = glfw3.glfwSetCharCallback(@as(?*glfw3.GLFWwindow, @ptrCast(self.window)), charCallback);

        glfw3.glfwGetWindowContentScale(@as(?*glfw3.GLFWwindow, @ptrCast(self.window)), &self.contentScale.x, &self.contentScale.y);

        core.engine_log("contentScale: {any}", .{self.contentScale});
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
                            _ = handler;
                            // handler.?(self.window, mousePos.x, mousePos.y);
                        }

                        self.cursorPos.x = @floatCast(mousePos.x);
                        self.cursorPos.y = @floatCast(mousePos.y);
                        self.inputState.mousePos = core.Vector2{ .x = mousePos.x, .y = mousePos.y };
                    },
                    .mouseButton => {},
                    .windowFocused => {},
                    .scroll => {},
                    .key => {},
                    .windowResize => {},
                    .codepoint => |codepoint| {
                        // core.ui_log("codepoint recieved: {c}", .{@as([4]u8, @bitCast(codepoint))[0]});
                        for (self.handlers.onTextEntry.items) |handler| {
                            handler.?(self.window, codepoint);
                        }
                    },
                }
            }

            self.workBuffer.clearRetainingCapacity();
        }
    }

    pub fn shouldExit(self: @This()) bool {
        if (glfw3.glfwWindowShouldClose(self.window) == glfw3.GLFW_TRUE)
            return true;

        if (self.exitSignal)
            return true;

        return false;
    }

    pub fn setCursorEnabled(self: *@This(), cursorEnabled: bool) void {
        self.cursorEnabled = cursorEnabled;
        glfw3.glfwSetInputMode(self.window, glfw3.GLFW_CURSOR, if (cursorEnabled) glfw3.GLFW_CURSOR_NORMAL else glfw3.GLFW_CURSOR_DISABLED);
    }

    pub fn isCursorEnabled(self: @This()) bool {
        return self.cursorEnabled;
    }

    // Low level API
    pub fn installCursorPosCallback(self: *@This(), pfn: glfw3.GLFWcursorposfun) !void {
        try self.handlers.onCursorPos.append(self.handlers.allocator, pfn);
    }

    pub fn installCodepointCallback(self: *@This(), pfn: glfw3.GLFWcharfun) !void {
        try self.handlers.onCursorPos.append(self.handlers.allocator, pfn);
    }
};

pub const IOEvent = union(enum(u8)) {
    windowFocused: struct { focused: c_int },
    mousePosition: struct { x: f64, y: f64 },
    mouseButton: struct { button: c_int, action: c_int, mods: c_int },
    scroll: struct { xoffset: f64, yoffset: f64 },
    key: struct { key: c_int, scancode: c_int, action: c_int, mods: c_int },
    windowResize: struct { newSize: core.Vector2f },
    codepoint: c_uint,
};

fn windowResizeCallback(_: ?*glfw3.GLFWwindow, newWidth: c_int, newHeight: c_int) callconv(.C) void {
    pushEventSafe(.{ .windowResize = .{
        .newSize = .{ .x = @floatFromInt(newWidth), .y = @floatFromInt(newHeight) },
    } });
}

// push an io event onto the IOEventQueue
//
// Excessive events shall be dropped.
pub fn pushEventSafe(event: IOEvent) void {
    platform.getInstance().eventQueue.pushLocked(event) catch {
        core.engine_logs("too many events queued, dropping event...");
    };
}

pub fn mousePositionCallback(_: ?*glfw3.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    pushEventSafe(.{ .mousePosition = .{ .x = xpos, .y = ypos } });
}

pub fn mouseButtonCallback(_: ?*glfw3.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    pushEventSafe(.{ .mouseButton = .{ .button = button, .action = action, .mods = mods } });
}

pub fn windowFocusedCallback(_: ?*glfw3.GLFWwindow, focused: c_int) callconv(.C) void {
    pushEventSafe(.{ .windowFocused = .{ .focused = focused } });
}

pub fn scrollCallback(_: ?*glfw3.GLFWwindow, xoffset: c_int, yoffset: c_int) callconv(.C) void {
    pushEventSafe(.{ .scroll = .{ .xoffset = xoffset, .yoffset = yoffset } });
}

pub fn keyCallback(_: ?*glfw3.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
    pushEventSafe(.{ .key = .{ .key = key, .scancode = scancode, .action = action, .mods = mods } });
}

pub fn charCallback(_: ?*glfw3.GLFWwindow, codepoint: c_uint) callconv(.C) void {
    pushEventSafe(.{ .codepoint = codepoint });
}

pub fn getPlatformExtensions(allocator: std.mem.Allocator) !std.ArrayList([*:0]const u8) {
    var rv = std.ArrayList([*:0]const u8).init(allocator);

    var extCount: u32 = 0;
    const extensions = platform.glfw3.glfwGetRequiredInstanceExtensions(&extCount);

    for (0..extCount) |i| {
        const x = @as([*]const [*:0]const u8, @ptrCast(extensions));
        try rv.append(x[i]);
    }

    return rv;
}
