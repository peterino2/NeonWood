const std = @import("std");
const logging = @import("logging.zig");
const names = @import("names.zig");
const input = @import("input.zig");

const Name = names.Name;
const MakeName = names.MakeName;

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const ArrayListUnmanaged = std.ArrayListUnmanaged;
const AutoHashMapUnmanaged = std.AutoHashMapUnmanaged;

// We actually don't need that many polymorphic types.
// this will primarily be an ecs focused engine.
// current goal: remove the graphics_test_run and move the renderer into the
// gEngine structure.

pub const RTTI_MAX_TYPES = 1024;

pub fn MakeTypeName(comptime TargetType: type) Name {
    const hashedName = comptime std.fmt.comptimePrint("{s}_{d}", .{ @typeName(TargetType), @sizeOf(TargetType) });

    return MakeName(hashedName);
}

pub const RttiData = struct {
    typeName: Name,
    typeSize: usize,

    init_func: fn (std.mem.Allocator, *anyopaque) void,
    tick_func: ?fn (*anyopaque, f64) void = null,

    pub fn from(comptime TargetType: type) RttiData {
        const wrappedInit = struct {
            const funcFind: @TypeOf(@field(TargetType, "init")) = @field(TargetType, "init");

            pub fn func(allocator: std.mem.Allocator, pointer: *anyopaque) void {
                @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer)).* = funcFind(allocator);
            }
        };

        var self = RttiData{
            .typeName = MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .init_func = wrappedInit.func,
        };

        if (@hasDecl(TargetType, "tick")) {
            const wrappedTick = struct {
                pub fn func(pointer: *anyopaque, deltaTime: f64) void {
                    var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                    ptr.tick(deltaTime);
                }
            };

            self.tick_func = wrappedTick.func;
        }

        return self;
    }
};

pub const TestStruct = struct {
    wanker: u32,
    timeAccumulation: f64 = 0.0,

    pub fn init(allocator: std.mem.Allocator) @This() {
        _ = allocator;
        std.debug.print("this is some real dynamic dispatch\n", .{});
        return .{ .wanker = 42069 };
    }

    pub fn tick(self: *@This(), deltaTime: f64) void {
        self.timeAccumulation += deltaTime;
        std.debug.print("ticking!: time = {d}\n", .{self.timeAccumulation});
    }
};

pub const TestStruct2 = struct {
    wanker: u32,

    pub fn init(allocator: std.mem.Allocator) @This() {
        _ = allocator;
        std.debug.print("test construction2\n", .{});
        return .{ .wanker = 42069 };
    }
};

test "test rtti data" {
    const types = [_]RttiData{
        RttiData.from(TestStruct),
        RttiData.from(TestStruct2),
    };

    var x: TestStruct = undefined;
    var y: TestStruct2 = undefined;

    types[0].init_func(std.testing.allocator, @ptrCast(*anyopaque, &x));
    types[1].init_func(std.testing.allocator, @ptrCast(*anyopaque, &y));

    for (types) |t, i| {
        std.debug.print("{d}: {s} (0x{x})\n", .{ i, t.typeName.utf8, t.typeName.hash });
    }

    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
    RttiData.from(@TypeOf(x)).tick_func.?(@ptrCast(*anyopaque, &x), 0.013);
}

pub const RttiWrapper = struct {
    ptr: *anyopaque,
    typeHash: u32,
};

pub const RttiRegistry = struct {
    entries: [RTTI_MAX_TYPES]RttiData,
    count: u32 = 0,

    pub fn init() @This() {
        var self = std.mem.zeroes(@This());

        return self;
    }

    pub fn dynamic_cast_by_id(self: @This(), TargetType: type, source: RttiWrapper) ?TargetType {
        _ = self;
        _ = TargetType;
        _ = source;
        return null;
    }
};
