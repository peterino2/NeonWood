const std = @import("std");
const core = @import("core");
const vk = @import("vulkan");

const RenderThread = @import("RenderThread.zig");

// aliases
const Name = core.Name;
const ObjectHandle = core.ObjectHandle;
const MakeTypeName = core.MakeTypeName;

pub const RendererInterfaceRef = core.InterfaceRef(RendererInterface);

// RendererInterfaceVTable
pub const RendererInterface = struct {
    typeSize: usize,
    typeAlign: usize,

    onRendererTeardown: ?*const fn (*anyopaque) void,

    sendShared: ?*const fn (*anyopaque, u32) void,
    rtPreDraw: ?*const fn (*anyopaque, *RenderThread, vk.CommandBuffer, u32) void,
    rtPostDraw: ?*const fn (*anyopaque, *RenderThread, vk.CommandBuffer, u32) void,

    pub fn from(comptime TargetType: type) @This() {
        const wrappedFuncs = struct {

            // === renderthread functions ===
            pub fn sendShared(p: *anyopaque, frameIndex: u32) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(p)));
                ptr.sendShared(frameIndex);
            }

            pub fn rtPreDraw(p: *anyopaque, rt: *RenderThread, cmd: vk.CommandBuffer, frameIndex: u32) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(p)));
                ptr.rtPreDraw(rt, cmd, frameIndex);
            }

            pub fn rtPostDraw(p: *anyopaque, rt: *RenderThread, cmd: vk.CommandBuffer, frameIndex: u32) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(p)));
                ptr.rtPostDraw(rt, cmd, frameIndex);
            }

            pub fn onRendererTeardown(pointer: *anyopaque) void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                ptr.onRendererTeardown();
            }
        };

        const self = @This(){
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .onRendererTeardown = if (@hasDecl(TargetType, "onRendererTeardown")) wrappedFuncs.onRendererTeardown else null,

            .sendShared = if (@hasDecl(TargetType, "sendShared")) wrappedFuncs.sendShared else null,
            .rtPreDraw = if (@hasDecl(TargetType, "rtPreDraw")) wrappedFuncs.rtPreDraw else null,
            .rtPostDraw = if (@hasDecl(TargetType, "rtPostDraw")) wrappedFuncs.rtPostDraw else null,
        };

        return self;
    }
};
