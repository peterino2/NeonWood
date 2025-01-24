// ok thinking about ozz animations
//
// runtime libraries -- convert to zig, write a c header runtime interface
//  ozz_base
//  ozz_animation
//  ozz_geometry
//
//  all libraries are under src/
//      src/
//          animation/
//          base/
//          geometry/
//          options/?
//
//          1. CAL all under ozz/src to ozz_cpp as static library
//          2. add ozz.zig and ozz_zig.cpp,
//
// offline libraries -- hmm i dont think i will try to convert these to zig
//  ozz_animation_offline
//  ozz_animation_offline_tools --
//  ozz_animation_offline_fbx -- fbx importing, requires linking wiht fbx sdk... maybe i dont want this... fuck adobe

const std = @import("std");

const Build = std.Build;
const LazyPath = LazyPath;

pub const GltfToOzz = struct {
    b: *Build,
    ozz_build: *Build,
    exe: *Build.Step.Compile,

    const BuildOptions = struct {
        importName: []const u8 = "ozz",
        optimize: std.builtin.OptimizeMode = .Debug,
    };

    fn initFromBuilder(b: *Build, ozz_build: *Build, opts: BuildOptions) GltfToOzz {
        const exe = ozz_build.addExecutable(.{
            .name = "gltf2ozz",
            .target = ozz_build.host,
            .optimize = .ReleaseSafe,
        });

        exe.linkLibCpp();
        exe.linkLibC();

        b.installArtifact(exe);
        const src_dir = "ozz-animation/src/";

        exe.addIncludePath(ozz_build.path("ozz-animation/include/ozz/animation/offline/tools"));
        exe.addIncludePath(ozz_build.path("ozz-animation/include/ozz/animation/offline"));
        exe.addIncludePath(ozz_build.path(src_dir ++ "animation/offline/tools"));
        exe.addIncludePath(ozz_build.path(src_dir ++ "animation/offline"));
        exe.addIncludePath(ozz_build.path("ozz-animation/include/"));
        exe.addIncludePath(ozz_build.path("ozz-animation/src"));
        exe.addIncludePath(ozz_build.path("ozz-animation/include/ozz/options"));
        exe.addIncludePath(ozz_build.path("ozz-animation/extern/jsoncpp/dist"));
        exe.addIncludePath(ozz_build.path("ozz-animation/extern/jsoncpp/dist/json"));

        exe.addCSourceFiles(.{
            .files = &.{
                src_dir ++ "animation/offline/gltf/gltf2ozz.cc",
                src_dir ++ "animation/offline/tools/import2ozz.cc",
                src_dir ++ "animation/offline/tools/import2ozz_anim.cc",
                src_dir ++ "animation/offline/tools/import2ozz_config.cc",
                src_dir ++ "animation/offline/tools/import2ozz_skel.cc",
                src_dir ++ "animation/offline/tools/import2ozz_track.cc",
                src_dir ++ "animation/offline/raw_animation.cc",
                src_dir ++ "animation/offline/raw_animation_utils.cc",
                src_dir ++ "animation/offline/animation_builder.cc",
                src_dir ++ "animation/offline/animation_optimizer.cc",
                src_dir ++ "animation/offline/raw_skeleton.cc",
                src_dir ++ "animation/offline/raw_skeleton_archive.cc",
                src_dir ++ "animation/offline/skeleton_builder.cc",
                src_dir ++ "animation/offline/raw_track.cc",
                src_dir ++ "animation/offline/track_builder.cc",
                src_dir ++ "animation/offline/additive_animation_builder.cc",
                src_dir ++ "animation/offline/raw_animation_archive.cc",
                src_dir ++ "animation/offline/track_optimizer.cc",
                "ozz-animation/extern/jsoncpp/dist/jsoncpp.cpp",
            },
        });

        const dep = b.dependency(opts.importName, .{});
        const ozz_mod = dep.artifact("ozz_cpp");
        exe.root_module.linkLibrary(ozz_mod);

        return .{
            .b = b,
            .ozz_build = ozz_build,
            .exe = exe,
        };
    }

    pub fn init(b: *Build, opts: BuildOptions) GltfToOzz {
        const dep = b.dependency(opts.importName, .{});
        return initFromBuilder(b, dep.builder, opts);
    }
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const ozz_cpp = b.addStaticLibrary(.{
        .name = "ozz_cpp",
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(ozz_cpp);

    ozz_cpp.addIncludePath(b.path("ozz-animation/include"));
    ozz_cpp.addIncludePath(b.path("ozz-animation/src"));
    ozz_cpp.linkLibC();

    if (target.result.abi != .msvc)
        ozz_cpp.linkLibCpp();

    const src_dir = "ozz-animation/src/";
    ozz_cpp.addCSourceFiles(.{
        .files = &.{
            src_dir ++ "options/options.cc",
            src_dir ++ "geometry/runtime/skinning_job.cc",
            src_dir ++ "base/containers/string_archive.cc",
            src_dir ++ "base/io/archive.cc",
            src_dir ++ "base/io/stream.cc",
            src_dir ++ "base/log.cc",
            src_dir ++ "base/platform.cc",
            src_dir ++ "base/maths/box.cc",
            src_dir ++ "base/maths/math_archive.cc",
            src_dir ++ "base/maths/simd_math.cc",
            src_dir ++ "base/maths/simd_math_archive.cc",
            src_dir ++ "base/maths/soa_math_archive.cc",
            src_dir ++ "base/memory/allocator.cc",
            src_dir ++ "animation/runtime/animation.cc",
            src_dir ++ "animation/runtime/animation_utils.cc",
            src_dir ++ "animation/runtime/blending_job.cc",
            src_dir ++ "animation/runtime/ik_aim_job.cc",
            src_dir ++ "animation/runtime/ik_two_bone_job.cc",
            src_dir ++ "animation/runtime/local_to_model_job.cc",
            src_dir ++ "animation/runtime/sampling_job.cc",
            src_dir ++ "animation/runtime/skeleton.cc",
            src_dir ++ "animation/runtime/skeleton_utils.cc",
            src_dir ++ "animation/runtime/track.cc",
            src_dir ++ "animation/runtime/track_sampling_job.cc",
            src_dir ++ "animation/runtime/track_triggering_job.cc",
        },
    });

    const ozz = b.addModule("ozz", .{
        .root_source_file = b.path("src/ozz.zig"),
    });

    ozz.addIncludePath(b.path("ozz-animation/include"));

    ozz.addCSourceFiles(.{
        .files = &.{
            "src/ozz_zig.cpp",
        },
    });

    const tests = b.addTest(.{
        .name = "ozz-tests",
        .root_source_file = b.path("tests/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(tests);

    const test_step = b.step("test", "run some ozz-runtime tests");
    tests.root_module.addImport("ozz", ozz);
    tests.linkLibrary(ozz_cpp);

    test_step.dependOn(&b.addRunArtifact(tests).step);
}
