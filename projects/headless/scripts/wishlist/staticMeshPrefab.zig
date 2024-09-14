const core = @import("core");
const std = @import("std");

// Overall, we allow for one level of nesting within static meshes.

const MeshActor = struct {
    name: core.Name(),
    static: bool = true, // if true, collision is automatically generated
    mesh: core.Name(),
    texture: core.Name(),
};
const SkeletalMeshActor = struct {};

const MeshesSystem = struct {
    // list of meshes, both static and non-static
    // Not all of them are entities.
    // By default, they are NOT entities.

    staticActors: std.ArrayListUnmanaged(MeshActor),
    skeletalActors: std.ArrayListUnmanaged(SkeletalMeshActor),
};
