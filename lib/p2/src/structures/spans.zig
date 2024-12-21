const std = @import("std");
const PagedVector = @import("paged-vector.zig").PagedVector;

pub const Span = struct {
    start: u32,
    size: u32,

    pub fn end(self: @This()) u32 {
        return self.start + self.size;
    }
};

pub const SpanHandle = struct {
    _index: i32 = 0,
};

pub const AllocatedSpan = struct {
    handle: SpanHandle,
    span: Span,
};

pub const MergedSpan = struct {
    start: u32,
    end: u32, // points to one-past-the-end, invalid to deref
    index: u32,
    next: ?*MergedSpan = null,
};

pub const MergedSpans = struct {
    list: ?*MergedSpan,
    capacity: u32,
    available: u32,
    spans: PagedVector(MergedSpan),

    pub fn init(allocator: std.mem.Allocator, capacity: u32) !@This() {
        return .{
            .list = null,
            .spans = try PagedVector(MergedSpan).init(allocator),
            .capacity = capacity,
            .available = capacity,
        };
    }

    pub fn allocate(self: *@This(), size: u32) !Span {

        // 1. find the first gap that matches the size
        // 2. create a span from that gap and call addSpan on it.
        var newSpan: ?Span = null;
        var predecessor: ?*MergedSpan = null;

        if (self.list) |list| {
            var iter: ?*MergedSpan = list;

            while (iter) |p| : (iter = p.next) {
                const gapStart = p.end;
                var gapSize = self.capacity - gapStart;
                if (p.next) |_next| {
                    const next: *MergedSpan = _next;
                    gapSize = next.start - p.end;
                }

                if (gapSize >= size) {
                    predecessor = p;
                    newSpan = .{ .start = gapStart, .size = size };
                    break;
                }
            }
        } else {
            // handle special case where we are empty and nothing is used.
            if (size <= self.capacity) {
                newSpan = .{ .start = 0, .size = size };
            }
        }

        if (newSpan) |n| {
            try self.addSpan(n, predecessor);
            return n;
        }

        return error.OutOfMemory;
    }

    pub fn addSpan(self: *@This(), span: Span, predecessor: ?*MergedSpan) !void {

        // update stats
        self.available -= span.size;

        // if the predecessor is null, this is the first span that we have, just set it and move on.
        if (predecessor) |p| {
            // if we're touching the end of one span, grow that one.
            if (p.end == span.start) {
                p.end += span.size;

                if (p.next) |next| {
                    if (next.start == span.start + span.size) {
                        // delete the next one and update predecessor's end to the next one
                        p.end = next.end;
                        p.next = next.next;

                        self.removeMergedSpan(next);
                    }
                }
            } else if (p.next) |next| {
                // if we're touching the start of one span, grow that one
                if (next.start == span.start + span.size) {
                    next.start = span.start;
                }
            } else {
                // if neither, then, create a new
                const newSpan = try self.spans.appendAndGet(.{
                    .start = span.start,
                    .end = span.start + span.size,
                    .next = p.next,
                    .index = @intCast(self.spans.len()),
                });
                p.next = newSpan;
            }
        } else {
            self.list = try self.spans.appendAndGet(.{
                .start = 0,
                .end = span.size,
                .next = null,
                .index = @intCast(self.spans.len()),
            });
        }
    }

    fn removeMergedSpan(self: *@This(), remove: *MergedSpan) void {
        self.spans.getMutable(self.spans.len() - 1).index = remove.index;
        self.spans.swapRemove(remove.index);
    }

    pub fn debugSpanCount(self: @This()) u32 {
        var i: u32 = 0;
        var iter = self.list;

        while (iter) |p| : (iter = p.next) {
            i += 1;
        }

        return i;
    }

    pub fn removeSpan(self: *@This(), span: Span) void {
        self.available += span.size;
        var iter = self.list;
        while (iter) |p| : (iter = p.next) {
            if (p.start <= span.start and p.start < p.end) {
                if (p.start == span.start) {
                    // we cover the start of that span, we can push the span's start to our end.
                    p.start = span.end();
                }
                if (p.end == span.start + span.size) {
                    // we cover the end of that span. we can shrink that span
                    p.end = span.start;
                }

                // if we are within this span, then we need to split the span into two.
                if (span.start > p.start and span.end() < p.end) {
                    // create the new span, starting at the end of our free'd span
                    const newSpan = self.spans.appendAndGet(.{
                        .end = p.end,
                        .next = p.next,
                        .start = span.end(),
                        .index = @intCast(self.spans.len()),
                    }) catch unreachable;
                    p.end = span.start;
                    p.next = newSpan;
                }
            }
        }
    }

    pub fn deinit(self: *@This()) void {
        self.spans.deinit();
    }
};

test "span allocation" {
    const allocator = std.testing.allocator;
    var spans = try MergedSpans.init(allocator, 4096);
    defer spans.deinit();

    const newSpan: Span = try spans.allocate(16);
    try std.testing.expectEqual(0, newSpan.start);
    try std.testing.expectEqual(16, newSpan.size);

    const newSpan2: Span = try spans.allocate(16);
    try std.testing.expectEqual(16, newSpan2.start);
    try std.testing.expectEqual(16, newSpan2.start);

    const newSpan3: Span = try spans.allocate(16);
    try std.testing.expectEqual(32, newSpan3.start);
    try std.testing.expectEqual(16, newSpan3.size);

    try std.testing.expectEqual(spans.debugSpanCount(), 1);

    const newSpan4: Span = try spans.allocate(16);
    try std.testing.expectEqual(48, newSpan4.start);
    try std.testing.expectEqual(16, newSpan4.size);

    spans.removeSpan(.{ .start = 12, .size = 4 });
    try std.testing.expectEqual(2, spans.debugSpanCount());

    const newSpan5: Span = try spans.allocate(4);
    try std.testing.expectEqual(12, newSpan5.start);
    try std.testing.expectEqual(4, newSpan5.size);
    try std.testing.expectEqual(1, spans.debugSpanCount());

    spans.removeSpan(.{ .start = 12, .size = 1 });
    spans.removeSpan(.{ .start = 14, .size = 1 });
    try std.testing.expectEqual(3, spans.debugSpanCount());

    _ = try spans.allocate(1);
    _ = try spans.allocate(1);

    try std.testing.expectEqual(1, spans.debugSpanCount());
}
