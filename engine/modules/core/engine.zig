const std = @import("std");
const logging = @import("logging.zig");
const names = @import("names.zig");
const input = @import("input.zig");
const rtti = @import("rtti.zig");
const time = @import("engineTime.zig");
const Name = names.Name;
const MakeName = names.MakeName;

const NeonObjectRef = rtti.NeonObjectRef;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const AutoHashMap = std.AutoHashMap;

const engine_log = logging.engine_log;

pub const Engine = struct {
    exitSignal: bool,

    subsystems: ArrayList(*anyopaque),
    subsystemsByType: AutoHashMap(u32, usize),
    allocator: std.mem.Allocator,
    rttiObjects: ArrayListUnmanaged(NeonObjectRef),
    tickables: ArrayListUnmanaged(usize),

    lastEngineTime: f64,
    deltaTime: f64, // delta time for this frame from the previous frame

    pub fn init(allocator: std.mem.Allocator) !@This() {
        const rv = Engine{
            .subsystems = ArrayList(*anyopaque).init(allocator),
            .subsystemsByType = AutoHashMap(u32, usize).init(allocator),
            .allocator = allocator,
            .exitSignal = false,
            .rttiObjects = .{},
            .tickables = .{},
            .deltaTime = 0.0,
            .lastEngineTime = 0.0,
        };

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
                    unreachable; // tried to register a tickable for an object which does not implement tick
                }
            }
            try self.tickables.append(self.allocator, newIndex);
        }

        return newObjectPtr;
    }

    pub fn tick(self: *@This()) void {
        const newTime = time.getEngineTime();
        self.deltaTime = newTime - self.lastEngineTime;

        for (self.tickables.items) |index| {
            const objectRef = self.rttiObjects.items[index];
            objectRef.vtable.tick_func.?(objectRef.ptr, self.deltaTime);
        }
        self.lastEngineTime = newTime;
    }

    pub fn run(self: *@This()) void {
        while (!self.exitSignal) {
            self.tick();
            // std.debug.print("\r frame time = {d} fps = {d}", .{ self.deltaTime, 1.0 / self.deltaTime });
        }
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
