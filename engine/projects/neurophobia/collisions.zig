const std = @import("std");
pub const neonwood = @import("../../modules/neonwood.zig");

const core = neonwood.core;

const ArrayListUnmanaged = std.ArrayListUnmanaged;

pub const CGBox = struct {

    topLeft: core.Vectorf,
    botRight: core.Vectorf,

    // returns if we're overlapping from this box to the other one.
    pub fn intersectBox(self: @This(), other: CGBox) bool
    {
        // x overlap
        const xrange1 = [_]f32{self.topLeft.x, self.botRight.x};
        const xrange2 = [_]f32{other.topLeft.x, other.botRight.x};

        const yrange1 = [_]f32{self.topLeft.z, self.botRight.z};
        const yrange2 = [_]f32{other.topLeft.z, other.botRight.z};

        const xoverlap = xrange1[0] <= xrange2[1] and xrange1[1] >= xrange2[0];
        const yoverlap = yrange1[0] <= yrange2[1] and yrange1[1] >= yrange2[0];

        return xoverlap and yoverlap;
    }

    // returns intersection of this box and this line
    pub fn intersectLine(self: @This(), other: CGLine) bool
    {
        _ = self;
        _ = other;
        return false;
    }

    // returns true if we intersect this box and the circle
    pub fn intersectCircle(self: @This()) bool 
    {
        _ = self;
        return false;
    }
};

pub const CGCircle = struct {
    point: core.Vectorf,
    radius: f32,
};

pub const CGLine = struct {
    start: core.Vectorf,
    end: core.Vectorf,

    //  done in 2d only using x and z
    pub fn intersectLine(self: @This(), other: CGLine) bool
    {
        if(self.start.x == self.end.x and self.start.z == self.end.z) return false;
        if(other.start.x == other.end.x and other.start.z == other.end.z) return false;

        var x1: f32 = self.start.x;
        var y1: f32 = self.start.z;
        
        var x2: f32 = self.end.x;
        var y2: f32 = self.end.z;

        var x3: f32 = other.start.x;
        var y3: f32 = other.start.z;

        var x4: f32 = other.end.x;
        var y4: f32 = other.end.z;

        var denom: f32 = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);

        if(denom == 0)
        {
            // this is a parallel line
            return false;
        }

        var ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom;

        if( ua > 1 or ua < 0)
            return false;

        var ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom;
        if(ub > 1 or ub < 0)
        {
            return false;
        }

        // core.Vector2f{
        //   .x = x1 + ua * (x2 - x1),
        //   .y = y1 + ua * (y2 - y1)
        // };

        return true;
    }
};

/// i have written so much code in domains i've never fucked with before
// in such a short period of time. I'm just going to be fully diving into business logic 
// with these next few subsystems.

// This collision checking algorithm is going to be next level bad.
// but to be perfectly honest.

// But there's barely a week left in this gamejam and there is a LOT 
// to do in terms of actual gameplay mechanics. For now All i need to 
// be able to do is detect walls, and triggers

pub const Collision2D = struct {
    allocator: std.mem.Allocator,
    boxes: ArrayListUnmanaged(CGBox),
    lines: ArrayListUnmanaged(CGLine),
    circles: ArrayListUnmanaged(CGCircle),

    pub fn init(allocator: std.mem.Allocator) @This() {
        var line1 = CGLine{
            .start = core.Vectorf{.x = 1.0, .z = 1.0, .y = 0},
            .end = core.Vectorf{.x = 3.0, .z = 3.0, .y = 0},
        };

        var line2 = CGLine{
            .start = core.Vectorf{.x = 1.0, .z = 3.0, .y = 0},
            .end = core.Vectorf{.x = 3.0, .z = 1.0, .y = 0},
        };

        var line3 = CGLine{
            .start = core.Vectorf{.x = -1.0, .z = -1.0, .y = 0},
            .end = core.Vectorf{.x = -3.0, .z = -3.0, .y = 0},
        };


        core.assert(line1.intersectLine(line2));
        core.assert(line2.intersectLine(line1));
        core.assert(!line1.intersectLine(line3));

        core.engine_logs("INTERSECTION WORKS");

        return .{
            .allocator = allocator,
            .boxes = .{},
            .circles = .{},
            .lines = .{},
        };
    }

    // returns true if it hits something
    pub fn lineTrace(self: @This(), startPoint: core.Vectorf, direction: core.Vectorf, length: f32) bool
    {  
        var traceLine = CGLine{
            .start = startPoint,
            .end = startPoint.add(direction.normalize().fmul(length)),
        };

        for(self.lines.items) |line|
        {
            if(traceLine.intersectLine(line)){
                return true;
            }
        }

        return false;
    }

    pub fn addLine(self: *@This(), start: core.Vectorf, end: core.Vectorf) !*CGLine
    {
        var newLine = CGLine{
            .start = start,
            .end = end,
        };

        try self.lines.append(self.allocator, newLine);
        return &self.lines.items[self.lines.items.len - 1];
    }

    // although we use Vectorfs the y parameter is ignored it's only 2d collisions.
    // only x y coordinates are done
    pub fn addBox(self: *@This(), topLeft: core.Vectorf, botRight: core.Vectorf) !*CGBox
    {
        try self.boxes.append(self.allocator, .{
            .topLeft = topLeft, 
            .botRight = botRight,
        });

        return &self.boxes.items[self.boxes.items.len - 1];
    }

    // although we use Vectorfs the y parameter is ignored it's only 2d collisions.
    pub fn addCircle(self: *@This(), point: core.Vectorf, radius: f32) !*CGCircle 
    {
        try self.circles.append(.{
            .point = point,
            .radius = radius,
        });

        return &self.boxes.items[self.boxes.items.len - 1];
    }
};