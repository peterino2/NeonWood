
// A stage defines a standard interface which encapsulates an entire level and an ECS state.

const std = @import("std");
const nw = @import("root").neonwood;

const core = nw.core;
const assets = nw.assets;


pub const StageInterface = struct {
    typeName: Name,
    typeSize: usize,
    typeAlign: usize,

    loadAssets: fn (*anyopaque) assets.AsyncAssetJobContext,
    onBindObject: fn (*anyopaque, ObjectHandle, usize, vk.CommandBuffer, usize) void,
    postDraw: ?fn (*anyopaque, vk.CommandBuffer, usize, f64) void,
};