const std = @import("std");
const logging = @import("logging.zig");
const names = @import("names.zig");
const input = @import("input.zig");
const rtti = @import("rtti.zig");
const time = @import("engineTime.zig");
const core = @import("../core.zig");
const jobs = @import("jobs.zig");
const tracy = core.tracy;
const trace = @import("trace.zig");

const TracesContext = trace.TracesContext;
const Name = names.Name;
const MakeName = names.MakeName;

const NeonObjectRef = rtti.NeonObjectRef;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const AutoHashMap = std.AutoHashMap;
const JobManager = jobs.JobManager;

const engine_log = logging.engine_log;

pub const Engine = struct {
    exitSignal: bool,

    allocator: std.mem.Allocator,

    // better name for these rtti objects is actually 'engine object'
    rttiObjects: ArrayListUnmanaged(NeonObjectRef),
    eventors: ArrayListUnmanaged(NeonObjectRef),
    tickables: ArrayListUnmanaged(usize),
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
        };

        rv.tracesContext.* = TracesContext.init(allocator);

        return rv;
    }
    pub fn deinit(self: *@This()) void {
        self.tracesContext.deinit();
    }

    // creates a neon object using the engine's allocator.
    // todo.. maybe there needs to be a managed NeObjectRef that allows a custom allocator
    // todo: We need a sparse array implementation of this
    pub fn createObject(self: *@This(), comptime T: type, params: NeonObjectParams) !*T {
        const newIndex = self.rttiObjects.items.len;
        var newObjectPtr = try self.allocator.create(T);
        const vtable = &@field(T, "NeonObjectTable");
        vtable.init_func(self.allocator, @ptrCast(*anyopaque, newObjectPtr));

        const newObjectRef = NeonObjectRef{
            .ptr = @ptrCast(*anyopaque, newObjectPtr),
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

        return newObjectPtr;
    }

    pub fn tick(self: *@This()) void {
        tracy.FrameMark();
        tracy.FrameMarkStart("frame");
        const newTime = time.getEngineTime();
        self.deltaTime = newTime - self.lastEngineTime;
        self.frameNumber += 1;

        for (self.eventors.items) |*objectRef| {
            objectRef.vtable.processEvents.?(objectRef.ptr, self.frameNumber) catch unreachable;
        }

        var index: isize = @intCast(isize, self.tickables.items.len) - 1;
        while (index >= 0) : (index -= 1) {
            var z = tracy.Zone(@src());
            const objectRef = self.rttiObjects.items[self.tickables.items[@intCast(usize, index)]];
            objectRef.vtable.tick_func.?(objectRef.ptr, self.deltaTime);
            z.Name(objectRef.vtable.typeName.utf8);
            z.End();
        }
        self.lastEngineTime = newTime;
        tracy.FrameMarkEnd("frame");
    }

    pub fn run(self: *@This()) void {
        const L = struct {
            engine: *Engine,

            pub fn func(ctx: @This(), job: *core.JobContext) void {
                _ = job;

                tracy.SetThreadName("Systems Thread");
                while (!ctx.engine.exitSignal) {
                    ctx.engine.tick();
                }
            }
        };
        core.dispatchJob(L{ .engine = self }) catch unreachable;
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
