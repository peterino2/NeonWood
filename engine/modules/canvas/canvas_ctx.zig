const std = @import("std");
const core = @import("../core.zig");


// Core mode of operation in canvas is based on a hierarchy of paintable objects.
// there are a number of primitive paintable objects but they all have a similar set of features


// top canvas system
pub const CanvasSubsystem = struct 
{
    allocator: std.mem.Allocator,
    

    pub fn init(allocator : std.mem.Allocator) !void
    {

    }

};