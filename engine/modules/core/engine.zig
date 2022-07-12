const std = @import("std");
const logging = @import("logging.zig");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const engine_log = logging.engine_log;

pub const Engine = struct {
    subsystems: ArrayList(*anyopaque),
    subsystemsByType: AutoHashMap(std.builtin.Type, usize),
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) !@This() {
        const rv = Engine{
            .subsystems = ArrayList(*anyopaque).init(alloc),
            .subsystemsByType = AutoHashMap(std.builtin.Type, usize).init(alloc),
            .alloc = alloc,
        };

        return rv;
    }

    pub fn addSubsystem(self: *@This(), comptime subsystem: anytype) !void {
        const typeInfo = @typeInfo(subsystem);
        switch (typeInfo) {
            .Pointer => |pointer| {
                const nextId = self.subsystems.items.len;
                self.subsystems.append(pointer);
                self.subsystemsByType.put(typeInfo, nextId);
            },
            _ => {},
        }
    }

    pub fn getSubsystem(self: *@This(), comptime subsystemType: type) ?*subsystemType {
        const typeInfo = @typeInfo(subsystemType);
        if (self.subsystemsByType.contains(typeInfo)) {
            return @ptrCast(*subsystemType, self.subsystemsByType.getPtr.?.*);
        }
        return null;
    }

    pub fn deinit(self: *@This()) void {
        self.subsystems.deinit();
        self.subsystemsByType.deinit();
    }
};

test "i think types should work here right" {
    // const alloc = std.testing.allocator;
    // var engine = Engine.init(alloc);
    // defer engine.deinit();

    const struct1 = struct {
        name: []const u8,
    };

    const struct1_inst = struct1{ .name = "struct1" };

    const anonstruct = struct {
        name: []const u8,

        pub fn init() @This() {
            return @This(){ .name = "takyon" };
        }
    }.init();

    const anon2 = @TypeOf(anonstruct).init();

    // engine.addSubsystem(&struct1_inst);
    // engine.addSubsystem(&anonstruct);

    // std.debug.print("{s}\n", .{engine.getSubsystem(struct1).?.*.name});
    // std.debug.print("{s}\n", .{engine.getSubsystem(anonstruct).?.*.name});

    std.debug.print("{s}\n", .{@typeName(@TypeOf(struct1_inst))});
    std.debug.print("{s}\n", .{@typeName(@TypeOf(anonstruct))});
    std.debug.print("{s}\n", .{@typeName(@TypeOf(anon2))});
}
