# obj_loader - a zig obj file loader

This was very rapidly written to provide a simple interface for loading `.obj` files in zig.

At this time I make no garauntees on correctness or performance.

To load an obj, 

```zig
const obj_loader = @import("path/to/obj_loader.zig");

var contents: ObjContents = obj_loader.loadObj("suzanne.obj", your.favorite.allocator);
defer contents.deinit();
```

The ObjContents contains a list of ObjMesh objects.

```zig
std.debug.print("obj: {s}, Vertices count = {d} Normals count = {d}, faces = {d}\n", .{
    contents.meshes.items[0].object_name,
    contents.meshes.items[0].v_positions.items.len,
    contents.meshes.items[0].v_normals.items.len,
    contents.meshes.items[0].v_faces.items.len,
});
```

```zig
pub const ObjMesh = struct {
    object_name: []u8,
    v_positions: ArrayListUnmanaged(ObjVec) = .{},
    v_colors: ArrayListUnmanaged(ObjColor) = .{},
    v_normals: ArrayListUnmanaged(ObjVec) = .{},
    v_textures: ArrayListUnmanaged(ObjVec2) = .{},
    v_faces: ArrayListUnmanaged(ObjFace) = .{},

    ...
}
```

## Faces 

The faces produced by this library are currently coded to a maximum of 4. If you want more advanced 
n-gon triangulation, give [`zmesh`](https://github.com/michal-z/zig-gamedev/tree/main/libs/zmesh) a try.

```zig
pub const ObjFace = struct {
    vertex: [4]u32,
    texture: [4]u32,
    normal: [4]u32,
    count: u32,
};
```
