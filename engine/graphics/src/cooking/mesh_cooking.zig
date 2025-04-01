const MeshConfig = struct {
    info: CookInfo = .{ .assetType = "Mesh" }, // there must always be a CookInfo field
    sourceType: []const u8 = "obj",
    animated: bool = false,
};

const extList = [_][]const u8{ "gltf", "obj", "glb" };
pub fn generateFunction(allocator: std.mem.Allocator, path: []const u8, out: *std.ArrayList(u8)) GenerateError!void {
    _ = allocator;
    out.clearRetainingCapacity();
    const ext = core.getFileExtension(path)[1..];

    var config: MeshConfig = .{};

    for (extList) |e| {
        if (std.mem.eql(u8, e, ext)) {
            config.sourceType = e;

            if (std.mem.eql(u8, e, "glb")) {
                config.sourceType = "gltf";
            }
        }
    }

    std.json.stringify(
        config,
        .{ .whitespace = .indent_4 },
        out.writer(),
    ) catch return GenerateError.UnableToGenerate;
}

fn cookObj(allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8) cook.CookResult {
    const rawFileBytes = cook.loadFileAlloc(allocator, dir, path) catch unreachable;
    defer allocator.free(rawFileBytes);

    var out = std.ArrayList(u8).init(allocator);

    var vertices = std.ArrayList(Vertex).init(allocator);
    defer vertices.deinit();

    var objs = obj.loadObjBytes(rawFileBytes, allocator) catch unreachable;
    defer objs.deinit();

    if (objs.meshes.items.len > 0) {
        mesh.loadObjMeshVertices(&vertices, objs.meshes.items[0]) catch unreachable;
        for (vertices.items) |vert| {
            out.appendSlice(&@as([@sizeOf(Vertex)]u8, @bitCast(vert))) catch unreachable;
        }

        return .{
            .bytes = out,
            .result = .Success,
        };
    } else {
        return .{
            .bytes = out,
            .result = .Failure,
        };
    }
}

fn ensureGltf2ozz(allocator: std.mem.Allocator) !void {
    const suffix = if (builtin.os.tag == .windows) ".exe" else "";
    std.fs.cwd().access("zig-out/tools/gltf2ozz" ++ suffix, .{}) catch {
        const argv: []const []const u8 = &.{ "zig", "build", "tools" };

        core.engine_log("gltf2ozz missing, building it...", .{});

        var child = std.process.Child.init(argv, allocator);
        child.stdin_behavior = .Ignore;
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;
        child.cwd = ".";

        switch (try child.spawnAndWait()) {
            .Exited => |value| {
                if (value == 0) {
                    core.engine_log("gltf2ozz built", .{});
                } else {
                    core.engine_logs("unable to build gltf2ozz");
                }
            },
            .Signal => {
                core.engine_logs("unable to build gltf2ozz");
            },
            .Stopped => {},
            .Unknown => {
                unreachable;
            },
        }

        return;
    };

    core.engine_log("gltf2ozz found", .{});
}

fn cookAnimations(allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8, config: MeshConfig) !void {
    _ = config;

    // 1. check if it has an associated .ozzconfig file.

    const gltf2OzzAbs = try std.fs.cwd().realpathAlloc(allocator, "zig-out/tools/gltf2ozz.exe");
    defer allocator.free(gltf2OzzAbs);

    const ozzconfig = try std.fmt.allocPrint(allocator, "{s}.ozzconfig", .{path});
    defer allocator.free(ozzconfig);

    const fileArg = try std.fmt.allocPrint(allocator, "--file={s}", .{core.getBasePath(path)});
    defer allocator.free(fileArg);

    const configArg = try std.fmt.allocPrint(allocator, "--config_file={s}", .{core.getBasePath(ozzconfig)});
    defer allocator.free(configArg);

    // todo, fix this later, idrc right now.
    const newConfigArg = try std.fmt.allocPrint(allocator, "--config_dump_reference={s}", .{core.getBasePath(ozzconfig)});
    defer allocator.free(newConfigArg);

    const absFile = try dir.realpathAlloc(allocator, path);
    defer allocator.free(absFile);

    var argv: []const []const u8 = &.{
        gltf2OzzAbs,
        fileArg,
        configArg,
    };

    dir.access(ozzconfig, .{}) catch {
        argv = &.{
            gltf2OzzAbs,
            fileArg,
            newConfigArg,
        };

        core.engine_log("creating ozz config for file, marked as animated but no animation data", .{});
    };

    // std.debug.print("{s} {s} {s} cwd = {s}\n", .{ argv[0], argv[1], argv[2], core.getFolder(absFile) });

    const result = try std.process.Child.run(.{
        .argv = argv,
        .allocator = allocator,
        .cwd = core.getFolder(absFile),
        .max_output_bytes = 150 * 1024 * 1024,
    });

    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    var success: bool = true;
    switch (result.term) {
        .Exited => |value| {
            if (value != 0) {
                success = false;
            }
        },
        .Signal => {
            success = false;
        },
        .Stopped => {
            success = false;
            // no-op should be ok?
        },
        .Unknown => {
            unreachable;
        },
    }

    if (success) {
        core.engine_log("generated animations for {s}", .{path});
    } else {
        core.engine_log("error generating animations {s} stdout:\n{s}\n stderr:{s}\n", .{ path, result.stdout, result.stderr });
    }
    // 2. if so, run it through gltf2ozz with that file.
}

fn cookGltf(allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8, config: MeshConfig) cook.CookResult {
    core.engine_logs("gltf cooking not implemeted");
    const out = std.ArrayList(u8).init(allocator);

    // check if it's animated. if it's animated, then invoke gltf2ozz and create a .ozzconfig file and
    // make a subfolder called

    if (config.animated) {
        // if gltf2ozz isn't there then we have to call zig build tools
        ensureGltf2ozz(allocator) catch unreachable;

        cookAnimations(allocator, dir, path, config) catch unreachable;
    }

    return .{ .bytes = out, .result = .Failure };
}

pub fn cookFunction(
    allocator: std.mem.Allocator,
    dir: std.fs.Dir,
    path: []const u8,
    params: cook.CookParams,
) cook.CookResult {
    core.engine_log("{s}", .{params.cookFileName});
    const fc = cook.loadFileAlloc(allocator, dir, params.cookFileName) catch unreachable;
    defer allocator.free(fc);

    const config = std.json.parseFromSlice(MeshConfig, allocator, fc[0 .. fc.len - 1], .{}) catch unreachable;
    defer config.deinit();

    if (std.mem.eql(u8, config.value.sourceType, "obj")) {
        return cookObj(allocator, dir, path);
    } else {
        return cookGltf(allocator, dir, path, config.value);
    }
}

pub fn initCooker(allocator: std.mem.Allocator) !void {
    _ = allocator;
    const registry = assets.cook.getRegistry();

    try registry.install("Mesh", generateFunction, cookFunction, &.{
        ".obj",
        ".gltf",
        ".glb",
    });
}

pub fn deinitCooker() void {
    //
}

const std = @import("std");
const assets = @import("assets");
const cook = assets.cook;
const CookInfo = assets.cook.CookInfo;
const GenerateError = assets.cook.GenerateError;
const core = @import("core");
const obj = @import("objLoader");
const builtin = @import("builtin");
const mesh = @import("../mesh.zig");
const Mesh = mesh.Mesh;
const Vertex = mesh.MeshVertex;
