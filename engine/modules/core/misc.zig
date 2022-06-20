// Random misc. utilities that aren't /totally/ categorized right now.

const logging = @import("logging.zig");

// Creates a for-loopable range between [0, n)
pub fn count(comptime n: anytype) [n]u0 {
    return comptime [1]u0{0} ** n;
}

// Creates a for-loopable range between [start, end).
// reccomended for use with inline FORs
pub fn range(comptime start: usize, comptime end: anytype) [end - start]@TypeOf(start) {
    comptime var r = [1]@TypeOf(start){start} ** (end - start);

    comptime {
        inline for (r) |val, i| {
            r[i] = val + i;
        }
    }

    return comptime r;
}

pub fn slice_to_cstr(str: []const u8) ?[*:0]const u8 {
    return @ptrCast(?[*:0]const u8, str.ptr);
}

pub fn buf_to_cstr(str: anytype) ?[*:0]const u8 {
    return @ptrCast(?[*:0]const u8, &str[0]);
}
