const MeshConfig = struct {
    info: CookInfo = .{ .assetType = "Mesh" }, // there must always be a CookInfo field
    sourceType: []const u8 = "obj",
};

pub fn generateFunction(allocator: std.mem.Allocator, out: *std.ArrayList(u8)) GenerateError!void {
    _ = allocator;
    out.clearRetainingCapacity();

    std.json.stringify(
        MeshConfig{},
        .{ .whitespace = .indent_4 },
        out.writer(),
    ) catch return GenerateError.UnableToGenerate;
}

pub fn cookFunction(
    allocator: std.mem.Allocator,
    dir: std.fs.Dir,
    path: []const u8,
    params: cook.CookParams,
) cook.CookResult {
    _ = params;

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

pub fn initCooker(allocator: std.mem.Allocator) !void {
    _ = allocator;
    const registry = assets.cook.getRegistry();

    try registry.install("Mesh", generateFunction, cookFunction, &.{
        ".obj",
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
