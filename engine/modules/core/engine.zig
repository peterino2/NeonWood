const std = @import("std");
const logging = @import("logging.zig");
const input = @import("input.zig");
const rtti = @import("rtti.zig");
const time = @import("engineTime.zig");
const core = @import("../core.zig");
const jobs = @import("jobs.zig");
const tracy = core.tracy;
const trace = @import("trace.zig");
const platform = @import("../platform.zig");
const p2 = @import("lib/p2/algorithm.zig");

const TracesContext = trace.TracesContext;
const Name = p2.Name;
const MakeName = p2.MakeName;

const NeonObjectRef = rtti.NeonObjectRef;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const AutoHashMap = std.AutoHashMap;
const JobManager = jobs.JobManager;

const engine_log = logging.engine_log;

pub const Engine = struct {
    exitSignal: bool,
    exitConfirmed: bool = false,

    allocator: std.mem.Allocator,

    // better name for these rtti objects is actually 'engine object'
    rttiObjects: ArrayListUnmanaged(NeonObjectRef),
    eventors: ArrayListUnmanaged(NeonObjectRef),
    exitListeners: ArrayListUnmanaged(NeonObjectRef),
    tickables: ArrayListUnmanaged(usize), // todo: this maybe should just be a list of objects
    tracesContext: *TracesContext,
    jobManager: JobManager,

    lastEngineTime: f64,
    deltaTime: f64, // delta time for this frame from the previous frame
    frameNumber: u64,

    pub fn init(allocator: std.mem.Allocator) !@This() {
        var rv = Engine{
            .allocator = allocator,
            .exitSignal = false,
            .rttiObjects = .{},
            .tickables = .{},
            .deltaTime = 0.0,
            .lastEngineTime = 0.0,
            .tracesContext = try allocator.create(TracesContext),
            .jobManager = JobManager.init(allocator),
            .eventors = .{},
            .frameNumber = 0,
            .exitListeners = .{},
        };

        rv.tracesContext.* = TracesContext.init(allocator);

        return rv;
    }

    pub fn deinit(self: *@This()) void {
        self.jobManager.deinit();
        for (self.rttiObjects.items) |item| {
            if (item.vtable.deinit_func) |deinitFn| {
                deinitFn(item.ptr);
            }
        }
        self.rttiObjects.deinit(self.allocator);
        self.eventors.deinit(self.allocator);
        self.tickables.deinit(self.allocator);
        self.tracesContext.deinit();
        self.exitListeners.deinit(self.allocator);
    }

    // creates an engine object using the engine's allocator.
    pub fn createObject(self: *@This(), comptime T: type, params: NeonObjectParams) !*T {
        const newIndex = self.rttiObjects.items.len;
        const vtable = &@field(T, "NeonObjectTable");
        var newObjectPtr = try vtable.init_func(self.allocator);

        const newObjectRef = NeonObjectRef{
            .ptr = @as(*anyopaque, @ptrCast(newObjectPtr)),
            .vtable = vtable,
        };

        try self.rttiObjects.append(self.allocator, newObjectRef);

        if (params.can_tick) {
            if (!@hasDecl(T, "tick")) {
                return error.RequestedTickNotAvailable; // tried to register a tickable for an object which does not implement tick
            }

            // register to tick table
            try self.tickables.append(self.allocator, newIndex);
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
        const newTime = time.getEngineTime();
        self.deltaTime = newTime - self.lastEngineTime;
        self.frameNumber += 1;

        try platform.getInstance().processEvents(self.frameNumber);

        for (self.eventors.items) |*objectRef| {
            objectRef.vtable.processEvents.?(objectRef.ptr, self.frameNumber) catch unreachable;
        }

        var index: isize = @as(isize, @intCast(self.tickables.items.len)) - 1;
        while (index >= 0) : (index -= 1) {
            var z = tracy.Zone(@src());
            const objectRef = self.rttiObjects.items[self.tickables.items[@as(usize, @intCast(index))]];
            objectRef.vtable.tick_func.?(objectRef.ptr, self.deltaTime);
            z.Name(objectRef.vtable.typeName.utf8);
            z.End();
        }
        self.lastEngineTime = newTime;
        tracy.FrameMarkEnd("frame");
    }

    pub fn run(self: *@This()) !void {
        core.engine_logs("enigne loop started");
        const L = struct {
            engine: *Engine,

            pub fn func(ctx: @This(), job: *core.JobContext) void {
                _ = job;

                tracy.SetThreadName("Systems Thread");
                while (!ctx.engine.exitSignal) {
                    ctx.engine.tick() catch unreachable;
                }
                for (ctx.engine.exitListeners.items) |ref| {
                    ref.vtable.exitSignal_func.?(ref.ptr) catch unreachable;
                }

                ctx.engine.exitConfirmed = true;
            }
        };
        try core.dispatchJob(L{ .engine = self });
    }

    pub fn exit(self: *@This()) void {
        self.exitSignal = true;
    }
};

pub const NeonObjectParams = struct {
    can_tick: bool = false,
    responds_to_events: bool = false,
};

test "comptime registration implementation" {}
