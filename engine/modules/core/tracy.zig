const std = @import("std");
const core = @import("../core.zig");
const CStr = core.CStr;
pub const ctracy = @cImport({
    @cDefine("TRACY_ENABLE", "1");
    @cDefine("TRACY_HAS_CALLSTACK", "0");
    @cInclude("TracyC.h");
});

// Tracy integration
pub const TracyFrame = struct {
    name: CStr,

    pub fn end(self: *@This()) void {
        ctracy.___tracy_emit_frame_mark_end(self.name);
    }
};

pub inline fn frame(name: ?[*c]const u8) TracyFrame {
    const f = TracyFrame{
        .name = if (name) |n| n else "default",
    };

    ctracy.___tracy_emit_frame_mark_start(f.name);
    return f;
}

pub const ZoneContext = struct {
    zone: ctracy.___tracy_c_zone_context,

    pub fn end(self: ZoneContext) void {
        ctracy.___tracy_emit_zone_end(self.zone);
    }
};

pub inline fn trace(comptime src: std.builtin.SourceLocation, name: ?[*c]const u8) ZoneContext {
    const location: ctracy.___tracy_source_location_data = .{
        .name = if (name) |n| n else null,
        .function = src.fn_name.ptr,
        .file = src.file.ptr,
        .line = src.line,
        .color = 0,
    };

    return ZoneContext{
        .zone = ctracy.___tracy_emit_zone_begin_callstack(&location, 1, 1),
    };
}
