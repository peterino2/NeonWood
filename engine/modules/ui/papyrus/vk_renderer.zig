const std = @import("std");
const vk = @import("vk");
const graphics = @import("../../graphics.zig");
const core = @import("../../core.zig");
const NeonVkContext = graphics.NeonVkContext;

const papyrusRes = @import("papyrusRes");

// vulkan based reference renderer
// this is just a sample integration
// device and cmd and vulkan bindings are assumed to be using the
// a 'vk' namespace.

// converts the emitted draw commands from the papyrus system into
// rendering draws for a vulkan instance

gc: *NeonVkContext,
allocator: std.mem.Allocator,

pub fn init(gc: *NeonVkContext, allocator: std.mem.Allocator) !@This() {
    core.ui_log("UI subsystem initialized", .{});
    var self = @This(){
        .gc = gc,
        .allocator = allocator,
    };
    try self.preparePipeline();
    return self;
}

// TODO, papyrus should not use the pipeline builder from neonwood and isntead
// create it's own version of vulkan utilities
pub fn preparePipeline(self: *@This()) !void {
    var pipelineBuilder = try graphics.NeonVkPipelineBuilder.initFromContext(
        self.gc,
        papyrusRes.papyrus_vert,
        papyrusRes.papyrus_frag,
    );
    defer pipelineBuilder.deinit();
}

pub fn deinit(self: *@This()) void {
    _ = self;
}
