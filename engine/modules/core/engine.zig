const std = @import("std");
const logging = @import("logging.zig");
const names = @import("names.zig");
const input = @import("input.zig");
const Name = names.Name;
const MakeName = names.MakeName;

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const engine_log = logging.engine_log;

pub const Engine = struct {
    exitSignal: bool,

    subsystems: ArrayList(*anyopaque),
    subsystemsByType: AutoHashMap(u32, usize),
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) !@This() {
        const rv = Engine{
            .subsystems = ArrayList(*anyopaque).init(alloc),
            .subsystemsByType = AutoHashMap(u32, usize).init(alloc),
            .alloc = alloc,
            .exitSignal = false,
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
