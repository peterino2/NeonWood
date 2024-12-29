const MeshConfig = struct {
    info: CookInfo = .{ .assetType = "Mesh" }, // there must always be a CookInfo field
    sourceType: []const u8 = "obj",
    animated: bool = false,
};

const extList = [_][]const u8{ "gltf", "obj" };
pub fn generateFunction(allocator: std.mem.Allocator, path: []const u8, out: *std.ArrayList(u8)) GenerateError!void {
    _ = allocator;
    out.clearRetainingCapacity();
    const ext = core.getFileExtension(path)[1..];

    var config: MeshConfig = .{};

    for (extList) |e| {
        if (std.mem.eql(u8, e, ext)) {
            config.sourceType = e;
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

fn cookGltf(allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8, config: MeshConfig) cook.CookResult {
    _ = dir;
    _ = path;
    core.engine_logs("gltf cooking not implemeted");
    const out = std.ArrayList(u8).init(allocator);

    // check if it's animated. if it's animated, then invoke gltf2ozz and create a .ozzconfig file

    if (config.animated) {}

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
        return cookGltf(allocator, dir, path, config);
    }
}

pub fn initCooker(allocator: std.mem.Allocator) !void {
    _ = allocator;
    const registry = assets.cook.getRegistry();

    try registry.install("Mesh", generateFunction, cookFunction, &.{
        ".obj",
        ".gltf",
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
const mesh = @import("../mesh.zig");
const Mesh = mesh.Mesh;
const Vertex = mesh.MeshVertex;
