const std = @import("std");
const logging = @import("logging.zig");
const names = @import("names.zig");
const input = @import("input.zig");
const algorithm = @import("lib/p2/algorithm.zig");
const engine_logs = logging.engine_logs;

const ObjectHandle = algorithm.ObjectHandle;
const Name = names.Name;
const MakeName = names.MakeName;

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const ArrayListUnmanaged = std.ArrayListUnmanaged;
const AutoHashMapUnmanaged = std.AutoHashMapUnmanaged;

pub fn InterfaceRef(comptime Vtable: type) type {
    return struct {
        ptr: *anyopaque,
        vtable: *const Vtable,
    };
}

// We actually don't need that many polymorphic types.
// this will primarily be an ecs focused engine.
// current goal: remove the graphics_test_run and move the renderer into the
// gEngine structure.

pub const RTTI_MAX_TYPES = 1024;

pub fn MakeTypeName(comptime TargetType: type) Name {
    const hashedName = comptime std.fmt.comptimePrint("{s}_{d}", .{ @typeName(TargetType), @sizeOf(TargetType) });

    return MakeName(hashedName);
}

pub const RttiDataEventError = error{
    UnknownStatePanic,
    BadInit,
};

pub const RttiData = struct {
    typeName: Name,
    typeSize: usize,
    typeAlign: usize,

    init_func: *const fn (std.mem.Allocator) RttiDataEventError!*anyopaque,
    tick_func: ?*const fn (*anyopaque, f64) void = null,
    deinit_func: ?*const fn (*anyopaque) void = null,
    postInit_func: ?*const fn (*anyopaque) RttiDataEventError!void = null,
    processEvents: ?*const fn (*anyopaque, u64) RttiDataEventError!void = null,

    pub fn from(comptime TargetType: type) RttiData {
        const wrappedInit = struct {
            const funcFind: @TypeOf(@field(TargetType, "init")) = @field(TargetType, "init");

            pub fn func(allocator: std.mem.Allocator) RttiDataEventError!*anyopaque {
                engine_logs("calling init function");
                var newObject = funcFind(allocator) catch return error.BadInit;
                return @as(*anyopaque, @ptrCast(newObject));
            }
        };

        var self = RttiData{
            .typeName = MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .init_func = wrappedInit.func,
        };

        if (@hasDecl(TargetType, "postInit")) {
            const wrappedPostInit = struct {
                pub fn func(pointer: *anyopaque) RttiDataEventError!void {
                    var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                    try ptr.postInit();
                }
            };

            self.postInit_func = wrappedPostInit.func;
        }

        if (@hasDecl(TargetType, "tick")) {
            const wrappedTick = struct {
                pub fn func(pointer: *anyopaque, deltaTime: f64) void {
                    var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                    ptr.tick(deltaTime);
                }
            };

            self.tick_func = wrappedTick.func;
        }

        if (@hasDecl(TargetType, "processEvents")) {
            const wrappedProcessEvents = struct {
                pub fn func(pointer: *anyopaque, frameNumber: u64) RttiDataEventError!void {
                    var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                    try ptr.processEvents(frameNumber);
                }
            };

            self.processEvents = wrappedProcessEvents.func;
        }

        if (@hasDecl(TargetType, "deinit")) {
            const wrappedDeinit = struct {
                pub fn func(pointer: *anyopaque) void {
                    var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                    ptr.deinit();
                }
            };

            self.deinit_func = wrappedDeinit.func;
        }

        return self;
    }
};

pub const NeonObjectRef = InterfaceRef(RttiData);

const TestStruct = struct {

    // Static interface to being a rttiObject
    pub const NeonObjectTable = RttiData.from(TestStruct);

    wanker: u32,
    timeAccumulation: f64 = 0.0,

    pub fn init(allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        std.debug.print("this is some real dynamic dispatch\n", .{});
        return .{ .wanker = 42069 };
    }

    pub fn tick(self: *@This(), deltaTime: f64) void {
        self.timeAccumulation += deltaTime;
        std.debug.print("ticking!: time = {d}\n", .{self.timeAccumulation});
    }
};

const TestStruct2 = struct {
    wanker: u32,

    pub fn init(allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        std.debug.print("test construction2\n", .{});
        return .{ .wanker = 69420 };
    }
};

test "test rtti data" {
    const types = [_]RttiData{
        RttiData.from(TestStruct),
        RttiData.from(TestStruct2),
    };

    var x: TestStruct = undefined;
    var y: TestStruct2 = undefined;

    types[0].init_func(std.testing.allocator, @as(*anyopaque, @ptrCast(&x)));
    types[1].init_func(std.testing.allocator, @as(*anyopaque, @ptrCast(&y)));

    for (types, 0..) |t, i| {
        std.debug.print("{d}: {s} (0x{x})\n", .{ i, t.typeName.utf8, t.typeName.hash });
    }

    RttiData.from(@TypeOf(x)).tick_func.?(@as(*anyopaque, @ptrCast(&x)), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@as(*anyopaque, @ptrCast(&x)), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@as(*anyopaque, @ptrCast(&x)), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@as(*anyopaque, @ptrCast(&x)), 0.013);
    (&TestStruct.NeonObjectTable).tick_func.?(@as(*anyopaque, @ptrCast(&x)), 0.013);
    try std.testing.expect(x.wanker == 42069);
    try std.testing.expect(y.wanker == 69420);
}
