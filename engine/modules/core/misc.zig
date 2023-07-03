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
        inline for (r, 0..) |val, i| {
            r[i] = val + i;
        }
    }

    return comptime r;
}

pub fn slice_to_cstr(str: []const u8) ?[*:0]const u8 {
    return @as(?[*:0]const u8, @ptrCast(str.ptr));
}

pub fn buf_to_cstr(str: anytype) ?[*:0]const u8 {
    return @as(?[*:0]const u8, @ptrCast(&str[0]));
}

pub const CStr = [*:0]const u8;

pub fn debug_struct(preamble: []const u8, s: anytype) void {
    logging.graphics_log("{s}:", .{preamble});
    logging.graphics_log("  {any}", .{s});
}

pub fn p_to_a(a: anytype) [*]const @TypeOf(a.*) {
    return @as([*]const @TypeOf(a.*), @ptrCast(a));
}

pub fn p_to_av(a: anytype) [*]@TypeOf(a.*) {
    return @as([*]@TypeOf(a.*), @ptrCast(a));
}
