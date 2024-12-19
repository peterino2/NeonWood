const std = @import("std");

pub const Span = struct {
    start: u32,
    size: u32,
};

pub const SpanAllocations = struct {
    size: u32,
    used: std.ArrayListUnmanaged(Span),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: usize) @This() {
        return .{
            .size = size,
            .allocator = allocator,
            .used = .{},
        };
    }

    pub fn allocate(self: *@This(), newSize: u32) Span {

        var gapStart: u32 = 0;
        var gapEnd: u32 = 0;
        // iterate over spans, from smallest value to largest
        // find the first gap that matches or exceeds the size
        
        for(self.used.items) |span|
        {
            gapEnd = span.start;
            const gapSize = gapEnd - gapStart;

            if(gapSize >= newSize)
            {
                break;
            }
        }

        // take that span and add it to the span list.
    }
};

test "span allocation" {
    const allocator = std.testing.allocator;

    var spans = SpanAllocations.init(allocator, );

}
