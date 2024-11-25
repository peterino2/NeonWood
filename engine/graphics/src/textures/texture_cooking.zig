const TextureConfig = struct {
    info: CookInfo = .{ .assetType = "Texture" }, // there must always be a CookInfo field
    sourceType: []const u8 = "png",
};

pub fn generateFunction(allocator: std.mem.Allocator, out: *std.ArrayList(u8)) GenerateError!void {
    _ = allocator;

    out.clearRetainingCapacity();
    std.json.stringify(
        TextureConfig{},
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

    return .{
        .bytes = allocator.dupe(u8, "placeholder") catch null,
        .result = .Success,
    };
}

pub fn initCooker(allocator: std.mem.Allocator) !void {
    _ = allocator;
    const registry = assets.cook.getRegistry();

    try registry.install("Texture", generateFunction, cookFunction, &.{
        ".png",
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
