const std = @import("std");

const nw = @import("root").neonwood;
const graphics = nw.graphics;
const audio = nw.audio;
const dialogue = @import("dialogue.zig");
const halcyon = @import("halcyon_sys.zig");
const core = nw.core;

const Name = core.Name;

pub const InteractableInterface = struct {
    typeName: Name,
    typeSize: usize,
    typeAlign: usize,

    onInteract: fn (*anyopaque) void,
    serialize: fn (*anyopaque, std.mem.Allocator) std.ArrayList(u8),

    pub fn from(comptime TargetType: type)  @This() {
        const wrappedFuncs = struct {

            pub fn onInteract(pointer: *anyopaque) void {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                ptr.onInteract();
            }

            pub fn serialize(pointer: *anyopaque, allocator: std.mem.Allocator) std.ArrayList(u8) {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                return ptr.serialize(allocator);
            }
        };

        var self = @This(){
            .typeName = core.MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .onInteract = wrappedFuncs.onInteract,
            .serialize = wrappedFuncs.serialize,
        };

        return self;
    }

};

pub const InteractableObject = struct {
    interface: InteractableRef,
    position: core.Vectorf,
    radius: f32,
    disabled: bool = false,

    pub fn interact(self: *@This()) void 
    {
        self.interface.onInteract();
    }

    pub fn serialize(self: *@This(), allocator: std.mem.Allocator) std.ArrayList(u8) 
    {
        return self.interface.vtable.serialize(self.interface.ptr, allocator);
    }
};

// oh god this is awful i need a subsystem registry in the engine in the future.
pub var dialogueSys: *dialogue.DialogueSystem = undefined;
pub var halcyonSys: *halcyon.HalcyonSys = undefined;

pub const HalcyonInteractable = struct {
    pub const InteractableVTable = InteractableInterface.from(@This());

    dialogueTag: []const u8,
    handle: core.ObjectHandle = undefined,

    pub fn onInteract(self: *@This()) void
    {
        halcyonSys.startDialogue(self.dialogueTag);
    }

    pub fn serialize(self: @This(), allocator: std.mem.Allocator) std.ArrayList(u8)
    {
        var ostr = std.ArrayList(u8).init(allocator);
        ostr.appendSlice(self.dialogueTag) catch unreachable;

        return ostr;
    }
};

pub const InteractableRef = struct {
    ptr: *anyopaque,
    vtable: *const InteractableInterface,

    pub fn makeRef(target: anytype) @This()
    {
        return .{
            .ptr = target,
            .vtable = &@TypeOf(target.*).InteractableVTable,
        };
    }

    pub fn onInteract(self: *@This()) void
    {
        self.vtable.onInteract(self.ptr);
    }
};

pub const InteractableObjectSet = core.SparseMultiSet(struct{ object: InteractableObject });

pub const InteractionSystem = struct {
    interactables: InteractableObjectSet,
    allocator: std.mem.Allocator,
    highLightObject: ?core.ObjectHandle,
    talkables: std.AutoHashMapUnmanaged(u32, *HalcyonInteractable),

    pub fn init(allocator: std.mem.Allocator) @This()
    {
        return .{
            .allocator = allocator,
            .interactables = InteractableObjectSet.init(allocator),
            .highLightObject = null,
            .talkables = .{},
        };
    }

    pub fn addInteractable(self: *@This(), interactable: InteractableObject) !core.ObjectHandle
    {
        return try self.interactables.createObject(.{
            .object = interactable,
        });
    }

    pub fn addTalkable(self: *@This(), interactableName: core.Name, text: []const u8, position: core.Vectorf, radius: f32) !core.ObjectHandle
    {

        if(self.talkables.get(interactableName.hash)) |original|
        {
            var handle = original.*.handle;
            self.interactables.get(handle, .object).?.*.disabled = false;
            self.interactables.get(handle, .object).?.*.position = position;
            self.interactables.get(handle, .object).?.*.radius = radius;
            return handle;
        }
        else {
            var testText = try self.allocator.create(HalcyonInteractable);
            testText.*.dialogueTag = text;

            try self.talkables.put(self.allocator, interactableName.hash, testText);

            var interactable: InteractableObject = .{
                .interface = InteractableRef.makeRef(testText),
                .position = position,
                .radius = radius
            };

            var handle = try self.addInteractable(interactable);
            testText.*.handle = handle;
            return handle;
        }


    }

    pub fn disableAll(self: *@This()) void
    {
        for(self.interactables.denseItems(.object)) |*interactable|
        {
            interactable.*.disabled = true;
        }
    }

    pub fn getNearestObjectInRange(self: *@This(), position: core.Vectorf, radius: f32, showDebug: bool) ?*InteractableObject
    {
        // only considers x and z position
        var nearest: ?*InteractableObject = null;
        var nearestDist: f32 = 100000000;
        
        for(self.interactables.denseItems(.object)) |*interactable|
        {
            if(interactable.*.disabled)
                continue;
            var distance = interactable.position.sub(position).lengthXZ();
            if(showDebug)
            {
                graphics.debug_draw.debugSphere(interactable.position, interactable.radius, .{
                    .color = core.Vectorf.new(1.0, 1.0, 0.0),
                });
            }
            if( distance < (interactable.radius + radius) )
            {
                if(distance < nearestDist)
                {
                    nearest = interactable;
                    nearestDist = distance;
                }
            }
        }

        return nearest;
    }

};