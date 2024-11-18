const std = @import("std");
const core = @import("core.zig");
const BumpArena = core.BumpArena;

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

test "1 million stacks." {
    // see how fast i can walk 1 million stacks
    var timer = std.time.Timer.start() catch unreachable;
    const startTime = timer.read();
    for (0..100000) |_| {
        core.stacks.pushCallStack();
    }
    const endTime = timer.read();
    std.debug.print("timeElapsed 100k callstacks {d}s", .{@as(f64, @floatFromInt(endTime - startTime)) / 1000000000});
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

pub const StackCompactor = struct {
    allocator: std.mem.Allocator,
    stackArena: BumpArena,
    stackMap: std.AutoHashMapUnmanaged(u32, *CallStack) = .{},
    const CallStack = struct {
        pointers: []usize,
        debugStr: []?[]u8,
    };

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
            .stackArena = try BumpArena.init(allocator),
        };

        return self;
    }

    pub fn addNewCallstack(self: *@This(), stack: []const usize) !u32 {
        const hash = hashStackList(stack);
        const bumpAllocator = self.stackArena.allocator();

        if (!self.stackMap.contains(hash)) {
            const ownedStack: *CallStack = try bumpAllocator.create(CallStack);
            ownedStack.pointers = try bumpAllocator.dupe(usize, stack);
            ownedStack.debugStr = try bumpAllocator.alloc(?[]u8, stack.len);

            const debug_info = std.debug.getSelfDebugInfo() catch {
                try self.stackMap.put(self.allocator, hash, ownedStack);
                return hash;
            };

            for (stack, 0..) |address, i| {
                ownedStack.debugStr[i] = null;

                const module = debug_info.getModuleForAddress(address) catch continue;
                const symbol_info = module.getSymbolAtAddress(debug_info.allocator, address) catch continue;

                if (symbol_info.line_info) |line_info| {
                    ownedStack.debugStr[i] = try std.fmt.allocPrintZ(
                        bumpAllocator,
                        "{d}> @0x{x} symbol_name: {s} {s} > {s}: {d}",
                        .{ i, address, symbol_info.symbol_name, symbol_info.compile_unit_name, line_info.file_name, line_info.line },
                    );
                } else {
                    ownedStack.debugStr[i] = try std.fmt.allocPrintZ(
                        bumpAllocator,
                        "{d}> @0x{x} symbol_name: {s} {s} > no file info",
                        .{ i, address, symbol_info.symbol_name, symbol_info.compile_unit_name },
                    );
                }
            }

            try self.stackMap.put(self.allocator, hash, ownedStack);
        }
        return hash;
    }

    pub fn deinit(self: @This()) void {
        self.stackList.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn getCallStack(self: *@This()) u32 {
        var context: std.debug.ThreadContext = undefined;
        const has_context = std.debug.getContext(&context);

        if (!has_context) {
            return;
        }

        var addr_buf: [1024]usize = undefined;
        const n = std.debug.walkStackWindows(addr_buf[0..], &context);

        return self.addNewCallstack(addr_buf[0..n]) catch unreachable;
    }
};

var stackCompactor: *core.StackCompactor = undefined;

pub fn initStackCompactor() void {
    stackCompactor = core.StackCompactor.create(std.heap.c_allocator) catch unreachable;
}

pub inline fn pushCallStack() void {
    var context: std.debug.ThreadContext = undefined;
    const has_context = std.debug.getContext(&context);

    if (!has_context) {
        return;
    }

    var addr_buf: [1024]usize = undefined;
    const n = std.debug.walkStackWindows(addr_buf[0..], &context);

    stackCompactor.addNewCallstack(addr_buf[0..n]) catch unreachable;
}

pub fn getStackCompactor() *StackCompactor {
    return stackCompactor;
}

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
