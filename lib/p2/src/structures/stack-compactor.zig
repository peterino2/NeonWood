const std = @import("std");

pub fn hashStackList(stack: []const usize) u32 {
    var c: u32 = 0;
    for (stack) |l| {
        c = combineHash32(c, hashPtr(l));
    }
    return c;
}

pub inline fn combineHash32(lhs: u32, rhs: u32) u32 {
    return lhs ^ (rhs +% 0x9e3779b9 +% (lhs << 6) +% (lhs >> 2));
}

pub inline fn hashPtr(value: usize) u32 {
    var k = value +% 1;

    if (@sizeOf(@TypeOf(value)) == 8) {
        k = (~k) +% (k << 18);
        k = k ^ std.math.rotr(usize, k, 31);
        k = @mulWithOverflow(k, 21)[0];
        k = k ^ std.math.rotr(usize, k, 11);
        k = k +% (k << 6);
        k = k ^ std.math.rotr(usize, k, 22);
        return @truncate(k);
    } else {}
}

test "test hash64s" {
    const pointers: []const usize = &.{
        0x0,
        0x1,
        0xffffffff1eed1234,
        0xffffffff_ffffffff,
        0xffffffff_ffffffff - 1,
    };
    var combined: u32 = 0;

    for (pointers) |l| {
        const h = hashPtr(l);
        std.debug.print("l = {x}, hash = {x}\n", .{ l, h });
        combined = combineHash32(combined, h);
    }
    std.debug.print("combined hash = {x} ({x})\n", .{ combined, hashStackList(pointers) });
}

// lhs ^= rhs + 0x9e3779b9 + (lhs << 6) + (lhs >> 2);
// lhs ^= rhs + 0x517cc1b727220a95 + (lhs << 6) + (lhs >> 2);
pub const StackCompactor = struct {
    allocator: std.mem.Allocator,
    stackArena: std.heap.ArenaAllocator, // todo. replace with p2.BumpArena
    stackMap: std.AutohashMapUnmanaged(u32, []usize) = .{},

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
            .stackArena = std.heap.ArenaAllocator.init(allocator),
        };

        return self;
    }

    pub fn addNewCallstack(self: @This(), stack: []const usize) !void {
        const hash = hashStackList(stack);
        if (!self.stackMap.contains(hash)) {}
    }

    pub fn deinit(self: @This()) void {
        self.stackList.deinit(self.allocator);
        self.allocator.destroy(self);
    }
};

pub fn walkAndPrintStack() void {
    var context: std.debug.ThreadContext = undefined;
    const has_context = std.debug.getContext(&context);

    if (!has_context) {
        return;
    }

    var addr_buf: [1024]usize = undefined;
    const n = std.debug.walkStackWindows(addr_buf[0..], &context);

    const debug_info = std.debug.getSelfDebugInfo() catch {
        return;
    };
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        const address = addr_buf[i];

        const module = debug_info.getModuleForAddress(address) catch continue;
        const symbol_info = module.getSymbolAtAddress(debug_info.allocator, address) catch continue;

        std.debug.print("@0x{x} symbol_name: {s} {s} > ", .{ address, symbol_info.symbol_name, symbol_info.compile_unit_name });

        if (symbol_info.line_info) |line_info| {
            std.debug.print(" {s}:{d}\n", .{ line_info.file_name, line_info.line });
        } else {
            std.debug.print(" no file info\n", .{});
        }
    }
}
