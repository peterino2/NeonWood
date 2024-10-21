const std = @import("std");

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
