const std = @import("std");
const paged_vector = @import("paged-vector.zig");
const builtin = @import("builtin");

const PagedVectorAdvanced = paged_vector.PagedVectorAdvanced;

pub const NameRegistryStatus = enum {
    Ok,
    OutOfMemory,
};

pub const NameInvalid: Name = .{ .index = 0 };

const NameInvalidComptimeString = "Invalid";

// trying out a names scheme similar in vein to unreal engine's FNames
pub const NameRegistry = struct {
    allocator: std.mem.Allocator,
    map: std.StringHashMapUnmanaged(u32),
    pagedVector: PagedVectorAdvanced([]const u8, 1024),
    stringArena: std.heap.ArenaAllocator,
    mutex: std.Thread.Mutex = .{},

    // with this system errors should be nonexistent
    // as a result I downgrade all errors into this error status field.
    // I think the enhanced ergonomics of being able to use names ubiquitously is worth losing the
    // immediate handling of the trace.
    //
    // usage of names should be null checked anyway.
    errorStatus: NameRegistryStatus = .Ok,

    pub fn init(allocator: std.mem.Allocator) !@This() {
        var self = @This(){
            .allocator = allocator,
            .stringArena = std.heap.ArenaAllocator.init(allocator),
            .map = .{},
            .pagedVector = try PagedVectorAdvanced([]const u8, 1024).init(allocator),
        };

        _ = self.InstallNameInner(NameInvalidComptimeString, false);
        return self;
    }

    pub fn count(self: @This()) u32 {
        return @intCast(self.pagedVector.len());
    }

    pub fn name(self: *@This(), nameString: []const u8) Name {
        const index = self.InstallNameInner(nameString, true);

        return .{
            .index = index,
            .string = self.pagedVector.get(index).*,
        };
    }

    fn InstallNameInner(self: *@This(), nameString: []const u8, shouldCopy: bool) u32 {
        self.mutex.lock();
        defer self.mutex.unlock();

        var newString = nameString;
        // check if the string exists if it does just return it as a name.
        if (self.map.get(newString)) |index| {
            return index;
        }

        if (shouldCopy) {
            var allocator = self.stringArena.allocator();
            newString = allocator.dupe(u8, nameString) catch {
                self.errorStatus = .OutOfMemory;
                @panic("Out of memory during name operation");
            };
        }

        // add to registry
        const newIndex = @as(u32, @intCast(self.pagedVector.len()));
        self.pagedVector.append(self.allocator, newString) catch {
            self.errorStatus = .OutOfMemory;
            @panic("Out of memory during name operation");
        };

        self.map.put(self.allocator, newString, newIndex) catch {
            self.errorStatus = .OutOfMemory;
            @panic("Out of memory during name operation");
        };

        return newIndex;
    }

    pub fn deinit(self: *@This()) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.map.deinit(self.allocator);
        self.pagedVector.deinit(self.allocator);
        self.stringArena.deinit();
    }
};

pub var gRegistry: *NameRegistry = undefined;
var registryCreated: bool = false;

pub fn createNameRegistry(allocator: std.mem.Allocator) !*NameRegistry {
    gRegistry = try allocator.create(NameRegistry);
    gRegistry.* = try NameRegistry.init(allocator);
    registryCreated = true;
    return gRegistry;
}

pub fn getRegistry() *NameRegistry {
    // specifically in the case of unittests we can silently just initialize a temporary registry
    if (builtin.is_test) {
        if (!registryCreated) {
            // leaking here is fine? might piss off valgrind
            _ = createNameRegistry(std.heap.c_allocator) catch unreachable;
        }
    }

    return gRegistry;
}

pub fn destroyNameRegistry() void {
    var allocator = gRegistry.allocator;
    gRegistry.deinit();
    allocator.destroy(gRegistry);
}

pub fn MakeName(string: []const u8) Name {
    return Name.MakeComptime(string);
}

pub const Name = struct {
    index: ?u32 = 0,
    string: []const u8 = "Invalid",

    pub fn MakeComptime(string: []const u8) @This() {
        return .{ .index = null, .string = string };
    }

    pub fn Make(string: []const u8) @This() {
        return getRegistry().name(string);
    }

    pub fn fromUtf8(string: []const u8) @This() {
        return getRegistry().name(string);
    }

    pub fn handle(self: *const @This()) u32 {
        if (self.index == null) {
            const index = getRegistry().InstallNameInner(self.string, false);
            const mutableThis = @as(*@This(), @ptrCast(@constCast(self)));
            mutableThis.*.index = index;
        }

        return self.index.?;
    }

    pub fn utf8(self: *const @This()) []const u8 {
        // so nasty... and const-violating. but the ergonomics is so good...
        if (self.index == null) {
            // fuck it..  i'll pay the cost of duplicating even comptime strings
            const index = getRegistry().InstallNameInner(self.string, true);
            const mutableThis = @as(*@This(), @ptrCast(@constCast(self)));
            mutableThis.*.index = index;
        }

        return getRegistry().pagedVector.get(self.index.?).*;
    }

    pub fn eql(self: *const @This(), other: *const @This()) bool {
        if (self.index == null) {
            const index = getRegistry().InstallNameInner(self.string, false);
            const mutableThis = @as(*@This(), @ptrCast(@constCast(self)));
            mutableThis.*.index = index;
        }

        if (other.index == null) {
            const index = getRegistry().InstallNameInner(self.string, false);
            const mutableThis = @as(*@This(), @ptrCast(@constCast(self)));
            mutableThis.*.index = index;
        }

        return self.index == other.index;
    }
};

test "zname initialization and lookup" {
    _ = try createNameRegistry(std.testing.allocator);
    defer destroyNameRegistry();

    const testComptimeName = "This is a name test";
    const testComptimeName2 = "This is another name test";

    var r = getRegistry();
    var name = MakeName(testComptimeName);
    var name2 = r.name(testComptimeName);
    var name4 = r.name(testComptimeName2);

    const fmtString = try std.fmt.allocPrint(std.testing.allocator, "morty I did horrible things to your {s}.", .{"locally elected representative"});
    defer std.testing.allocator.free(fmtString);

    var name3 = r.name(fmtString);

    try std.testing.expectEqualSlices(u8, testComptimeName, name.utf8());
    try std.testing.expectEqualSlices(u8, testComptimeName, name2.utf8());
    try std.testing.expect(name2.eql(&name));
    try std.testing.expect(!name3.eql(&name));

    var uninitializedName: Name = .{};
    try std.testing.expect(uninitializedName.eql(&r.name("Invalid")));
    try std.testing.expect(!name4.eql(&name3));

    try std.testing.expectEqualSlices(u8, name3.utf8(), fmtString);
}
