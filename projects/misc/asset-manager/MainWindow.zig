allocator: std.mem.Allocator,

rootTree: std.ArrayList(PathData),

const PathData  = struct {};

pub fn create(allocator: std.mem.Allocator) *@This() {
    return .{
        .allocator = allocator,
    };
}

fn displayPath(self: *@This(), ) void 
{
}

pub fn tick(self: *@This()) void 
{
    _ = self;
}

pub fn destroy(self: *@This()) void {
    self.allocator.destroy(self);
}

const neonwood = @import("NeonWood");
const core = neonwood.core;
const vkImgui = neonwood.vkImgui;
const imgui = neonwood.vkImgui.api;
const std = @import("std");
