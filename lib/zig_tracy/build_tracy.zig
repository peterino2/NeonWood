const std = @import("std");
const Builder = std.Build;

/// Build required sources, use tracy by importing "tracy.zig"
pub fn link(b: *Builder, step: *std.Build.Step.Compile, opt_path: ?[]const u8) void {
    const step_options = b.addOptions();
    step.root_module.addOptions("build_options", step_options);
    step_options.addOption(bool, "tracy_enabled", opt_path != null);

    if (opt_path) |path| {
        step.addIncludePath(.{ .path = path });
        const tracy_client_source_path = std.fs.path.join(b.allocator, &.{ path, "TracyClient.cpp" }) catch unreachable;
        step.addCSourceFile(.{
            .file = .{ .path = tracy_client_source_path },
            .flags = &[_][]const u8{
                "-DTRACY_ENABLE",
                // MinGW doesn't have all the newfangled windows features,
                // so we need to pretend to have an older windows version.
                "-D_WIN32_WINNT=0x601",
                "-fno-sanitize=undefined",
            },
        });

        step.linkLibC();
        step.linkSystemLibrary("c++");

        if (step.root_module.resolved_target.?.result.os.tag == .windows) {
            step.linkSystemLibrary("Advapi32");
            step.linkSystemLibrary("User32");
            step.linkSystemLibrary("Ws2_32");
            step.linkSystemLibrary("DbgHelp");
        }
    }
}
