const std = @import("std");
const core = @import("../../core.zig");
const vk = @import("vulkan");

// aliases
const Name = core.Name;
const ObjectHandle = core.ObjectHandle;
const MakeTypeName = core.MakeTypeName;

pub const RendererInterfaceRef = core.InterfaceRef(RendererInterface);

// RendererInterfaceVTable
pub const RendererInterface = struct {
    typeName: Name,
    typeSize: usize,
    typeAlign: usize,

    preDraw: *const fn (*anyopaque, frameId: usize) void,
    onBindObject: *const fn (*anyopaque, ObjectHandle, usize, vk.CommandBuffer, usize) void,
    postDraw: ?*const fn (*anyopaque, vk.CommandBuffer, usize, f64) void,

    pub fn from(comptime TargetType: type) @This() {
        const wrappedFuncs = struct {
            pub fn preDraw(pointer: *anyopaque, frameId: usize) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                ptr.preDraw(frameId);
            }

            pub fn onBindObject(pointer: *anyopaque, objectHandle: ObjectHandle, objectIndex: usize, cmd: vk.CommandBuffer, frameIndex: usize) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                ptr.onBindObject(objectHandle, objectIndex, cmd, frameIndex);
            }

            pub fn postDraw(pointer: *anyopaque, cmd: vk.CommandBuffer, frameIndex: usize, deltaTime: f64) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                ptr.postDraw(cmd, frameIndex, deltaTime);
            }
        };

        inline for (.{ "preDraw", "onBindObject" }) |declName| {
            if (!@hasDecl(TargetType, declName)) {
                @compileError(
                    std.fmt.comptimePrint(
                        "Tried to Generate {s} for type {s} but it's missing {s}",
                        .{ @typeName(@This()), @typeName(TargetType), declName },
                    ),
                );
            }
        }

        var self = @This(){
            .typeName = MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .preDraw = wrappedFuncs.preDraw,
            .onBindObject = wrappedFuncs.onBindObject,
            .postDraw = null,
        };

        if (@hasDecl(TargetType, "postDraw")) {
            self.postDraw = wrappedFuncs.postDraw;
        }

        return self;
    }
};
