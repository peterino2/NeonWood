const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("lua", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/lua.zig"),
        .link_libc = true,
    });

    mod.addCSourceFiles(.{
        .root = b.path("lua/src/"),
        .files = &.{
            "lapi.c",
            "lmathlib.c",
            "lauxlib.c",
            "lbaselib.c",
            "lcode.c",
            "lcorolib.c",
            "lctype.c",
            "ldblib.c",
            "ldebug.c",
            "ldo.c",
            "ldump.c",
            "lfunc.c",
            "lgc.c",
            "linit.c",
            "liolib.c",
            "llex.c",
            "lmem.c",
            "loadlib.c",
            "lobject.c",
            "lopcodes.c",
            "loslib.c",
            "lparser.c",
            "lstate.c",
            "lstring.c",
            "lstrlib.c",
            "ltable.c",
            "ltablib.c",
            "ltm.c",
            "lundump.c",
            "lutf8lib.c",
            "lvm.c",
            "lzio.c",
        },
    });

    mod.addCSourceFile(.{ .file = b.path("src/limited_io.c") });

    mod.addIncludePath(b.path("lua/src/"));
    mod.addIncludePath(b.path("src/"));

    const run_step = b.step("run-lua", "");
    const tests = b.addExecutable(.{
        .name = "run-lua",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("test/test-lua.zig"),
        .link_libc = true,
    });

    tests.root_module.addImport("lua", mod);
    const runArtifact = b.addRunArtifact(tests);
    run_step.dependOn(&runArtifact.step);
}
