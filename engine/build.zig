const std = @import("std");
const vkgen = @import("modules/graphics/lib/vulkan-zig/generator/index.zig");
const vma_build = @import("modules/graphics/lib/zig-vma/vma_build.zig");
const Step = std.build.Step;
const Builder = std.build.Builder;
const zigTracy = @import("modules/core/lib/Zig-Tracy/build_tracy.zig");

const shaders_folder = "modules/graphics/shaders/";

pub fn loadFileAlloc(filename: []const u8, comptime alignment: usize, allocator: std.mem.Allocator) ![]const u8 {
    var file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    const filesize = (try file.stat()).size;
    var buffer: []u8 = try allocator.allocAdvanced(u8, @intCast(u29, alignment), filesize, .exact);
    try file.reader().readNoEof(buffer);
    return buffer;
}

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
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();

        const allocator = gpa.allocator();

        var writer = self.resources.writer();
        var should_generate: bool = false;
        var should_free_file: bool = false;
        var should_free_file1: bool = false;
        const shader_out_path = self.shader_step.add(source);

        const dir = std.fs.path.dirname(shader_out_path).?;
        const ofile = std.fmt.allocPrint(allocator, "{s}/{s}.spv.cache", .{ dir, name }) catch unreachable;
        defer allocator.free(ofile);
        const F = struct {
            pub fn f(b0: *bool, b1: *bool) []const u8 {
                b0.* = true;
                b1.* = true;
                return "";
            }
        };

        const fileContents = loadFileAlloc(shader_out_path, 1, allocator) catch F.f(&should_generate, &should_free_file);

        defer if (!should_free_file) allocator.free(fileContents);

        var hash: u32 = 0;

        if (!should_generate) {
            hash = std.hash.CityHash32.hash(fileContents);
        }

        if (!should_generate) {
            const hashContents = loadFileAlloc(ofile, 1, allocator) catch F.f(&should_free_file1, &should_generate);
            defer if (!should_free_file1) allocator.free(hashContents);

            const F2 = struct {
                pub fn f(b0: *bool) u32 {
                    b0.* = true;
                    return 0xAAAAAAAA;
                }
            };

            const readHash = std.fmt.parseInt(u32, hashContents, 0) catch F2.f(&should_generate);

            if (!should_generate) {
                if (readHash != hash) {
                    should_generate = true;
                }
            }
        }

        writer.print("pub const {s} = @embedFile(\"", .{name}) catch unreachable;
        renderPath(shader_out_path, writer);
        writer.writeAll("\");\n") catch unreachable;

        if (!should_generate) {
            return;
        }

        const cwd = std.fs.cwd();
        _ = cwd.makePath(dir) catch unreachable;
        const hashAsString = std.fmt.allocPrint(allocator, "{d}", .{hash}) catch unreachable;
        defer allocator.free(hashAsString);

        cwd.writeFile(ofile, hashAsString) catch unreachable;
    }

    fn make(step: *Step) !void {
        const self = @fieldParentPtr(ResourceGenStep, "step", step);
        const cwd = std.fs.cwd();

        const dir = std.fs.path.dirname(self.output_file.path.?).?;
        try cwd.makePath(dir);
        try cwd.writeFile(self.output_file.path.?, self.resources.items);
    }
};

pub fn createEnginePackage() void {}

