const std = @import("std");
const vkgen = @import("modules/graphics/lib/vulkan-zig/generator/index.zig");
const vma_build = @import("modules/graphics/lib/zig-vma/vma_build.zig");
const Step = std.build.Step;
const Builder = std.build.Builder;

const shaders_folder = "modules/graphics/shaders/";

pub const ResourceGenStep = struct {
    step: Step,
    shader_step: *vkgen.ShaderCompileStep,
    builder: *Builder,
    package: std.build.Pkg,
    output_file: std.build.GeneratedFile,
    resources: std.ArrayList(u8),

    pub fn init(builder: *Builder, out: []const u8) *ResourceGenStep {
        const self = builder.allocator.create(ResourceGenStep) catch unreachable;
        const full_out_path = std.fs.path.join(builder.allocator, &[_][]const u8{
            builder.build_root,
            builder.cache_root,
            out,
        }) catch unreachable;

        self.* = .{
            .step = Step.init(.custom, "resources", builder.allocator, make),
            .shader_step = vkgen.ShaderCompileStep.init(builder, &[_][]const u8{ "glslc", "--target-env=vulkan1.2" }, "shaders"),
            .builder = builder,
            .package = .{
                .name = "resources",
                .source = .{ .generated = &self.output_file },
                .dependencies = null,
            },
            .output_file = .{
                .step = &self.step,
                .path = full_out_path,
            },
            .resources = std.ArrayList(u8).init(builder.allocator),
        };

        self.step.dependOn(&self.shader_step.step);
        return self;
    }

    fn renderPath(path: []const u8, writer: anytype) void {
        const separators = &[_]u8{ std.fs.path.sep_windows, std.fs.path.sep_posix };
        var i: usize = 0;
        while (std.mem.indexOfAnyPos(u8, path, i, separators)) |j| {
            writer.writeAll(path[i..j]) catch unreachable;
            switch (std.fs.path.sep) {
                std.fs.path.sep_windows => writer.writeAll("\\\\") catch unreachable,
                std.fs.path.sep_posix => writer.writeByte(std.fs.path.sep_posix) catch unreachable,
                else => unreachable,
            }

            i = j + 1;
        }
        writer.writeAll(path[i..]) catch unreachable;
    }

    pub fn addShader(self: *ResourceGenStep, name: []const u8, source: []const u8) void {
        const shader_out_path = self.shader_step.add(source);
        var writer = self.resources.writer();

        writer.print("pub const {s} = @embedFile(\"", .{name}) catch unreachable;
        renderPath(shader_out_path, writer);
        writer.writeAll("\");\n") catch unreachable;
    }

    fn make(step: *Step) !void {
        const self = @fieldParentPtr(ResourceGenStep, "step", step);
        const cwd = std.fs.cwd();

        const dir = std.fs.path.dirname(self.output_file.path.?).?;
        try cwd.makePath(dir);
        try cwd.writeFile(self.output_file.path.?, self.resources.items);
    }
};

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const cflags: []const []const u8 = &.{"-Imodules/core/lib/stb/"};

    const exe = b.addExecutable("NeonWood", "modules/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    exe.linkLibC();
    exe.addCSourceFile("modules/core/lib/stb/stb_impl.cpp", cflags);
    exe.addCSourceFile("modules/graphics/lib/tinyobjloader/tinyobjloader.c", cflags);
    exe.addIncludeDir("modules/core/lib");
    exe.addIncludeDir("modules/graphics/lib");
    exe.addLibPath("modules/graphics/lib");
    exe.linkSystemLibrary("glfw3dll");

    if (target.getOs().tag == .windows) {
        exe.addObjectFile("modules/graphics/lib/zig-vma/test/vulkan-1.lib");
    } else {
        exe.linkSystemLibrary("vulkan");
    }

    const gen = vkgen.VkGenerateStep.init(b, "modules/graphics/lib/vk.xml", "vk.zig");
    //const vma = vma_build.link(exe.builder, "zig-cache/vk.zig");

    vma_build.link(exe, "zig-cache/vk.zig", mode, target);

    exe.addPackage(gen.package);
    //exe.addPackage(vma);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const res = ResourceGenStep.init(b, "resources.zig");
    res.addShader("triangle_vert", shaders_folder ++ "triangle.vert");
    res.addShader("triangle_frag", shaders_folder ++ "triangle.frag");
    res.addShader("triangle_mesh_vert", shaders_folder ++ "triangle_mesh.vert");
    res.addShader("triangle_mesh_frag", shaders_folder ++ "triangle_mesh.frag");
    res.addShader("triangle_vert_static", shaders_folder ++ "triangle_static.vert");
    res.addShader("triangle_frag_static", shaders_folder ++ "triangle_static.frag");
    res.addShader("triangle_vert_colored", shaders_folder ++ "triangle_colored.vert");
    res.addShader("triangle_frag_colored", shaders_folder ++ "triangle_colored.frag");
    exe.addPackage(res.package);

    const exe_tests = b.addTest("modules/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
    std.debug.print("|---------------------|\n", .{});
    std.debug.print("|Build complete       |\n", .{});
    std.debug.print("|---------------------|\n", .{});
}
