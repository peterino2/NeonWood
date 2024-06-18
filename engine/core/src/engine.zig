const std = @import("std");
const logging = @import("logging.zig");
const input = @import("input.zig");
const engineObject = @import("engineObject.zig");
const time = @import("engineTime.zig");
const core = @import("core.zig");
const jobs = @import("jobs.zig");

const tracy = @import("tracy");
const p2 = @import("p2");
const nfd = @import("nfd");

const Atomic = std.atomic.Value;
const EngineDataEventError = engineObject.EngineDataEventError;

const Name = p2.Name;
const MakeName = p2.MakeName;

const EngineObjectRef = engineObject.EngineObjectRef;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const AutoHashMap = std.AutoHashMap;
const JobManager = jobs.JobManager;

const engine_log = logging.engine_log;

pub const PollFuncFn = *const fn (*anyopaque) EngineDataEventError!void;
pub const ProcEventsFn = *const fn (*anyopaque, u64) EngineDataEventError!void;

const EngineDelegates = @import("EngineDelegates.zig");

// perhaps a better name for this guy isn't actually engine, rather 'orchestrator' is more apt.
// but that's so avant-garde
pub const Engine = struct {
    exitSignal: Atomic(bool) = Atomic(bool).init(false),
    exitConfirmed: Atomic(bool) = Atomic(bool).init(false),

    allocator: std.mem.Allocator,

    // better name for these engineObject objects is actually 'engine object'
    rttiObjects: ArrayListUnmanaged(EngineObjectRef),
    eventors: ArrayListUnmanaged(EngineObjectRef),
    exitListeners: ArrayListUnmanaged(EngineObjectRef),
    preTickables: ArrayListUnmanaged(EngineObjectRef),
    tickables: ArrayListUnmanaged(usize), // todo: this maybe should just be a list of objects
    jobManager: *JobManager,

    destroyListSimple: ArrayListUnmanaged(EngineObjectRef) = .{},
    destroyListCore: ArrayListUnmanaged(EngineObjectRef) = .{},

    lastEngineTime: f64,
    deltaTime: f64, // delta time for this frame from the previous frame
    frameNumber: u64,

    averageFrameTime: f64 = 0,
    averageFrameSampleWindow: u32 = 60, // rolling weighted average

    platformCtx: *anyopaque = undefined,
    platformPollFunc: ?PollFuncFn = null,
    platformProcEventsFunc: ?ProcEventsFn = null,

    nfdRuntime: *nfd.NFDRuntime,

    delegates: EngineDelegates,

    first: bool = true,

    pub fn init(allocator: std.mem.Allocator) !@This() {
        const rv = Engine{
            .allocator = allocator,
            .rttiObjects = .{},
            .tickables = .{},
            .preTickables = .{},
            .deltaTime = 0.0,
            .lastEngineTime = 0.0,
            .jobManager = try JobManager.create(allocator),
            .eventors = .{},
            .frameNumber = 0,
            .exitListeners = .{},
            .nfdRuntime = try nfd.NFDRuntime.create(allocator, .{}),
            .delegates = EngineDelegates.init(allocator),
        };

        return rv;
    }

    pub fn deinit(self: *@This()) void {
        core.engine_logs("shutting down job Manager");
        self.jobManager.destroy();

        var i: i32 = @intCast(self.destroyListCore.items.len - 1);
        while (i >= 0) : (i -= 1) {
            const item = self.destroyListCore.items[@as(usize, @intCast(i))];
            if (item.vtable.deinit_func) |deinitFn| {
                deinitFn(item.ptr);
            }
        }
        self.destroyListCore.deinit(self.allocator);
        self.destroyListSimple.deinit(self.allocator);

        core.engine_logs("destroying engine objects");
        self.rttiObjects.deinit(self.allocator);

        core.engine_logs("destroying eventors");
        self.eventors.deinit(self.allocator);

        core.engine_logs("destroying tickables");
        self.tickables.deinit(self.allocator);
        self.preTickables.deinit(self.allocator);
        self.nfdRuntime.destroy();
        self.delegates.deinit();

        core.engine_logs("calling onexit listeners");
        self.exitListeners.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    // creates an engine object using the engine's allocator.
    pub fn createObject(self: *@This(), comptime T: type, params: NeonObjectParams) !*T {
        const newIndex = self.rttiObjects.items.len;
        const vtable = &@field(T, "NeonObjectTable");
        const newObjectPtr = try vtable.init_func(self.allocator);

        const newObjectRef = EngineObjectRef{
            .ptr = @as(*anyopaque, @ptrCast(newObjectPtr)),
            .vtable = vtable,
        };

        try self.rttiObjects.append(self.allocator, newObjectRef);

        if (params.isCore) {
            try self.destroyListCore.append(self.allocator, newObjectRef);
        } else {
            try self.destroyListSimple.append(self.allocator, newObjectRef);
        }

        if (params.can_tick) {
            if (!@hasDecl(T, "tick")) {
                return error.RequestedTickNotAvailable; // tried to register a tickable for an object which does not implement tick
            }

            // register to tick table
            try self.tickables.append(self.allocator, newIndex);
        }

        if (@hasDecl(T, "preTick")) {
            try self.preTickables.append(self.allocator, newObjectRef);
        }

        if (@hasDecl(T, "processEvents")) {
            try self.eventors.append(self.allocator, newObjectRef); //
        }

        if (@hasDecl(T, "onExitSignal")) {
            try self.exitListeners.append(self.allocator, newObjectRef); //
        }

        if (@hasDecl(T, "postInit")) {
            try vtable.postInit_func.?(newObjectPtr);
        }

        return @as(*T, @ptrCast(@alignCast(newObjectPtr)));
    }

    pub fn tick(self: *@This()) !void {
        tracy.FrameMark();
        tracy.FrameMarkStart("frame");
        tracy.FrameMarkEnd("frame");

        const newTime = time.getEngineTime();

        if (self.first) {
            self.first = false;
            self.lastEngineTime = newTime;
        }

        self.deltaTime = newTime - self.lastEngineTime;
        const sampleWindowf: f64 = @floatFromInt(self.averageFrameSampleWindow);
        self.averageFrameTime = self.averageFrameTime - (self.averageFrameTime / sampleWindowf) + self.deltaTime / sampleWindowf;

        for (self.delegates.onFrameDebugInfoEmitted.items) |l| {
            try l.func(l.ctx, self.averageFrameTime);
        }

        self.frameNumber += 1;

        if (self.platformProcEventsFunc) |procEventsFn| {
            try procEventsFn(self.platformCtx, self.frameNumber);
        }

        for (self.eventors.items) |*objectRef| {
            objectRef.vtable.processEvents.?(objectRef.ptr, self.frameNumber) catch @panic("process event error");
        }

        for (self.preTickables.items) |*objectRef| {
            objectRef.vtable.preTick_func.?(objectRef.ptr, self.deltaTime) catch @panic("pretick event error");
        }

        var index: isize = @as(isize, @intCast(self.tickables.items.len)) - 1;
        while (index >= 0) : (index -= 1) {
            var z = tracy.Zone(@src());
            const objectRef = self.rttiObjects.items[self.tickables.items[@as(usize, @intCast(index))]];
            objectRef.vtable.tick_func.?(objectRef.ptr, self.deltaTime);
            z.Name(objectRef.vtable.typeName.utf8());
            z.End();
        }
        self.lastEngineTime = newTime;
    }

    pub fn run(self: *@This()) !void {
        core.engine_logs("engine loop started");
        const L = struct {
            engine: *Engine,

            pub fn func(ctx: @This(), job: *core.JobContext) void {
                _ = job;

                tracy.SetThreadName("Systems Thread");
                while (!ctx.engine.exitSignal.load(.seq_cst)) {
                    ctx.engine.tick() catch unreachable;
                }
                for (ctx.engine.exitListeners.items) |ref| {
                    ref.vtable.exitSignal_func.?(ref.ptr) catch unreachable;
                }

                ctx.engine.exitConfirmed.store(true, .seq_cst);
            }
        };
        try core.dispatchJob(L{ .engine = self });

        try self.mainLoop();

        var i: i32 = @intCast(self.destroyListSimple.items.len - 1);
        while (i >= 0) : (i -= 1) {
            const item = self.destroyListSimple.items[@as(usize, @intCast(i))];
            if (item.vtable.deinit_func) |deinitFn| {
                deinitFn(item.ptr);
            }
        }
    }

    fn mainLoop(self: *@This()) !void {
        while (!self.exitConfirmed.load(.acquire)) {
            if (self.platformPollFunc) |pollFunc| {
                const z = core.tracy.ZoneN(@src(), "glfw input polling");
                try pollFunc(self.platformCtx);
                defer z.End();
            }
            std.time.sleep(1000 * 1000); // 1ms delay between polling functions, effectively limits input to 1khz.
            // (there is a noticable power consumption draw on laptops and battery based systems if this is unlimited)
            try self.nfdRuntime.processMessages();
        }
    }

    pub fn exit(self: *@This()) void {
        self.exitSignal.store(true, .release);
    }

    pub fn isShuttingDown(self: *@This()) bool {
        return self.exitSignal.load(.monotonic);
    }

    pub fn exitFinished(self: *@This()) bool {
        return self.exitConfirmed.load(.monotonic);
    }
};

pub const NeonObjectParams = struct {
    can_tick: bool = false,
    responds_to_events: bool = false,
    isCore: bool = false,
};

test "comptime registration implementation" {}
