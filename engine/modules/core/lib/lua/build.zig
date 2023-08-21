const std = @import("std");

fn addCSourceFileShim(exe: anytype, comptime path: []const u8, flags: anytype) void {
    exe.addCSourceFile(.{ .file = .{ .path = path }, .flags = flags });
}

pub fn addLib(b: *std.Build, exe: *std.build.CompileStep, comptime pathPrefix: []const u8) void {
    var cflags = std.ArrayList([]const u8).init(b.allocator);
    defer cflags.deinit();

    exe.addIncludePath(.{ .path = pathPrefix ++ "/src" });
    exe.addIncludePath(.{ .path = pathPrefix ++ "/" });

    const src = pathPrefix ++ "/src/";

    addCSourceFileShim(exe, src ++ "lapi.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lauxlib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lbaselib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lcode.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lcorolib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lctype.c", cflags.items);
    addCSourceFileShim(exe, src ++ "ldblib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "ldebug.c", cflags.items);
    addCSourceFileShim(exe, src ++ "ldo.c", cflags.items);
    addCSourceFileShim(exe, src ++ "ldump.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lfunc.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lgc.c", cflags.items);
    addCSourceFileShim(exe, src ++ "linit.c", cflags.items);
    addCSourceFileShim(exe, src ++ "liolib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "llex.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lmathlib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lmem.c", cflags.items);
    addCSourceFileShim(exe, src ++ "loadlib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lobject.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lopcodes.c", cflags.items);
    addCSourceFileShim(exe, src ++ "loslib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lparser.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lstate.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lstring.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lstrlib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "ltable.c", cflags.items);
    addCSourceFileShim(exe, src ++ "ltablib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "ltm.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lundump.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lutf8lib.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lvm.c", cflags.items);
    addCSourceFileShim(exe, src ++ "lzio.c", cflags.items);
}