pub fn createGameExecutable(
    target: std.zig.CrossTarget,
    b: *std.build.Builder,
    name: []const u8,
    mainFile: []const u8,
    enable_tracy: bool,
    options: *std.build.OptionsStep,
) !*std.build.LibExeObjStep {
    var allocator = b.allocator;

    const mode = b.standardReleaseOptions();

    var maxPathBuffer = std.mem.zeroes([std.fs.MAX_PATH_BYTES]u8);
    var basePath = try std.fs.realpath(b.build_root, &maxPathBuffer);
    _ = basePath;

    var enginePathBuffer = std.mem.zeroes([std.fs.MAX_PATH_BYTES]u8);
    var enginePath = try std.fs.realpath(b.build_root, &enginePathBuffer);

    // std.debug.print("build_root: {s} \n", .{basePath});
    var cflags = std.ArrayList([]const u8).init(allocator);
    defer cflags.deinit();

    try cflags.append(try std.fmt.allocPrint(allocator, "-I{s}/modules/core/lib/stb/", .{enginePath}));
    if(enable_tracy)
    {
        try cflags.append(try std.fmt.allocPrint(allocator, "-DTRACY_ENABLE=1", .{}));
        try cflags.append(try std.fmt.allocPrint(allocator, "-DTRACY_HAS_CALLSTACK=0", .{}));
        try cflags.append(try std.fmt.allocPrint(allocator, "-D_Win32_WINNT=0x601", .{}));
    }
    try cflags.append(try std.fmt.allocPrint(allocator, "-fno-sanitize=all", .{}));


    for (cflags.items) |s| {
        _ = s;
        //std.debug.print("cflag: {s}\n", .{s});
    }

    var thisBuildFile = @src().file;
    var engineRoot = std.fs.path.dirname(thisBuildFile).?;

    // std.debug.print("root = `{s}`\n", .{engineRoot});

    var mainFilePath = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ engineRoot, mainFile });
    defer allocator.free(mainFilePath);

    const exe = b.addExecutable(name, mainFilePath);

    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    exe.linkLibC();
    exe.addCSourceFile("modules/core/lib/stb/stb_impl.cpp", cflags.items);
    exe.addCSourceFile("modules/graphics/lib/imgui/imgui.cpp", cflags.items);
    exe.addCSourceFile("modules/graphics/lib/imgui/imgui_demo.cpp", cflags.items);
    exe.addCSourceFile("modules/graphics/lib/imgui/imgui_draw.cpp", cflags.items);
    exe.addCSourceFile("modules/graphics/lib/imgui/imgui_tables.cpp", cflags.items);
    exe.addCSourceFile("modules/graphics/lib/imgui/backends/imgui_impl_vulkan.cpp", cflags.items);
    exe.addCSourceFile("modules/graphics/lib/imgui/backends/imgui_impl_glfw.cpp", cflags.items);
    exe.addCSourceFile("modules/graphics/lib/imgui/imgui_widgets.cpp", cflags.items);
    exe.addCSourceFile("modules/graphics/lib/cimgui/cimgui.cpp", cflags.items);
    exe.addCSourceFile("modules/graphics/cimgui_compat.cpp", cflags.items);
    exe.addCSourceFile("modules/audio/miniaudio.c", cflags.items);
    exe.addIncludePath("modules/core/lib");
    exe.addIncludePath("modules/audio/lib");
    exe.addIncludePath("modules/graphics/lib/vulkan_inc");
    exe.addIncludePath("modules/graphics/lib/cimgui");
    exe.addIncludePath("modules/graphics/lib/imgui");
    exe.addIncludePath("modules/graphics/lib/imgui/backends");
    exe.addIncludePath("modules/graphics/lib");
    exe.addIncludePath("modules/graphics");
    exe.addLibraryPath("modules/graphics/lib");
    if(target.getOs().tag == .windows)
    {
        exe.linkSystemLibrary("glfw3dll");
    }
    else 
    {
        exe.linkSystemLibrary("glfw");
        exe.linkSystemLibrary("dl");
        exe.linkSystemLibrary("pthread");
    }
    exe.linkSystemLibrary("m");
    exe.addOptions("game_build_opts", options);

    if(mode == .ReleaseFast or mode == .ReleaseSmall or mode == .ReleaseSafe)
    {
        if(enable_tracy)
        {
            std.debug.print("\n\n !! enable_tracy will be ignored for release-* builds\n\n", .{});
        }
        zigTracy.link(b, exe, null);
    }
    else if(enable_tracy)
    {
        std.debug.print("\n\nenabling tracy\n\n", .{});
        zigTracy.link(b, exe, "modules/core/lib/Zig-Tracy/tracy-0.7.8/");
    }
    else {
        std.debug.print("\n\n no tracy\n\n", .{});
        zigTracy.link(b, exe, null);
    }

    const gen = vkgen.VkGenerateStep.init(b, "modules/graphics/lib/vk.xml", "vk.zig");

    if (target.getOs().tag == .windows) {
        exe.addObjectFile("modules/graphics/lib/zig-vma/test/vulkan-1.lib");
    } else {
        exe.linkSystemLibrary("vulkan");
    }

    const res = ResourceGenStep.init(b, "resources.zig");
    res.addShader("triangle_vert", shaders_folder ++ "triangle.vert");
    res.addShader("triangle_frag", shaders_folder ++ "triangle.frag");
    res.addShader("triangle_mesh_vert", shaders_folder ++ "triangle_mesh.vert");
    res.addShader("triangle_mesh_frag", shaders_folder ++ "triangle_mesh.frag");
    res.addShader("triangle_vert_static", shaders_folder ++ "triangle_static.vert");
    res.addShader("triangle_frag_static", shaders_folder ++ "triangle_static.frag");
    res.addShader("triangle_vert_colored", shaders_folder ++ "triangle_colored.vert");
    res.addShader("triangle_frag_colored", shaders_folder ++ "triangle_colored.frag");
    res.addShader("sprite_mesh_vert", shaders_folder ++ "sprite_mesh.vert");
    res.addShader("sprite_mesh_frag", shaders_folder ++ "sprite_mesh.frag");
    res.addShader("default_lit_frag", shaders_folder ++ "default_lit.frag");
    res.addShader("image_vert", shaders_folder ++ "image_vert.vert");
    res.addShader("image_frag", shaders_folder ++ "image_frag.frag");
    res.addShader("debug_vert", shaders_folder ++ "debug.vert");
    res.addShader("debug_frag", shaders_folder ++ "debug.frag");
    exe.addPackage(res.package);

    var runName = try std.fmt.allocPrint(allocator, "run-{s}", .{name});
    defer allocator.free(mainFilePath);

    vma_build.link(exe, "zig-cache/vk.zig", mode, target);
    exe.addPackage(gen.package);

    const objViewer_run_cmd = exe.run();
    objViewer_run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        objViewer_run_cmd.addArgs(args);
    }

    const run_objViewer = b.step(runName, "Run the app");
    run_objViewer.dependOn(&objViewer_run_cmd.step);

    // clean up
    {
        var i: usize = 0;
        while (i < cflags.items.len) : (i += 1) {
            allocator.free(cflags.items[i]);
        }
    }

    return exe;
}

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    const options = b.addOptions();
    options.addOption(bool, "validation_layers", 
        b.option(bool, "vulkan_validation", "Enables vulkan validation layers") orelse false);

    options.addOption(bool, "release_build", false); // set to true to override all other debug flags.
    const enable_tracy = b.option(bool, "tracy", "Enables integration with tracy profiler") orelse false;

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.

    // const gen = vkgen.VkGenerateStep.init(b, "modules/graphics/lib/vk.xml", "vk.zig");
    //_ = createGameExecutable(target, b, "objViewer", "objViewer.zig") catch |e| {
    //    std.debug.print("error: {any}", .{e});
    //    unreachable;
    //};

    _ = createGameExecutable(target, b, "neurophobia", "neurophobia.zig", enable_tracy, options) catch |e| {
        std.debug.print("error: {any}", .{e});
        unreachable;
    };

    _ = createGameExecutable(target, b, "demo", "demo.zig", enable_tracy, options) catch |e| {
        std.debug.print("error: {any}", .{e});
        unreachable;
    };

    _ = createGameExecutable(target, b, "jobTest", "jobTest.zig", enable_tracy, options) catch |e| {
        std.debug.print("error: {any}", .{e});
        unreachable;
    };
}
