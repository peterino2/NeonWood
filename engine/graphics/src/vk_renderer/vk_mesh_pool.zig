const std = @import("std");

const core = @import("core");
const IndexPool = core.IndexPool;
const IndexPoolHandle = core.IndexPoolHandle;

const DynamicMesh = @import("../vk_dynamic_mesh.zig").DynamicMesh;

// should be owned by renderthread


pub const Reservation = struct {
    index: Span,
    vertex: Span,
};

pub const ReservationHandle = struct {
    vertexReservation: IndexPoolHandle,
};


pub const MeshPool = struct {
    mesh: *DynamicMesh,
    reservedIndex: IndexPool(Reservation),
    usedSpansIndex: std.ArrayListUnmanaged(Span),
    reservedVertex: IndexPool(Reservation),

    pub fn create() *@This() {}
};
