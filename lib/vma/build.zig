const std = @import("std");
const vma_build = @import("vma_build.zig");
const vma_config = @import("vma_config.zig");

fn getConfigArgs(comptime config: vma_config.Config) []const []const u8 {
    comptime {
        @setEvalBranchQuota(100000);
        var args: []const []const u8 = &[_][]const u8{
            std.fmt.comptimePrint("-DVMA_VULKAN_VERSION={}", .{config.vulkanVersion}),
            std.fmt.comptimePrint("-DVMA_DEDICATED_ALLOCATION={}", .{@intFromBool(config.dedicatedAllocation)}),
            std.fmt.comptimePrint("-DVMA_BIND_MEMORY2={}", .{@intFromBool(config.bindMemory2)}),
            std.fmt.comptimePrint("-DVMA_MEMORY_BUDGET={}", .{@intFromBool(config.memoryBudget)}),
            std.fmt.comptimePrint("-DVMA_STATIC_VULKAN_FUNCTIONS={}", .{@intFromBool(config.staticVulkanFunctions)}),
            std.fmt.comptimePrint("-DVMA_STATS_STRING_ENABLED={}", .{@intFromBool(config.statsStringEnabled)}),
        };
        if (config.debugInitializeAllocations) |value| {
            args = args ++ &[_][]const u8{std.fmt.comptimePrint(
                "-DVMA_DEBUG_INITIALIZE_ALLOCATIONS={}",
                .{@intFromBool(value)},
            )};
        }
        if (config.debugMargin) |value| {
            args = args ++ &[_][]const u8{std.fmt.comptimePrint(
                "-DVMA_DEBUG_MARGIN={}",
                .{value},
            )};
        }
        if (config.debugDetectCorruption) |value| {
            args = args ++ &[_][]const u8{std.fmt.comptimePrint(
                "-DVMA_DEBUG_DETECT_CORRUPTION={}",
                .{@intFromBool(value)},
            )};
        }
        if (config.recordingEnabled) |value| {
            args = args ++ &[_][]const u8{std.fmt.comptimePrint(
                "-DVMA_RECORDING_ENABLED={}",
                .{@intFromBool(value)},
            )};
        }
        if (config.debugMinBufferImageGranularity) |value| {
            args = args ++ &[_][]const u8{std.fmt.comptimePrint(
                "-DVMA_DEBUG_MIN_BUFFER_IMAGE_GRANULARITY={}",
                .{value},
            )};
        }
        if (config.debugGlobalMutex) |value| {
            args = args ++ &[_][]const u8{std.fmt.comptimePrint(
                "-DVMA_DEBUG_GLOBAL_MUTEX={}",
                .{@intFromBool(value)},
            )};
        }
        if (config.useStlContainers) |value| {
            args = args ++ &[_][]const u8{std.fmt.comptimePrint(
                "-DVMA_USE_STL_CONTAINERS={}",
                .{@intFromBool(value)},
            )};
        }
        if (config.useStlSharedMutex) |value| {
            args = args ++ &[_][]const u8{std.fmt.comptimePrint(
                "-DVMA_USE_STL_SHARED_MUTEX={}",
                .{@intFromBool(value)},
            )};
        }

        return args;
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const commonArgs = &[_][]const u8{ "-std=c++14", "-DVMA_IMPLEMENTATION" };
    const releaseArgs = &[_][]const u8{} ++ commonArgs ++ comptime getConfigArgs(vma_config.releaseConfig);
    const debugArgs = &[_][]const u8{} ++ commonArgs ++ comptime getConfigArgs(vma_config.debugConfig);
    const args = if (optimize == .Debug) debugArgs else releaseArgs;

    const macos_vulkan_sdk = b.graph.env_map.hash_map.get("VULKAN_SDK");

    const vulkan_dep = b.dependency("vulkan", .{
        .target = target,
        .optimize = optimize,
    });

    const vulkan = vulkan_dep.module("vulkan");

    const mod = b.addModule("vma", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("vma.zig"),
        .link_libc = true,
        .link_libcpp = target.result.abi != .msvc,
    });

    if (target.result.os.tag == .macos) {
        mod.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib/" });
        mod.addLibraryPath(.{ .cwd_relative = b.fmt("{s}/1.3.250.1/macOS/lib/", .{macos_vulkan_sdk.?}) });
        mod.linkSystemLibrary("vulkan", .{});
    }

    mod.addIncludePath(b.path("vulkan"));
    mod.addCSourceFile(.{ .file = b.path("vk_mem_alloc.cpp"), .flags = args });

    mod.addImport("vulkan", vulkan);

    // ========== tests =============
    const test_step = b.step("test-vma", "run unit tests for vma");
    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("vma_test.zig"),
    });
    tests.root_module.addImport("vma", mod);
    const runArtifact = b.addRunArtifact(tests);
    test_step.dependOn(&runArtifact.step);
}
