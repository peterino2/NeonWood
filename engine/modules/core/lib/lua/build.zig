const std = @import("std");

pub fn addLib(b: *std.Build, exe: *std.build.CompileStep, comptime pathPrefix: []const u8) void {
    var cflags = std.ArrayList([]const u8).init(b.allocator);
    defer cflags.deinit();

    exe.addIncludePath(pathPrefix ++ "/src");
    exe.addIncludePath(pathPrefix ++ "/");

    const src = pathPrefix ++ "/src/";

    exe.addCSourceFile(src ++ "lapi.c", cflags.items);
    exe.addCSourceFile(src ++ "lauxlib.c", cflags.items);
    exe.addCSourceFile(src ++ "lbaselib.c", cflags.items);
    exe.addCSourceFile(src ++ "lcode.c", cflags.items);
    exe.addCSourceFile(src ++ "lcorolib.c", cflags.items);
    exe.addCSourceFile(src ++ "lctype.c", cflags.items);
    exe.addCSourceFile(src ++ "ldblib.c", cflags.items);
    exe.addCSourceFile(src ++ "ldebug.c", cflags.items);
    exe.addCSourceFile(src ++ "ldo.c", cflags.items);
    exe.addCSourceFile(src ++ "ldump.c", cflags.items);
    exe.addCSourceFile(src ++ "lfunc.c", cflags.items);
    exe.addCSourceFile(src ++ "lgc.c", cflags.items);
    exe.addCSourceFile(src ++ "linit.c", cflags.items);
    exe.addCSourceFile(src ++ "liolib.c", cflags.items);
    exe.addCSourceFile(src ++ "llex.c", cflags.items);
    exe.addCSourceFile(src ++ "lmathlib.c", cflags.items);
    exe.addCSourceFile(src ++ "lmem.c", cflags.items);
    exe.addCSourceFile(src ++ "loadlib.c", cflags.items);
    exe.addCSourceFile(src ++ "lobject.c", cflags.items);
    exe.addCSourceFile(src ++ "lopcodes.c", cflags.items);
    exe.addCSourceFile(src ++ "loslib.c", cflags.items);
    exe.addCSourceFile(src ++ "lparser.c", cflags.items);
    exe.addCSourceFile(src ++ "lstate.c", cflags.items);
    exe.addCSourceFile(src ++ "lstring.c", cflags.items);
    exe.addCSourceFile(src ++ "lstrlib.c", cflags.items);
    exe.addCSourceFile(src ++ "ltable.c", cflags.items);
    exe.addCSourceFile(src ++ "ltablib.c", cflags.items);
    exe.addCSourceFile(src ++ "ltm.c", cflags.items);
    exe.addCSourceFile(src ++ "lundump.c", cflags.items);
    exe.addCSourceFile(src ++ "lutf8lib.c", cflags.items);
    exe.addCSourceFile(src ++ "lvm.c", cflags.items);
    exe.addCSourceFile(src ++ "lzio.c", cflags.items);
}
