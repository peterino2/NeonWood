const std = @import("std");
const core = @import("../core.zig");
const image = @import("../image.zig");
const RingQueue = core.RingQueue;
const tracy = core.tracy;

// We are having some serious issues with this events pump.

pub const c = @import("c.zig");

pub const PlatformParams = struct {
    extent: core.Vector2c = .{ .x = 1600, .y = 900 },
    windowName: []const u8 = "sample window",
    icon: []const u8 = "content/textures/icon.png",
};

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
    cursorEnabled: bool = true,

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
            .workBuffer = std.ArrayList(IOEvent).init(allocator),
        };

        core.engine_log("Creating IO Buffer with {x} size", .{@sizeOf(IOEvent) * 8096});

        return self;
    }

    pub fn initGlfw(self: *@This()) !void {
        if (c.glfwInit() != c.GLFW_TRUE) {
            core.engine_errs("Glfw Init Failed");
            return error.GlfwInitFailed;
        }

        c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);

        self.window = c.glfwCreateWindow(
            @intCast(c_int, self.extent.x),
            @intCast(c_int, self.extent.y),
            self.windowName.ptr,
            null,
            null,
        ) orelse return error.WindowInitFailed;

        var png = try image.PngContents.init(self.allocator, self.iconPath);
        defer png.deinit();

        var pixels: ?*u8 = &png.pixels[0];
        var iconImage = c.GLFWimage{
            .width = @intCast(c_int, png.size.x),
            .height = @intCast(c_int, png.size.y),
            .pixels = pixels,
        };
        if (c.glfwRawMouseMotionSupported() != 0)
            c.glfwSetInputMode(self.window, c.GLFW_RAW_MOUSE_MOTION, c.GLFW_TRUE);

        c.glfwSetWindowIcon(self.window, 1, &iconImage);
        c.glfwSetWindowAspectRatio(self.window, 16, 9);

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

    pub fn getCursorPosition(self: *@This()) core.Vector2 {
        var pos: core.Vector2 = .{ .x = 0, .y = 0 };

        c.glfwGetCursorPos(@ptrCast(?*c.GLFWwindow, self.window), &pos.x, &pos.y);
        return pos;
    }

    pub fn installHandlers(self: *@This()) void {
        _ = c.glfwSetCursorPosCallback(@ptrCast(?*c.GLFWwindow, self.window), mousePositionCallback);
    }

    pub fn pumpEvents(self: *@This()) !void {
        if (self.eventQueue.count() > 0) {
            self.eventQueue.lock();

            while (self.eventQueue.popFromUnlocked()) |event| {
                try self.workBuffer.append(event);
            }

            self.eventQueue.unlock();

            for (self.workBuffer.items) |event| {
                switch (event) {
                    .cursorPos => |payload| {
                        for (self.handlers.onCursorPos.items) |handler| {
                            handler.?(self.window, payload.x, payload.y);
                        }
                    },
                    .cursorEnter, .windowFocused, .mouseButton, .scroll, .key, .char, .monitor => {},
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

    pub fn deinit(self: *@This()) void {
        self.handlers.deinit();
    }

    // Low level API
    pub fn installCursorPosCallback(self: *@This(), pfn: c.GLFWcursorposfun) !void {
        try self.handlers.onCursorPos.append(self.handlers.allocator, pfn);
    }
};

const IOEvent = union(enum(u8)) {
    cursorEnter: struct { entered: c_int },
    windowFocused: struct { focused: c_int },
    cursorPos: struct { x: f64, y: f64 },
    mouseButton: struct { button: c_int, action: c_int, mods: c_int },
    scroll: struct { xoffset: f64, yoffset: f64 },
    key: struct { key: c_int, scancode: c_int, action: c_int, mods: c_int },
    char: struct { c: c_int },
    monitor: struct { monitor: ?*c.GLFWmonitor, event: c_int },
};

// These are Imgui callbacks that need to be rejigged
// glfwSetWindowFocusCallback(vd->Window, ImGui_ImplGlfw_WindowFocusCallback);
// glfwSetCursorEnterCallback(vd->Window, ImGui_ImplGlfw_CursorEnterCallback);
// glfwSetCursorPosCallback(vd->Window, ImGui_ImplGlfw_CursorPosCallback);
// glfwSetMouseButtonCallback(vd->Window, ImGui_ImplGlfw_MouseButtonCallback);
// glfwSetScrollCallback(vd->Window, ImGui_ImplGlfw_ScrollCallback);
// glfwSetKeyCallback(vd->Window, ImGui_ImplGlfw_KeyCallback);
// glfwSetCharCallback(vd->Window, ImGui_ImplGlfw_CharCallback);
// glfwSetWindowCloseCallback(vd->Window, ImGui_ImplGlfw_WindowCloseCallback);
// glfwSetWindowPosCallback(vd->Window, ImGui_ImplGlfw_WindowPosCallback);
// glfwSetWindowSizeCallback(vd->Window, ImGui_ImplGlfw_WindowSizeCallback);

// _ = platform.c.glfwSetKeyCallback(platform.getInstance().window, inputCallback);
// _ = platform.c.glfwSetCursorPosCallback(platform.getInstance().window, mousePositionCallback);
// _ = platform.c.glfwSetMouseButtonCallback(platform.getInstance().window, mouseInputCallback);
// pumped functions.

const platform = @import("../platform.zig");

pub fn mousePositionCallback(_: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    platform.getInstance().eventQueue.pushLocked(.{ .cursorPos = .{ .x = xpos, .y = ypos } }) catch unreachable;
}

// pub fn mouseInputCallback(window: ?*platform.c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
//     c.cImGui_ImplGlfw_MouseButtonCallback(@ptrCast(?*c.GLFWwindow, window), button, action, mods);
// }
//
// pub fn inputCallback(window: ?*platform.c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
//     c.cImGui_ImplGlfw_KeyCallback(@ptrCast(?*c.GLFWwindow, window), key, scancode, action, mods);
// }
