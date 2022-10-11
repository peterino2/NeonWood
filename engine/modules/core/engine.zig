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

pub fn createObject(comptime T: type, params: NeonObjectParams) !*T {
    return core.gEngine.createObject(T, params);
}

pub const Engine = struct {
    exitSignal: bool,

    subsystems: ArrayList(*anyopaque),
    subsystemsByType: AutoHashMap(u32, usize),
    allocator: std.mem.Allocator,
    rttiObjects: ArrayListUnmanaged(NeonObjectRef),
    tickables: ArrayListUnmanaged(usize),
    tracesContext: *TracesContext,
    jobManager: JobManager,

    lastEngineTime: f64,
    deltaTime: f64, // delta time for this frame from the previous frame

    pub fn init(allocator: std.mem.Allocator) !@This() {
        var rv = Engine{
            .subsystems = ArrayList(*anyopaque).init(allocator),
            .subsystemsByType = AutoHashMap(u32, usize).init(allocator),
            .allocator = allocator,
            .exitSignal = false,
            .rttiObjects = .{},
            .tickables = .{},
            .deltaTime = 0.0,
            .lastEngineTime = 0.0,
            .tracesContext = try allocator.create(TracesContext),
            .jobManager = JobManager.init(allocator),
        };

        rv.tracesContext.* = TracesContext.init(allocator);

        return rv;
    }

    pub fn addSubsystem(self: *@This(), subsystem: anytype) !void {
        const typeInfo = @typeInfo(@TypeOf(subsystem));
        switch (typeInfo) {
            .Pointer => |_| {
                const nextId = self.subsystems.items.len;
                try self.subsystems.append(subsystem);
                try self.subsystemsByType.put(
                    MakeName(@typeName(@TypeOf(subsystem.*))).hash,
                    nextId,
                );
            },
            else => {
                return error.SubsystemRegisterationNotAPointer;
            },
        }
    }

    pub fn getSubsystem(self: *@This(), comptime subsystemType: type) ?*subsystemType {
        const name = comptime MakeName(@typeName(subsystemType));
        const index = self.subsystemsByType.get(name.hash) orelse return null;
        return @ptrCast(*subsystemType, @alignCast(
            @alignOf(subsystemType),
            self.subsystems.items[index],
        ));
    }

    pub fn deinit(self: *@This()) void {
        self.tracesContext.deinit();
        self.subsystems.deinit();
        self.subsystemsByType.deinit();
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
            comptime {
                if (!@hasDecl(T, "tick")) {
                    return error.RequestedTickNotAvailable; // tried to register a tickable for an object which does not implement tick
                }
            }

            // register to tick table
            try self.tickables.append(self.allocator, newIndex);
        }

        return newObjectPtr;
    }

    pub fn tick(self: *@This()) void {
        tracy.FrameMark();
        tracy.FrameMarkStart("frame");
        const newTime = time.getEngineTime();
        self.deltaTime = newTime - self.lastEngineTime;

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
        while (!self.exitSignal) {
            self.tick();
        }
    }

    pub fn exit(self: *@This()) void {
        self.exitSignal = true;
    }
};

pub const NeonObjectParams = struct {
    can_tick: bool = false,
};

test "basic type registration" {
    const alloc = std.testing.allocator;
    var engine = try Engine.init(alloc);
    defer engine.deinit();

    const struct1 = struct {
        name: []const u8,
    };

    var struct1_inst = struct1{ .name = "struct1" };

    var anonstruct = struct {
        name: []const u8,

        pub fn init() @This() {
            return @This(){ .name = "takyon" };
        }
    }.init();

    try engine.addSubsystem(&struct1_inst);
    try engine.addSubsystem(&anonstruct);

    try std.testing.expect(&struct1_inst == engine.getSubsystem(struct1).?);
}

test "comptime registration implementation" {}
