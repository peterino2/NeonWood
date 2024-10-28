const std = @import("std");
const paged_vector = @import("paged-vector.zig");
const PagedVectorAdvanced = paged_vector.PagedVectorAdvanced;

// non-threadsafe, fast bump-only allocator
pub const BumpArena = struct {
    const PageSize = 8192 * 2;
    const SmallAllocPages = paged_vector.PagedVectorAdvanced([PageSize]u8, 1);

    smallBumpOffset: usize = 0,
    pageIndex: usize = 0,

    backing: std.mem.Allocator,
    small: SmallAllocPages,
    large: std.heap.ArenaAllocator,
    mutex: std.Thread.Mutex,

    pub var vtable: std.mem.Allocator.VTable = .{
        .alloc = alloc,
        .free = free,
        .resize = resize,
    };

    pub fn init(backing: std.mem.Allocator) !@This() {
        return .{
            .backing = backing,
            .small = try SmallAllocPages.init(backing),
            .large = std.heap.ArenaAllocator.init(backing),
            .mutex = .{},
        };
    }

    pub fn deinit(self: *@This()) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.small.deinit(self.backing);
        self.large.deinit();
    }

    fn respectAlignment(offset: usize, alignment: u8) usize {
        if (offset == 0) {
            return 0;
        }
        const a: usize = @intCast(@as(usize, @intCast(1)) << @as(u6, @truncate(alignment)));
        return ((offset / a) + 1) * @as(usize, @intCast(a));
    }

    pub fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
        const self: *@This() = @ptrCast(@alignCast(ctx));

        self.mutex.lock();
        defer self.mutex.unlock();

        if (len > 4096) {
            return self.largeAllocator().vtable.alloc(self.largeAllocator().ptr, len, ptr_align, ret_addr);
        } else {
            const currentPageFree = PageSize - self.smallBumpOffset;
            if (len < currentPageFree) {
                const alignedOffset = respectAlignment(self.smallBumpOffset, ptr_align);
                const rv = self.small.getMutable(self.pageIndex)[alignedOffset .. alignedOffset + len];
                // std.debug.print("original offset {d} respected offset {d} alignment {d} address: {x}\n", .{ self.smallBumpOffset, alignedOffset, ptr_align, @intFromPtr(rv.ptr) });
                self.smallBumpOffset = alignedOffset + len;
                return rv.ptr;
            } else {
                // new allocation exceeds the remaining size of this page
                self.pageIndex += 1;
                self.smallBumpOffset = len;
                self.small.append(self.backing, undefined) catch return null;
                return self.small.getMutable(self.pageIndex)[0..len].ptr;
            }
        }

        unreachable;
    }

    inline fn largeAllocator(self: *@This()) std.mem.Allocator {
        return self.large.allocator();
    }

    pub fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
        // it's a bump allocator, it does nothing on free.
        _ = ctx;
        _ = buf;
        _ = buf_align;
        _ = ret_addr;
    }

    pub fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
        _ = ctx;
        _ = buf;
        _ = buf_align;
        _ = new_len;
        _ = ret_addr;

        return false;
    }

    pub fn allocator(self: *@This()) std.mem.Allocator {
        return .{ .ptr = self, .vtable = &vtable };
    }

    pub fn reset(self: *@This()) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.large.reset(.free_all);
        self.small.reset(self.backing);
        self.smallBumpOffset = 0;
        self.latestPageFree = PageSize;
        self.pageIndex = 0;
    }
};

test "bump-it-uppp" {
    var arena = try BumpArena.init(std.testing.allocator);
    defer arena.deinit();
}
