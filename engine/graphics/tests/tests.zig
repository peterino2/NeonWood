const std = @import("std");
const graphics = @import("graphics");
const core = @import("core");
const platform = @import("platform");
const QuakeMap = graphics.QuakeMap;

test "simple_integration" {
    // this doesn't really do anything other than just a simple compile check
    std.debug.print("sizeof NeonVkContext = {d}\n", .{@sizeOf(graphics.NeonVkContext)});
    std.debug.print("sizeof triangle_mesh_vert.ObjectData = {d}\n", .{@sizeOf(graphics.vk_renderer.triangle_mesh_vert.ObjectData)});
}

test "renderthread queue" {
    const allocator = std.testing.allocator;
    try core.start_module(.{}, .{}, allocator);
    defer core.shutdown_module(allocator);
}

test "quake map loading" {
    // const TestMap = @embedFile("testmap.map");

    const testmapFile =
        \\{
        \\"spawnflags" "0"
        \\"classname" "worldspawn"
        \\"wad" "E:\q1maps\Q.wad"
        \\{
        \\( 256 64 16 ) ( 256 64 0 ) ( 256 0 16 ) mmetal1_2 0 0 0 1 1
        \\( 0 0 0 ) ( 0 64 0 ) ( 0 0 16 ) mmetal1_2 0 0 0 1 1
        \\( 64 256 16 ) ( 0 256 16 ) ( 64 256 0 ) mmetal1_2 0 0 0 1 1
        \\( 0 0 0 ) ( 0 0 16 ) ( 64 0 0 ) mmetal1_2 0 0 0 1 1
        \\( 64 64 0 ) ( 64 0 0 ) ( 0 64 0 ) mmetal1_2 0 0 0 1 1
        \\( 0 0 -64 ) ( 64 0 -64 ) ( 0 64 -64 ) mmetal1_2 0 0 0 1 1
        \\}
        \\}
        \\{
        \\"spawnflags" "0"
        \\"classname" "info_player_start"
        \\"origin" "32 32 24"
        \\}
    ;

    var err: QuakeMap.ErrorInfo = undefined;
    var map = try QuakeMap.read(std.testing.allocator, testmapFile, &err);
    defer map.deinit();
}
