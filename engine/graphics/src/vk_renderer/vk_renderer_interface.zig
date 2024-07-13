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

    sendShared: ?*const fn (*anyopaque, u32) void,
    rtPreDraw: ?*const fn (*anyopaque, vk.CommandBuffer, u32) void,
    rtPostDraw: ?*const fn (*anyopaque, vk.CommandBuffer, u32) void,

    pub fn from(comptime TargetType: type) @This() {
        const wrappedFuncs = struct {

            // ==== legacy non-renderthread functions ====
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

            // === renderthread functions ===
            pub fn sendShared(p: *anyopaque, frameIndex: u32) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(p)));
                ptr.sendShared(frameIndex);
            }

            pub fn rtPreDraw(p: *anyopaque, cmd: vk.CommandBuffer, frameIndex: u32) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(p)));
                ptr.rtPreDraw(cmd, frameIndex);
            }

            pub fn rtPostDraw(p: *anyopaque, cmd: vk.CommandBuffer, frameIndex: u32) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(p)));
                ptr.rtPostDraw(cmd, frameIndex);
            }

            pub fn onRendererTeardown(pointer: *anyopaque) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                ptr.onRendererTeardown();
            }
        };

        const self = @This(){
            .typeName = MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .preDraw = if (@hasDecl(TargetType, "preDraw")) wrappedFuncs.preDraw else null,
            .onBindObject = if (@hasDecl(TargetType, "onBindObject")) wrappedFuncs.onBindObject else null,
            .onRendererTeardown = if (@hasDecl(TargetType, "onRendererTeardown")) wrappedFuncs.onRendererTeardown else null,
            .postDraw = if (@hasDecl(TargetType, "postDraw")) wrappedFuncs.postDraw else null,

            .sendShared = if (@hasDecl(TargetType, "sendShared")) wrappedFuncs.sendShared else null,
            .rtPreDraw = if (@hasDecl(TargetType, "rtPreDraw")) wrappedFuncs.rtPreDraw else null,
            .rtPostDraw = if (@hasDecl(TargetType, "rtPostDraw")) wrappedFuncs.rtPostDraw else null,
        };

        return self;
    }
};
