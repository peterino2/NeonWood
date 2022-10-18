const std = @import("std");

const nw = @import("root").neonwood;
const graphics = nw.graphics;
const audio = nw.audio;
const core = nw.core;

pub const InteractableInterface = struct {
    typeName: Name,
    typeSize: usize,
    typeAlign: usize,

    onInteract: fn (*anyopaque) void,

    pub fn from(comptime TargetType: type)  @This() {
        const wrappedFuncs = struct {

            pub fn onInteract(pointer: *anyopaque) void {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                ptr.onInteract(cmd, frameIndex, deltaTime);
            }
        };

        var self = @This(){
            .typeName = MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .onInteract = wrappedFuncs.onInteract,
        };

        return self;
    }

};

pub const InteractableObject = struct {
    interface: InteractableInterfaceRef,
    position: core.Vectorf,
    radius: f32,
};

pub const InteractableInterfaceRef = core.InterfaceRef(InteractableInterface);

pub const InteractableObjectSet = core.SparseMultiSet(struct{ object: InteractableObject});

pub const InteractionSystem = struct {
    interactables: InteractableObjectSet,
    allocator: std.mem.Allocator,
    hightLightObject: core.ObjectHandle,

    pub fn init(allocator: std.mem.Allocator) @This()
    {
        return .{
            .allocator = allocator,
            .interactables = InteractableObjectSet.init(allocator),
        };
    }

    pub fn addInteractable(self: @This(), interactable: InteractableObject, interface: InteractableInterfaceRef) !core.ObjectHandle
    {
        try self.interactables.createObject();
    }

    pub fn getFirstObjectInRange(self: @This(), position: core.Vectorf, radius: f32) core.ObjectHandle
    {
        _ = self; 
        _ = position;
        _ = radius;

        return .{};
    }
};