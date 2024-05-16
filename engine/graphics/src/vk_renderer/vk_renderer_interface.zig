const std = @import("std");
const core = @import("core");
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

    preDraw: ?*const fn (*anyopaque, frameId: usize) void,
    onBindObject: ?*const fn (*anyopaque, ObjectHandle, usize, vk.CommandBuffer, usize) void,
    postDraw: ?*const fn (*anyopaque, vk.CommandBuffer, usize, f64) void,
    onRendererTeardown: ?*const fn (*anyopaque) void,

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

            pub fn onRendererTeardown(pointer: *anyopaque) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                ptr.onRendererTeardown();
            }
        };

        // everything is custom now so, i dont think it even needs to do anything
        // inline for (.{}) |declName| {
        //     if (!@hasDecl(TargetType, declName)) {
        //         @compileError(
        //             std.fmt.comptimePrint(
        //                 "Tried to Generate {s} for type {s} but it's missing {s}",
        //                 .{ @typeName(@This()), @typeName(TargetType), declName },
        //             ),
        //         );
        //     }
        // }

        const self = @This(){
            .typeName = MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .preDraw = if (@hasDecl(TargetType, "preDraw")) wrappedFuncs.preDraw else null,
            .onBindObject = if (@hasDecl(TargetType, "onBindObject")) wrappedFuncs.onBindObject else null,
            .onRendererTeardown = if (@hasDecl(TargetType, "onRendererTeardown")) wrappedFuncs.onRendererTeardown else null,
            .postDraw = if (@hasDecl(TargetType, "postDraw")) wrappedFuncs.postDraw else null,
        };

        return self;
    }
};
